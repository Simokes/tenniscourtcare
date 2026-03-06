import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../data/services/firebase_cache_service.dart';

// ✅ FIX: throw si pas overridé → détecte les usages incorrects
final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError(
    'databaseProvider must be overridden in main.dart via ProviderScope. '
    'Make sure to import core_providers.dart (not database_provider.dart).',
  );
});

final firebaseCacheServiceProvider = Provider<FirebaseCacheService>((ref) {
  final db = ref.watch(databaseProvider);
  final fs = FirebaseFirestore.instance;
  return FirebaseCacheService(db, fs);
});
