class QueueConfig {
  static const int maxRetries = 3;
  static const Duration maxBackoff = Duration(minutes: 5);
  static const Duration retryCheckInterval = Duration(seconds: 30);
  static const int largeQueueWarningThreshold = 50;
  static const int largeQueueCriticalThreshold = 100;
}
