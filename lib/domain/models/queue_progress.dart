import '../../data/database/app_database.dart';

class QueueProgress {
  final int total;
  final int synced;
  final int pending;
  final double progress; // 0.0 to 1.0

  QueueProgress({
    required this.total,
    required this.synced,
    required this.pending,
    required this.progress,
  });

  factory QueueProgress.fromItems(List<SyncQueueItem> items) {
    final total = items.length;
    final synced = items.where((i) => i.syncedAt != null).length;
    final pending = total - synced;
    final progress = total == 0 ? 1.0 : synced / total;

    return QueueProgress(
      total: total,
      synced: synced,
      pending: pending,
      progress: progress,
    );
  }
}
