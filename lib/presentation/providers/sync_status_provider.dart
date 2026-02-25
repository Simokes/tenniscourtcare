import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/sync_status.dart';
import 'terrain_provider.dart'; // for firebaseSyncServiceProvider

final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final firebaseService = ref.watch(firebaseSyncServiceProvider);
  return firebaseService.watchSyncStatus();
});
