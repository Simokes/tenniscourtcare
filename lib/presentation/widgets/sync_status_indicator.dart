import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tenniscourtcare/domain/models/sync_status_model.dart';
import 'package:tenniscourtcare/presentation/providers/firebase_sync_provider.dart';

enum SyncIndicatorMode { compact, detailed, minimal }

class SyncStatusIndicator extends ConsumerWidget {
  final SyncIndicatorMode mode;

  const SyncStatusIndicator({
    super.key,
    this.mode = SyncIndicatorMode.compact,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(currentSyncStatusProvider);

    return statusAsync.when(
      data: (status) => _buildContent(context, ref, status),
      loading: () => _buildLoading(context),
      error: (err, st) => _buildError(context, ref, err.toString()),
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, SyncStatusModel status) {
    if (status.isSyncing) {
      return _buildSyncing(context);
    }
    if (status.hasError) {
      return _buildErrorState(context, ref, status.errorMessage);
    }
    return _buildSuccess(context, status.lastSyncTime);
  }

  Widget _buildLoading(BuildContext context) {
    // Initial loading of provider (rare)
    return const SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String error) {
    return _buildErrorState(context, ref, error);
  }

  // --- STATE BUILDERS ---

  Widget _buildSyncing(BuildContext context) {
    switch (mode) {
      case SyncIndicatorMode.minimal:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case SyncIndicatorMode.compact:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('Syncing...', style: TextStyle(fontSize: 12)),
          ],
        );
      case SyncIndicatorMode.detailed:
        return const ListTile(
          leading: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          title: Text('Syncing data...'),
          subtitle: Text('Please wait'),
        );
    }
  }

  Widget _buildErrorState(
      BuildContext context, WidgetRef ref, String? message) {
    final msg = message ?? 'Sync failed';

    void onRetry() {
      ref.invalidate(firebaseSyncProvider);
    }

    switch (mode) {
      case SyncIndicatorMode.minimal:
        return IconButton(
          icon: const Icon(Icons.sync_problem, color: Colors.red),
          onPressed: onRetry,
          tooltip: 'Retry Sync',
        );
      case SyncIndicatorMode.compact:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 16),
            const SizedBox(width: 4),
            Text(
              'Error',
              style: TextStyle(color: Colors.red.shade700, fontSize: 12),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 16),
              onPressed: onRetry,
              tooltip: 'Retry',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        );
      case SyncIndicatorMode.detailed:
        return ListTile(
          leading: const Icon(Icons.error, color: Colors.red),
          title: const Text('Sync Failed'),
          subtitle: Text(msg),
          trailing: ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        );
    }
  }

  Widget _buildSuccess(BuildContext context, DateTime lastSync) {
    final timeStr = _formatTime(lastSync);

    switch (mode) {
      case SyncIndicatorMode.minimal:
        return const Icon(Icons.cloud_done, color: Colors.green, size: 20);
      case SyncIndicatorMode.compact:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
            const SizedBox(width: 4),
            Text(
              'Synced $timeStr',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        );
      case SyncIndicatorMode.detailed:
        return ListTile(
          leading: const Icon(Icons.check_circle, color: Colors.green),
          title: const Text('Data Synced'),
          subtitle: Text('Last update: $timeStr'),
        );
    }
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return 'yesterday'; // Simplified for now
  }
}
