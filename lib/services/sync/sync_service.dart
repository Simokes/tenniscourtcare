import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../../data/database/app_database.dart';

enum SyncAction { create, update, delete }

class SyncService {
  final AppDatabase _db;
  final FirebaseFirestore _firestore;

  bool _isOnline = false;
  bool get isOnline => _isOnline;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  final _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  final _queueChangeController = StreamController<void>.broadcast();
  Stream<void> get onQueueChanged => _queueChangeController.stream;

  SyncService(this._db, this._firestore);

  Future<void> initialize() async {
    final result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);

    // Initial check for pending items even if offline (to update count)
    // or just rely on providers.
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    bool wasOnline = _isOnline;
    _isOnline = result.any((r) => r != ConnectivityResult.none);

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
    required T Function(DocumentSnapshot) fromFirestore,
    required Future<void> Function(List<T> items) saveToLocal,
    required String Function(T item) getId,
    Query Function(Query)? queryFn,
  }) {
    Query query = _firestore.collection(collection);
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
    required T Function(DocumentSnapshot) fromFirestore,
    required Future<void> Function(List<T> items) saveToLocal,
    Query Function(Query)? queryFn,
  }) async {
    if (!_isOnline) {
      debugPrint('SyncService: Offline. Cannot refresh $collection.');
      return;
    }

    try {
      Query query = _firestore.collection(collection);
      if (queryFn != null) {
        query = queryFn(query);
      }

      final snapshot = await query.get();
      final items = snapshot.docs.map(fromFirestore).toList();

      // For refresh, we generally want to update everything we fetched.
      // We might want to respect pending changes (not overwrite local edits).
      // Let's reuse the logic from syncDown: filter out pending IDs.
      final pendingIds = await _getPendingDocumentIds(collection);

      // Assume T has an ID access or we pass an getId function?
      // The prompt didn't specify getId for refreshCollection, but syncDown has it.
      // Let's add getId to refreshCollection signature to match syncDown pattern
      // or assume we save all for now if no conflict.
      // But to match syncDown logic, we need to know IDs.
      // Wait, the prompt example usage:
      // await sync.refreshCollection<Terrain>(..., saveToLocal: ...);
      // It didn't show getId.
      // But if I want to respect pending changes I need IDs.
      // I will assume for now we overwrite unless I add getId.
      // Given the prompt example "await db.terrains.deleteAll(); await db.terrains.insertAll(terrains);",
      // it seems the user intends a FULL refresh replacing local data.
      // BUT, deleting all would lose pending local changes if we are not careful.
      // However, the prompt says "Update Drift local", and the example usage shows
      // deleteAll(). This is aggressive.
      // If I use deleteAll(), I lose pending creates/updates if they are not yet synced.
      // But the sync queue stores the *changes* separately in `SyncQueue` table?
      // No, `SyncQueue` stores the *operation* to replay.
      // The `terrains` table stores the *current state*.
      // If I delete `terrains`, I lose the local state.
      // If `SyncQueue` has a pending update for ID '123', and I delete '123' from `terrains`,
      // then `123` is gone from UI until I re-insert it.
      // If I re-insert from Firestore, I get the OLD server version.
      // Then the SyncQueue will eventually run and update server.
      // But the UI will momentarily revert to server state.
      //
      // User Prompt Example:
      //   await sync.refreshCollection<Terrain>(..., saveToLocal: (terrains) async {
      //     final db = ref.read(databaseProvider);
      //     await db.terrains.deleteAll(); // <--- THIS IS DANGEROUS for pending changes
      //     await db.terrains.insertAll(terrains);
      //   });
      //
      // I should probably follow the prompt's interface but implement `saveToLocal` safely in the provider.
      // So `refreshCollection` just fetches and calls `saveToLocal`.
      // It is up to `saveToLocal` implementation to decide how to merge.

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
        // Use set to ensure ID match, or set with merge if needed.
        // Prompt said create: set() is safer for idempotency if ID is provided.
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
