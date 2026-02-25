import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../../data/database/app_database.dart';
import '../sync/sync_service.dart';

class QueueManager {
  final AppDatabase _db;
  final SyncService _syncService;

  bool _isFlushing = false;
  final _queueUpdatedController = StreamController<int>.broadcast();
  Stream<int> get onQueueUpdated => _queueUpdatedController.stream;

  QueueManager(this._db, this._syncService);

  // A) queueChange() - Add item to queue
  Future<void> queueChange({
    required String collection,
    required String action,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    final uuid = '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(10000)}';

    await _db.into(_db.syncQueue).insert(
      SyncQueueCompanion(
        uuid: Value(uuid),
        collection: Value(collection),
        action: Value(action),
        documentId: Value(documentId),
        data: Value(jsonEncode(data)),
        timestamp: Value(DateTime.now()),
        syncedAt: const Value(null),
        retryCount: const Value(0),
        lastError: const Value(null),
      ),
    );

    debugPrint("QueueManager: Queued $action on $collection:$documentId");
    await _notifyQueueUpdated();
  }

  // B) flushQueue() - Process all pending items
  Future<void> flushQueue() async {
    if (_isFlushing) return;
    _isFlushing = true;

    try {
      final pendingItems = await (_db.select(_db.syncQueue)
        ..where((t) => t.syncedAt.isNull())
        ..orderBy([(t) => OrderingTerm.asc(t.timestamp)])
      ).get();

      if (pendingItems.isEmpty) return;

      debugPrint("QueueManager: Flushing ${pendingItems.length} items");

      int syncedCount = 0;
      int failedCount = 0;

      for (final item in pendingItems) {
        // Don't retry if max retries reached (unless manually reset)
        if (item.retryCount >= 3) {
           debugPrint("QueueManager: Skipping item ${item.uuid} (max retries reached)");
           continue;
        }

        final error = await _sendItemToCloud(item);

        if (error == null) {
          // Success
          await (_db.delete(_db.syncQueue)..where((t) => t.id.equals(item.id))).go();
          debugPrint("QueueManager: Synced ${item.collection}:${item.documentId}");
          syncedCount++;
        } else {
          // Failure
          final newRetryCount = item.retryCount + 1;
          await (_db.update(_db.syncQueue)..where((t) => t.id.equals(item.id))).write(
              SyncQueueCompanion(
                retryCount: Value(newRetryCount),
                lastError: Value(error),
              ),
          );
          debugPrint("QueueManager: Failed ${item.collection} (attempt $newRetryCount)");
          if (newRetryCount >= 3) debugPrint("QueueManager: Max retries reached");
          failedCount++;
        }
      }

      if (syncedCount > 0 || failedCount > 0) {
        await _notifyQueueUpdated();
        debugPrint("QueueManager: Flush complete. Synced $syncedCount, Failed $failedCount");
      }
    } finally {
      _isFlushing = false;
    }
  }

  // C) getQueueSize() - Count pending items
  Future<int> getQueueSize() async {
    final count = await (_db.selectOnly(_db.syncQueue)
      ..addColumns([_db.syncQueue.id.count()])
      ..where(_db.syncQueue.syncedAt.isNull())
    ).getSingle();
    return count.read(_db.syncQueue.id.count()) ?? 0;
  }

  // D) getPendingItems() - Get details
  Future<List<SyncQueueItem>> getPendingItems() async {
    return (_db.select(_db.syncQueue)
      ..where((t) => t.syncedAt.isNull())
      ..orderBy([(t) => OrderingTerm.asc(t.timestamp)])
    ).get();
  }

  // E) retryFailedItems() - Retry items that failed
  Future<void> retryFailedItems() async {
    // Reset retryCount to 0 for all failed items (even maxed ones, to allow retry)
    await (_db.update(_db.syncQueue)
      ..where((t) => t.lastError.isNotNull())
    ).write(
      const SyncQueueCompanion(
        retryCount: Value(0),
        lastError: Value(null),
      ),
    );

    await flushQueue();
  }

  // F) clearQueue() - Clear all pending (dangerous)
  Future<void> clearQueue({required bool confirmed}) async {
    if (!confirmed) throw Exception("Must confirm before clearing");

    await (_db.delete(_db.syncQueue)..where((t) => t.syncedAt.isNull())).go();
    debugPrint("QueueManager: Queue cleared by user");
    await _notifyQueueUpdated();
  }

  Future<void> _notifyQueueUpdated() async {
    final size = await getQueueSize();
    _queueUpdatedController.add(size);
  }

  Future<String?> _sendItemToCloud(SyncQueueItem item) async {
    try {
      final data = jsonDecode(item.data) as Map<String, dynamic>;

      SyncAction action;
      try {
        action = SyncAction.values.firstWhere((e) => e.name == item.action);
      } catch (_) {
        action = SyncAction.update; // Default safety
      }

      await _syncService.sendToCloud(item.collection, item.documentId, data, action);
      return null; // Success
    } catch (e) {
      return e.toString(); // Failure
    }
  }

  void dispose() {
    _queueUpdatedController.close();
  }
}
