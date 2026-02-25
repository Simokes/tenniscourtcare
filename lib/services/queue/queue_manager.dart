import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../../data/database/app_database.dart';
import '../sync/sync_service.dart';
import '../../core/config/queue_config.dart';

class QueueManager {
  final AppDatabase _db;
  final SyncService _syncService;

  bool _isFlushing = false;

  final _queueUpdatedController = StreamController<int>.broadcast();
  final _queueWarningController = StreamController<int>.broadcast();
  final _queueCriticalController = StreamController<int>.broadcast();

  Stream<int> get onQueueUpdated => _queueUpdatedController.stream;
  Stream<int> get onQueueWarning => _queueWarningController.stream;
  Stream<int> get onQueueCritical => _queueCriticalController.stream;

  Timer? _retryTimer;

  QueueManager(this._db, this._syncService) {
     // Start periodic retry check
    _retryTimer = Timer.periodic(
      QueueConfig.retryCheckInterval,
      (_) => processScheduledRetries(),
    );
  }

  // A) queueChange() - Add item to queue
  Future<void> queueChange({
    required String collection,
    required String action,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    final uuid = '${DateTime.now().millisecondsSinceEpoch}-${math.Random().nextInt(10000)}';

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
        nextRetryAt: const Value(null),
      ),
    );

