import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tenniscourtcare/presentation/providers/firebase_sync_provider.dart';
import 'package:tenniscourtcare/presentation/providers/sync_status_provider.dart';
import 'package:tenniscourtcare/domain/entities/sync_status.dart';

class SyncStatusModel {
  final bool isSyncing;
  final bool hasError;
  final String? errorMessage;
  final DateTime lastSyncTime;
  final int itemsSynced;

  const SyncStatusModel({
    required this.isSyncing,
    required this.hasError,
    this.errorMessage,
    required this.lastSyncTime,
    this.itemsSynced = 0,
  });

  SyncStatusModel copyWith({
    bool? isSyncing,
    bool? hasError,
    String? errorMessage,
    DateTime? lastSyncTime,
    int? itemsSynced,
  }) {
    return SyncStatusModel(
      isSyncing: isSyncing ?? this.isSyncing,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      itemsSynced: itemsSynced ?? this.itemsSynced,
    );
  }

  @override
  String toString() =>
      'SyncStatusModel(isSyncing: $isSyncing, hasError: $hasError, error: $errorMessage, lastSync: $lastSyncTime)';
}

// Stores the last successful sync time
final lastSyncTimeProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// Aggregates sync status from multiple sources into a single model
final currentSyncStatusProvider = StreamProvider<SyncStatusModel>((ref) async* {
  // Update lastSyncTime when sync completes successfully
  ref.listen<AsyncValue<SyncResult>>(firebaseSyncProvider, (previous, next) {
    if (next is AsyncData && next.valueOrNull?.success == true) {
      ref.read(lastSyncTimeProvider.notifier).state = DateTime.now();
    }
  });

  // Watch primary sync operation (Cloud <-> Local)
  final syncOperation = ref.watch(firebaseSyncProvider);

  // Watch granular status (Real-time updates from service)
  final granularStatusAsync = ref.watch(syncStatusProvider);

  // Watch last sync time
  final lastSyncTime = ref.watch(lastSyncTimeProvider);

  // Check granular status for "syncing" state (covers background uploads)
  final granularStatus = granularStatusAsync.valueOrNull ?? {};
  final isGranularSyncing =
      granularStatus.values.any((s) => s == SyncStatus.syncing);

  final isSyncing = syncOperation.isLoading || isGranularSyncing;
  var hasError = syncOperation.hasError;
  var errorMessage = syncOperation.error?.toString();
  final itemsSynced = syncOperation.valueOrNull?.itemsSynced ?? 0;

  // Check operation result for specific errors
  if (syncOperation.hasValue) {
    final result = syncOperation.value!;
    if (!result.success) {
      hasError = true;
      errorMessage = result.error;
    }
  }

  yield SyncStatusModel(
    isSyncing: isSyncing,
    hasError: hasError,
    errorMessage: errorMessage,
    lastSyncTime: lastSyncTime,
    itemsSynced: itemsSynced,
  );
});
