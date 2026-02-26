import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../presentation/providers/database_provider.dart';
import '../domain/entities/maintenance.dart' as dom;
import '../data/mappers/maintenance_mapper.dart';
import '../services/listener_monitor.dart';

part 'maintenance_providers.g.dart';

@Riverpod(keepAlive: true)
Stream<List<dom.Maintenance>> maintenanceStream(MaintenanceStreamRef ref) {
  final monitor = ListenerMonitor();
  monitor.registerListener('maintenanceStreamProvider');
  ref.onDispose(() => monitor.unregisterListener('maintenanceStreamProvider'));

  final db = ref.watch(databaseProvider);

  return db.select(db.maintenances).watch().map((rows) {
    // Filter first (Drift rows have status)
    final filtered = rows.where((row) => row.status != 'completed').toList();

    // Sort rows (Drift rows have createdAt)
    filtered.sort((a, b) {
      // Use createdAt
      final dateA = a.createdAt;
      final dateB = b.createdAt;
      return dateB.compareTo(dateA); // DESC
    });

    // Map to domain
    return filtered.map((r) => r.toDomain()).toList();
  });
}