    debugPrint('QueueManager: Queued $action on $collection:$documentId');
    await _notifyQueueUpdated();
  }

  DateTime _calculateNextRetryAt(int retryCount) {
    // Exponential backoff: 1s, 2s, 4s, capped at maxBackoff
    final delaySeconds = math.min(
      math.pow(2, retryCount - 1).toInt(),
      QueueConfig.maxBackoff.inSeconds,
    );
    return DateTime.now().add(Duration(seconds: delaySeconds));
  }

  Future<void> processScheduledRetries() async {
    try {
      final now = DateTime.now();
      final readyItems = await (_db.select(_db.syncQueue)
        ..where((q) => q.syncedAt.isNull() &
                     q.nextRetryAt.isNotNull() &
                     q.nextRetryAt.isSmallerOrEqualValue(now)))
        .get();

      if (readyItems.isNotEmpty) {
        debugPrint(
          'QueueManager: Processing ${readyItems.length} scheduled retries',
        );
        await flushQueue();
      }
    } catch (e) {
      debugPrint('QueueManager: Error in processScheduledRetries: $e');
    }
  }

  Future<void> _deduplicateQueue() async {
    try {
      // Get all pending items grouped by collection+documentId
      final allItems = await (_db.select(_db.syncQueue)
        ..where((q) => q.syncedAt.isNull()))
        .get();

      final Map<String, List<SyncQueueItem>> grouped = {};
      for (final item in allItems) {
        final key = '${item.collection}:${item.documentId}';
        grouped.putIfAbsent(key, () => []).add(item);
      }

      // Deduplicate: keep only latest action per documentId
      int removed = 0;
      for (final items in grouped.values) {
        if (items.length > 1) {
          // Sort by timestamp descending (latest first)
          items.sort((a, b) => b.timestamp.compareTo(a.timestamp));

          // Delete action wins over create/update
          final hasDelete = items.any((i) => i.action == 'delete');

          if (hasDelete) {
            // Keep only delete, remove others
            final keepId = items.firstWhere((i) => i.action == 'delete').id;
            for (final item in items) {
              if (item.id != keepId) {
                await (_db.delete(_db.syncQueue)..where((q) => q.id.equals(item.id))).go();
                removed++;
              }
            }
          } else {
            // Keep only latest create/update
            
            for (final item in items.skip(1)) {
              await (_db.delete(_db.syncQueue)..where((q) => q.id.equals(item.id))).go();
              removed++;
            }
          }
        }
      }

      if (removed > 0) {
        debugPrint('QueueManager: Deduplicated $removed redundant items');
      }
    } catch (e) {
      debugPrint('QueueManager: Error in _deduplicateQueue: $e');
    }
  }

  Future<bool> _handleConflict(SyncQueueItem item, String error) async {
    try {
      // Map error to business logic
      final isTerrainUnavailable =
        error.toLowerCase().contains('terrain') ||
        error.toLowerCase().contains('not available');

      final isDoubleBooking =
        error.toLowerCase().contains('booking') ||
        error.toLowerCase().contains('conflict');

      final isServerError =
        error.toLowerCase().contains('500') ||
        error.toLowerCase().contains('502') ||
        error.toLowerCase().contains('503');

      if (isTerrainUnavailable) {
        // Delete reservation
        if (item.collection == 'reservations') {
          await (_db.delete(_db.reservations)
            ..where((r) => r.id.equals(int.parse(item.documentId)))) // assuming documentId matches local id string
            .go();

          debugPrint(
            'QueueManager: Conflict handled - Reservation cancelled: ${item.documentId}',
          );

          // Update queue: mark as resolved (delete from queue after)
          return true; // Skip retry
        }
      } else if (isDoubleBooking) {
        // Notify user - keep in queue for manual intervention
        debugPrint(
          'QueueManager: Conflict - Double booking detected: ${item.documentId}',
        );
        return false; // Retry later
      } else if (isServerError) {
        // Temporary error - retry with backoff
        debugPrint(
          'QueueManager: Conflict - Server error, will retry: ${item.documentId}',
        );
        return false; // Retry
      }

      return false; // Default: retry
    } catch (e) {
      debugPrint('QueueManager: Error in _handleConflict: $e');
      return false; // Retry on error
    }
  }

  Future<void> _checkQueueSize() async {
    try {
      final count = await getQueueSize();

      if (count >= QueueConfig.largeQueueCriticalThreshold) {
        _queueCriticalController.add(count);
        debugPrint('QueueManager: CRITICAL - Queue has $count items!');
      } else if (count >= QueueConfig.largeQueueWarningThreshold) {
        _queueWarningController.add(count);
        debugPrint('QueueManager: WARNING - Queue has $count items');
      }
    } catch (e) {
      debugPrint('QueueManager: Error in _checkQueueSize: $e');
    }
  }

  // B) flushQueue() - Process all pending items
  Future<void> flushQueue() async {
    if (_isFlushing) return;
    _isFlushing = true;

    try {
      final now = DateTime.now();

      // Get items ready to sync (check nextRetryAt)
      final items = await (_db.select(_db.syncQueue)
        ..where((q) =>
          q.syncedAt.isNull() &
          (q.nextRetryAt.isNull() | q.nextRetryAt.isSmallerOrEqualValue(now)) &
          q.retryCount.isSmallerThanValue(QueueConfig.maxRetries)
        )
        ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]))
        .get();

      if (items.isEmpty) {
        _isFlushing = false;
        return;
      }

      debugPrint('QueueManager: Flushing ${items.length} items');

      int synced = 0;
      int failed = 0;

      for (final item in items) {
        try {
          final error = await _sendItemToCloud(item);

          if (error == null) {
            // Success
            await (_db.update(_db.syncQueue)..where((t) => t.id.equals(item.id)))
              .write(
                 SyncQueueCompanion(
                    syncedAt: Value(DateTime.now()),
                    retryCount: const Value(0),
                    lastError: const Value(null),
                    nextRetryAt: const Value(null),
                 )
              );

            // Delete from queue after sync
            await (_db.delete(_db.syncQueue)
              ..where((q) => q.id.equals(item.id)))
              .go();

            synced++;
            debugPrint('QueueManager: Synced ${item.collection}:${item.documentId}');
          } else {
            // Failure - check for conflict
            final shouldSkip = await _handleConflict(item, error);

            if (shouldSkip) {
              // Delete from queue (conflict resolved)
              await (_db.delete(_db.syncQueue)
                ..where((q) => q.id.equals(item.id)))
                .go();
              synced++;
            } else {
              // Retry with backoff
              final newRetryCount = item.retryCount + 1;
              final nextRetry = _calculateNextRetryAt(newRetryCount);

              await (_db.update(_db.syncQueue)..where((t) => t.id.equals(item.id)))
                .write(
                  SyncQueueCompanion(
                    retryCount: Value(newRetryCount),
                    lastError: Value(error),
                    nextRetryAt: Value(nextRetry),
                  )
                );

              failed++;
              debugPrint(
                'QueueManager: Failed ${item.collection} (attempt $newRetryCount) - '
                'Retrying at ${nextRetry.toIso8601String()}',
              );
            }
          }
        } catch (e) {
          failed++;
          debugPrint('QueueManager: Error syncing item: $e');
        }
      }

      await _notifyQueueUpdated();
      await _checkQueueSize();

      debugPrint(
        'QueueManager: Flush complete. Synced $synced, Failed $failed',
      );
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
        nextRetryAt: Value(null), // Clear nextRetryAt to retry immediately
      ),
    );

    await flushQueue();
  }

  // F) clearQueue() - Clear all pending (dangerous)
  Future<void> clearQueue({required bool confirmed}) async {
    if (!confirmed) throw Exception('Must confirm before clearing');

    await (_db.delete(_db.syncQueue)..where((t) => t.syncedAt.isNull())).go();
    debugPrint('QueueManager: Queue cleared by user');
    await _notifyQueueUpdated();
  }

  Future<void> _notifyQueueUpdated() async {
    await _deduplicateQueue();
    final size = await getQueueSize();
    _queueUpdatedController.add(size);
    await _checkQueueSize();
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

  Future<void> dispose() async {
    await _queueUpdatedController.close();
    await _queueWarningController.close();
    await _queueCriticalController.close();
    _retryTimer?.cancel();
  }
}
