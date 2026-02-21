import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  // Singleton instance
  return AppDatabase();
});
