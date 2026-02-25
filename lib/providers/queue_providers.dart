import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/queue/queue_manager.dart';
import '../data/database/app_database.dart';
import '../presentation/providers/database_provider.dart';
import 'sync_providers.dart';
import '../domain/models/queue_status.dart';
import '../domain/models/queue_progress.dart';
import '../domain/models/queue_error.dart';

part 'queue_providers.g.dart';

@Riverpod(keepAlive: true)
QueueManager queueManager(QueueManagerRef ref) {
  final db = ref.watch(databaseProvider);
  final syncService = ref.watch(syncServiceProvider);
  final manager = QueueManager(db, syncService);

  // Listen for connectivity changes to trigger flush
  ref.listen(isOnlineStatusProvider, (previous, next) {
    next.whenData((isOnline) {
      if (isOnline) {
        manager.flushQueue();
      }
    });
  });

  // Dispose manager when provider is disposed
  ref.onDispose(() {
    manager.dispose();
  });

  return manager;
}

@Riverpod(keepAlive: true)
Stream<int> pendingQueueCount(PendingQueueCountRef ref) async* {
  final manager = ref.watch(queueManagerProvider);

  // Yield initial count
  yield await manager.getQueueSize();

  // Yield updates
  await for (final count in manager.onQueueUpdated) {
    yield count;
  }
}

@Riverpod()
Future<List<SyncQueueItem>> pendingQueueItems(PendingQueueItemsRef ref) async {
  final manager = ref.watch(queueManagerProvider);

  // Rebuild when count changes
  ref.watch(pendingQueueCountProvider);

  return await manager.getPendingItems();
}

@Riverpod()
Future<void> retryFailed(RetryFailedRef ref) async {
  final manager = ref.watch(queueManagerProvider);
  await manager.retryFailedItems();
  ref.invalidate(pendingQueueItemsProvider);
}

@Riverpod(keepAlive: true)
Future<QueueStatus> queueStatus(QueueStatusRef ref) async {
  final count = await ref.watch(pendingQueueCountProvider.future);
  final items = await ref.watch(pendingQueueItemsProvider.future);

  final failedCount = items.where((i) => i.retryCount > 0).length;
  final status = count == 0
    ? QueueStatusType.idle
    : failedCount > 0
      ? QueueStatusType.partialFailure
      : QueueStatusType.syncing;

  return QueueStatus(
    count: count,
    failedCount: failedCount,
    status: status,
    lastSyncAt: items.isEmpty ? null : items.first.syncedAt,
  );
}

@Riverpod(keepAlive: true)
Future<QueueProgress> queueProgress(QueueProgressRef ref) async {
  final items = await ref.watch(pendingQueueItemsProvider.future);
  return QueueProgress.fromItems(items);
}

@Riverpod(keepAlive: true)
Future<List<QueueError>> queueErrors(QueueErrorsRef ref) async {
  final items = await ref.watch(pendingQueueItemsProvider.future);

  return items
    .where((i) => i.lastError != null && i.lastError!.isNotEmpty)
    .map((i) => QueueError(
      documentId: i.documentId,
      collection: i.collection,
      error: i.lastError!,
      retryCount: i.retryCount,
    ))
    .toList();
}

@Riverpod(keepAlive: true)
Stream<int> queueWarnings(QueueWarningsRef ref) {
  final manager = ref.watch(queueManagerProvider);
  return manager.onQueueWarning;
}

@Riverpod(keepAlive: true)
Stream<int> queueCritical(QueueCriticalRef ref) {
  final manager = ref.watch(queueManagerProvider);
  return manager.onQueueCritical;
}

@Riverpod(keepAlive: true)
void scheduleRetryCheck(ScheduleRetryCheckRef ref) {
  // Just watching the manager initializes it, including the retry timer.
  ref.watch(queueManagerProvider);
}
