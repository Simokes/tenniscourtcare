import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/sync_status.dart';
import '../providers/sync_status_provider.dart';

class SyncStatusIndicator extends ConsumerWidget {
  final String collection;

  const SyncStatusIndicator({super.key, required this.collection});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusMapAsync = ref.watch(syncStatusProvider);

    return statusMapAsync.when(
      data: (statusMap) {
        final status = statusMap[collection] ?? SyncStatus.local;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Center(child: _buildIndicator(status, context)),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const Icon(Icons.error_outline, color: Colors.grey),
    );
  }

  Widget _buildIndicator(SyncStatus status, BuildContext context) {
    switch (status) {
      case SyncStatus.local:
        return Tooltip(
          message: 'Local (non synchronisé)',
          child: Icon(Icons.cloud_off, color: Colors.grey.shade400, size: 20),
        );
      case SyncStatus.syncing:
        return const Tooltip(
          message: 'Synchronisation en cours...',
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      case SyncStatus.synced:
        return Tooltip(
          message: 'Synchronisé',
          child: Icon(Icons.cloud_done, color: Colors.green.shade400, size: 20),
        );
      case SyncStatus.error:
        return const Tooltip(
          message: 'Erreur de synchronisation',
          child: Icon(Icons.cloud_off, color: Colors.red, size: 20),
        );
    }
  }
}
