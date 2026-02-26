import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tenniscourtcare/data/services/firebase_sync_service.dart';
import 'package:tenniscourtcare/domain/entities/sync_status.dart';
import 'package:tenniscourtcare/presentation/providers/database_provider.dart';

final syncStatusProvider = StreamProvider<Map<String, SyncStatus>>((ref) {
  final firestore = FirebaseFirestore.instance;
  final db = ref.watch(databaseProvider);
  final syncService = FirebaseSyncService(firestore, db);
  return syncService.watchSyncStatus();
});
