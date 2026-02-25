class QueueError {
  final String documentId;
  final String collection;
  final String error;
  final int retryCount;

  QueueError({
    required this.documentId,
    required this.collection,
    required this.error,
    required this.retryCount,
  });
}
