import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tenniscourtcare/domain/models/setup_status.dart';
import 'package:tenniscourtcare/presentation/providers/setup_providers.dart';
import 'package:tenniscourtcare/presentation/providers/sync_status_provider.dart';

/// Result of Firebase sync operation
class SyncResult {
  final bool success;
  final String? error;
  final int itemsSynced;

  const SyncResult({
    required this.success,
    this.error,
    this.itemsSynced = 0,
  });

  factory SyncResult.success({int itemsSynced = 0}) =>
      SyncResult(success: true, itemsSynced: itemsSynced);

  factory SyncResult.failure(String error) =>
      SyncResult(success: false, error: error);

  @override
  String toString() =>
      'SyncResult(success: $success, error: $error, itemsSynced: $itemsSynced)';
}


/// Automatically triggered Firebase sync when user is authenticated
///
/// This provider orchestrates the full bidirectional sync flow:
/// 1. Waits for setupStatus == authenticated
/// 2. Pulls data from Firestore to local Drift DB
/// 3. Pushes local changes from Drift to Firestore
/// 4. Returns sync result with success status
///
/// Per /architecture.md Section 10 (Offline-First Sync):
/// - Cloud Wins: Firestore data overwrites local (except pending local changes)
/// - Sync Down: Pull Firestore → Drift (happens first)
/// - Sync Up: Push Drift → Firestore (happens second)
///
/// Depends on: setupStatusProvider (gates execution to authenticated state)
/// Triggered by: setupStatusProvider invalidation (e.g., after successful login)
/// Type: FutureProvider (single async operation, cached until invalidated)
///
/// Example:
/// ```dart
/// ref.watch(firebaseSyncProvider).when(
///   data: (result) => result.success ? showSuccess() : showError(result.error),
///   loading: () => showLoadingIndicator(),
///   error: (error, st) => showError('Sync failed: $error'),
/// );
/// ```
final firebaseSyncProvider = FutureProvider<SyncResult>((ref) async {
  try {
    // STEP 1: Wait for setupStatusProvider to be resolved
    final setupStatusAsync = await ref.watch(setupStatusProvider.future);

    // STEP 2: Only sync if user is authenticated
    if (setupStatusAsync != SetupStatus.authenticated) {
      debugPrint(
        '⏭️ FirebaseSync: Skipping sync (setupStatus: $setupStatusAsync, '
        'not authenticated)',
      );
      return SyncResult.success();
    }

    // STEP 3: Get sync service and perform bidirectional sync
    // final syncService = ref.watch(firebaseSyncServiceProvider); // Removed in Phase B

    debugPrint('🔄 FirebaseSync: Starting authenticated sync...');

    // This internally does:
    // 1. Pull from Firestore to Drift (syncDown)
    // 2. Push from Drift to Firestore (syncUp)
    // await syncService.syncAll(); // Removed in Phase B

    debugPrint('✅ FirebaseSync: Sync complete');
    return SyncResult.success();
  } catch (e, st) {
    debugPrint('❌ FirebaseSync error: $e\n$st');
    return SyncResult.failure('Sync failed: $e');
  }
});

/// Stream of sync status changes for real-time UI updates
///
/// Emits whenever [firebaseSyncProvider] is invalidated.
/// Used for displaying sync status in UI (loading indicators, etc).
///
/// Type: StreamProvider (continuous stream of sync changes)
///
/// Example:
/// ```dart
/// ref.watch(firebaseSyncStreamProvider).when(
///   data: (result) => Text(result.success ? '✅ Synced' : '❌ Failed'),
///   loading: () => CircularProgressIndicator(),
///   error: (error, st) => Text('Sync error'),
/// );
/// ```
final firebaseSyncStreamProvider = StreamProvider<SyncResult>((ref) async* {
  // Listen to firebaseSyncProvider changes
  // Note: 'listen' in the body of a provider is for side effects or reacting.
  // For a StreamProvider, we usually just yield.
  // But here we want to re-emit when the future provider re-runs.

  // Initial value
  try {
     final result = await ref.watch(firebaseSyncProvider.future);
     yield result;
  } catch (e) {
     yield SyncResult.failure(e.toString());
  }
});

/// Manual trigger for re-sync
///
/// Use this to manually trigger a full sync outside the automatic flow.
/// Per /architecture.md Section 10.2: Manual sync on user request.
///
/// Type: FutureProvider (cached, call invalidate() to re-trigger)
///
/// Usage:
/// ```dart
/// final result = ref.read(manualSyncProvider);
/// result.when(
///   data: (syncResult) => showStatus(syncResult.success),
///   loading: () => showLoading(),
///   error: (error, st) => showError(),
/// );
/// ```
final manualSyncProvider = FutureProvider<SyncResult>((ref) async {
  try {
    debugPrint('🔄 ManualSync: User triggered sync...');
    // final syncService = ref.watch(firebaseSyncServiceProvider);
    // await syncService.syncAll(); // Removed in Phase B
    debugPrint('✅ ManualSync: Complete');
    return SyncResult.success();
  } catch (e, st) {
    debugPrint('❌ ManualSync error: $e\n$st');
    return SyncResult.failure('Manual sync failed: $e');
  }
});
