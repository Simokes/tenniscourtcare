enum QueueStatusType { idle, syncing, partialFailure }

class QueueStatus {
  final int count;
  final int failedCount;
  final QueueStatusType status;
  final DateTime? lastSyncAt;

  QueueStatus({
    required this.count,
    required this.failedCount,
    required this.status,
    this.lastSyncAt,
  });

  bool get isHealthy => failedCount == 0 && count == 0;
}
