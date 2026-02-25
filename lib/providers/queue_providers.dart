import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/queue/queue_manager.dart';
import '../data/database/app_database.dart';
import '../presentation/providers/database_provider.dart';
import 'sync_providers.dart';

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

  return manager;
}

@Riverpod(keepAlive: true)
Stream<int> pendingQueueCount(PendingQueueCountRef ref) async* {
  final manager = ref.watch(queueManagerProvider);

  // Yield initial count
  yield await manager.getQueueSize();

  // Yield updates
  await for (final _ in manager.onQueueUpdated) {
    yield await manager.getQueueSize();
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
