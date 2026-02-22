import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database_provider.dart';
import '../../domain/entities/terrain.dart';

/// Provider for the count of items that are low in stock
final lowStockCountProvider = StreamProvider<int>((ref) {
  final database = ref.watch(databaseProvider);
  return database.watchAllStockItems().map((items) {
    return items.where((item) => item.quantity <= (item.minThreshold ?? 0)).length;
  });
});

/// Provider for the count of maintenances performed today
final todayMaintenanceCountProvider = StreamProvider<int>((ref) {
  final database = ref.watch(databaseProvider);
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
  final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59).millisecondsSinceEpoch;

  // We need a set of all terrain IDs to use watchDailyMaintenanceTypeCounts
  // or we need to modify the DB method to accept an optional set.
  // For now, let's get all terrains first.
  final terrainsAsync = ref.watch(dashboardTerrainsProvider);
  
  return terrainsAsync.when(
    data: (terrains) {
      final ids = terrains.map((t) => t.id).toSet();
      if (ids.isEmpty) return Stream.value(0);
      
      return database.watchDailyMaintenanceTypeCounts(
        terrainIds: ids,
        start: startOfDay,
        end: endOfDay,
      ).map((list) => list.fold(0, (sum, item) => sum + item.count));
    },
    loading: () => Stream.value(0),
    error: (_, __) => Stream.value(0),
  );
});

/// Provider for all terrains
final dashboardTerrainsProvider = FutureProvider<List<Terrain>>((ref) async {
  final database = ref.watch(databaseProvider);
  return database.getAllTerrains();
});
