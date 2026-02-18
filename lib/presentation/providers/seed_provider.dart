import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/seed_data.dart';
import 'database_provider.dart';

/// Provider pour initialiser les données de seed (uniquement en debug)
final seedDataProvider = FutureProvider<void>((ref) async {
  if (kDebugMode) {
    final database = ref.watch(databaseProvider);
    await seedDevData(database);
  }
});
