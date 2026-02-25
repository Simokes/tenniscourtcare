import 'dart:async';
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

  final _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  SyncService(this._db, this._firestore);

  Future<void> initialize() async {
    final result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    _isOnline = result != ConnectivityResult.none;
    debugPrint('SyncService: Connection status changed. Online: $_isOnline');
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }

  /// Send directly to cloud (no queue).
  /// Used by QueueManager to process queue items.
  Future<void> sendToCloud(
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

  /// SyncUp: Direct attempt to sync.
  /// Does NOT queue. Returns true if successful, false otherwise.
  Future<bool> syncUp(
    String collection,
    String documentId,
    Map<String, dynamic> data, {
    required SyncAction action,
  }) async {
    if (_isOnline) {
      try {
        await sendToCloud(collection, documentId, data, action);
        return true;
      } catch (e) {
        debugPrint('SyncService: Direct sync failed. Error: $e');
        return false;
      }
    } else {
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

  Future<Set<String>> _getPendingDocumentIds(String collection) async {
    final rows = await (_db.selectOnly(_db.syncQueue)
      ..addColumns([_db.syncQueue.documentId])
      ..where(_db.syncQueue.collection.equals(collection) & _db.syncQueue.syncedAt.isNull())
    ).get();

    return rows.map((r) => r.read(_db.syncQueue.documentId)!).toSet();
  }
}
