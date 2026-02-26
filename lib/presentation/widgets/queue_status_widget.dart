import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/queue_status.dart';
import '../../providers/queue_providers.dart';

class QueueStatusBanner extends ConsumerWidget {
  const QueueStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(queueStatusProvider);
    final progressAsync = ref.watch(queueProgressProvider);

    // Listen to warnings/critical alerts
    ref.listen(queueWarningsProvider, (prev, next) {
      next.whenData((count) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ $count changes waiting to sync'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      });
    });

    ref.listen(queueCriticalProvider, (prev, next) {
      next.whenData((count) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🔴 CRITICAL: $count changes waiting!'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      });
    });

    return statusAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (err, st) => const SizedBox.shrink(),
      data: (status) {
        if (status.count == 0) {
          return const SizedBox.shrink();
        }

        return progressAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (err, st) => const SizedBox.shrink(),
          data: (progress) => Container(
            color: _getColorByStatus(status.status),
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${status.count} change${status.count == 1 ? '' : 's'} waiting',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (status.failedCount > 0)
                      GestureDetector(
                        onTap: () => _showErrorDialog(context, ref),
                        child: Text(
                          '${status.failedCount} failed - Tap to retry',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.progress,
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${progress.synced} of ${progress.total} synced',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getColorByStatus(QueueStatusType status) {
    switch (status) {
      case QueueStatusType.idle:
        return Colors.transparent;
      case QueueStatusType.syncing:
        return Colors.blue[50]!;
      case QueueStatusType.partialFailure:
        return Colors.orange[50]!;
    }
  }

  void _showErrorDialog(BuildContext context, WidgetRef ref) {
    // We can't watch directly inside a callback, so we use read or rely on the provider having data
    // But since the banner is already built, we can just show the dialog and inside the dialog use a Consumer

    showDialog(
      context: context,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final errorsAsync = ref.watch(queueErrorsProvider);

          return errorsAsync.when(
            loading: () => const AlertDialog(
              content: SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (err, st) => AlertDialog(
              title: const Text('Error'),
              content: Text('Failed to load errors: $err'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ],
            ),
            data: (errors) => AlertDialog(
              title: const Text('Sync Errors'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: errors.length,
                  itemBuilder: (ctx, i) {
                    final error = errors[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${error.collection} - ${error.documentId}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              error.error,
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Attempt ${error.retryCount}/3',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    ref.read(retryFailedProvider);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Retry All'),
                ),
                TextButton(
                  onPressed: () => _confirmClearQueue(ctx, ref),
                  child: const Text(
                    'Clear Queue',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmClearQueue(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Queue?'),
        content: const Text(
          'This will delete all pending changes. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(queueManagerProvider).clearQueue(confirmed: true);
              Navigator.pop(ctx);
              Navigator.pop(context); // Close error dialog too
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
