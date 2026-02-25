import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart' as fb;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../../data/database/app_database.dart';

enum SyncAction { create, update, delete }

class SyncService {
  final AppDatabase _db;
  final fb.FirebaseFirestore _firestore;

  bool _isOnline = false;
  bool get isOnline => _isOnline;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  final _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  final _queueChangeController = StreamController<void>.broadcast();
  Stream<void> get onQueueChanged => _queueChangeController.stream;

  SyncService(this._db, this._firestore);

  Future<void> initialize() async {
    final result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    bool wasOnline = _isOnline;
    _isOnline = result != ConnectivityResult.none;

    if (_isOnline && !wasOnline) {
      debugPrint('SyncService: Online. Flushing queue...');
      _flushQueue();
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _queueChangeController.close();
  }

  /// SyncUp: Sends data to Firestore or queues it if offline/fails.
  Future<bool> syncUp(
    String collection,
    String documentId,
    Map<String, dynamic> data, {
    required SyncAction action,
  }) async {
    if (_isOnline) {
      try {
        await _sendToCloud(collection, documentId, data, action);
        return true;
      } catch (e) {
        debugPrint('SyncService: Sync failed, queueing. Error: $e');
        await _addToQueue(collection, documentId, data, action, lastError: e.toString());
        return false;
      }
    } else {
      await _addToQueue(collection, documentId, data, action);
      return false;
    }
  }

  /// SyncDown: Listens to Firestore and updates local DB.
  /// Respects "Cloud Wins" unless local has pending changes for that ID.
  StreamSubscription<List<T>> syncDown<T>({
    required String collection,
    required T Function(fb.DocumentSnapshot) fromFirestore,
    required Future<void> Function(List<T> items) saveToLocal,
    required String Function(T item) getId,
    fb.Query Function(fb.Query)? queryFn,
  }) {
    fb.Query query = _firestore.collection(collection);
    if (queryFn != null) {
      query = queryFn(query);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map(fromFirestore).toList();
    }).listen((items) async {
      // Filter out items that have pending local changes to avoid overwriting user edits
      final pendingIds = await _getPendingDocumentIds(collection);

      final itemsToSave = items.where((item) {
        final id = getId(item);
        return !pendingIds.contains(id);
      }).toList();

      if (itemsToSave.isNotEmpty) {
        await saveToLocal(itemsToSave);
      }
    });
  }

  /// RefreshCollection: Performs a one-time fetch from Firestore and updates local DB.
  /// Useful for manual refresh (pull-to-refresh).
  Future<void> refreshCollection<T>({
    required String collection,
    required T Function(fb.DocumentSnapshot) fromFirestore,
    required Future<void> Function(List<T> items) saveToLocal,
    fb.Query Function(fb.Query)? queryFn,
  }) async {
    if (!_isOnline) {
      debugPrint('SyncService: Offline. Cannot refresh $collection.');
      return;
    }

    try {
      fb.Query query = _firestore.collection(collection);
      if (queryFn != null) {
        query = queryFn(query);
      }

      final snapshot = await query.get();
      final items = snapshot.docs.map(fromFirestore).toList();

      // For refresh, we generally want to update everything we fetched.
      // We rely on saveToLocal to handle conflict resolution.
      await saveToLocal(items);

    } catch (e) {
      debugPrint('SyncService: Failed to refresh $collection. Error: $e');
      rethrow;
    }
  }

  Future<void> _addToQueue(
    String collection,
    String documentId,
    Map<String, dynamic> data,
    SyncAction action, {
    String? lastError,
  }) async {
    // Check if item already exists in queue (pending), update it if so
    final existing = await (_db.select(_db.syncQueue)
      ..where((t) => t.collection.equals(collection) & t.documentId.equals(documentId) & t.syncedAt.isNull())
    ).getSingleOrNull();

    if (existing != null) {
      // Update existing queue item
      SyncAction currentAction = action;
      if (existing.action == SyncAction.create.name && action == SyncAction.update) {
         currentAction = SyncAction.create;
      }

      final existingData = jsonDecode(existing.data) as Map<String, dynamic>;
      final newData = {...existingData, ...data};

      await (_db.update(_db.syncQueue)..where((t) => t.id.equals(existing.id))).write(
        SyncQueueCompanion(
          action: Value(currentAction.name),
          data: Value(jsonEncode(newData)),
          createdAt: Value(DateTime.now()),
          retryCount: const Value(0),
          lastError: Value(lastError),
        ),
      );
    } else {
      // Insert new
      await _db.into(_db.syncQueue).insert(
        SyncQueueCompanion(
          collection: Value(collection),
          documentId: Value(documentId),
          action: Value(action.name),
          data: Value(jsonEncode(data)),
          createdAt: Value(DateTime.now()),
          lastError: Value(lastError),
        ),
      );
    }
    _queueChangeController.add(null);
  }

  Future<void> _flushQueue() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final pendingItems = await (_db.select(_db.syncQueue)
        ..where((t) => t.syncedAt.isNull())
        ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
      ).get();

      for (final item in pendingItems) {
        if (item.retryCount >= 3) continue; // Skip items that failed too many times

        try {
          final data = jsonDecode(item.data) as Map<String, dynamic>;
          final action = SyncAction.values.firstWhere((e) => e.name == item.action);

          await _sendToCloud(item.collection, item.documentId, data, action);

          // Mark as synced
          await (_db.update(_db.syncQueue)..where((t) => t.id.equals(item.id))).write(
            SyncQueueCompanion(
              syncedAt: Value(DateTime.now()),
              lastError: const Value(null),
            ),
          );
        } catch (e) {
          debugPrint('SyncService: Failed to flush item ${item.id}. Error: $e');
          await (_db.update(_db.syncQueue)..where((t) => t.id.equals(item.id))).write(
            SyncQueueCompanion(
              retryCount: Value(item.retryCount + 1),
              lastError: Value(e.toString()),
            ),
          );
        }
      }
      _queueChangeController.add(null);
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _sendToCloud(
    String collection,
    String documentId,
    Map<String, dynamic> data,
    SyncAction action,
  ) async {
    final colRef = _firestore.collection(collection);
    final docRef = colRef.doc(documentId);

    switch (action) {
      case SyncAction.create:
        await docRef.set(data);
        break;
      case SyncAction.update:
        await docRef.update(data);
        break;
      case SyncAction.delete:
        await docRef.delete();
        break;
    }
  }

  Future<Set<String>> _getPendingDocumentIds(String collection) async {
    final rows = await (_db.selectOnly(_db.syncQueue)
      ..addColumns([_db.syncQueue.documentId])
      ..where(_db.syncQueue.collection.equals(collection) & _db.syncQueue.syncedAt.isNull())
    ).get();

    return rows.map((r) => r.read(_db.syncQueue.documentId)!).toSet();
  }

  Future<int> getPendingChangesCount() async {
    final count = await (_db.selectOnly(_db.syncQueue)
      ..addColumns([_db.syncQueue.id.count()])
      ..where(_db.syncQueue.syncedAt.isNull())
    ).getSingle();

    return count.read(_db.syncQueue.id.count()) ?? 0;
  }

  Future<List<SyncQueueItem>> getUnSyncedChanges() async {
     return (_db.select(_db.syncQueue)..where((t) => t.syncedAt.isNull())).get();
  }
}
