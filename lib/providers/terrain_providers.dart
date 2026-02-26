import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart';

import '../presentation/providers/database_provider.dart';
import '../providers/sync_providers.dart';
import '../domain/entities/terrain.dart' as dom;
import '../data/database/app_database.dart';
import '../data/firestore/models/terrain_firestore_model.dart';
import '../data/mappers/terrain_mapper.dart';
import '../services/listener_monitor.dart';

part 'terrain_providers.g.dart';

@Riverpod(keepAlive: true)
Stream<List<dom.Terrain>> terrainsStream(TerrainsStreamRef ref) {
  final monitor = ListenerMonitor();
  monitor.registerListener('terrainsStreamProvider');
  ref.onDispose(() => monitor.unregisterListener('terrainsStreamProvider'));

  final db = ref.watch(databaseProvider);

  return db.select(db.terrains).watch().map((rows) {
    return rows
        .where((row) => row.available) // Filter on Drift Row
        .map((r) => r.toDomain())
        .toList()
      ..sort(
        (a, b) => a.nom.compareTo(b.nom),
      ); // Sort on Domain Entity which has 'nom'
  });
}

@Riverpod()
Future<void> refreshTerrains(RefreshTerrainsRef ref) async {
  final sync = ref.read(syncServiceProvider);
  final db = ref.read(databaseProvider);

  await sync.refreshCollection<TerrainFirestoreModel>(
    collection: 'terrains',
    fromFirestore: (doc) => TerrainFirestoreModel.fromFirestore(doc),
    saveToLocal: (items) async {
      await db.transaction(() async {
        for (final item in items) {
          final companion = TerrainsCompanion(
            remoteId: Value(item.id),
            nom: Value(item.name),
            type: const Value(0),
            location: Value(item.location),
            capacity: Value(item.capacity),
            pricePerHour: Value(item.pricePerHour),
            available: Value(item.available),
            createdAt: Value(item.createdAt),
            updatedAt: Value(item.updatedAt ?? item.createdAt),
            syncedAt: Value(DateTime.now()),
            imageUrl: Value(item.imageUrl),
          );

          final existing = await (db.select(
            db.terrains,
          )..where((t) => t.remoteId.equals(item.id))).getSingleOrNull();

          if (existing != null) {
            await (db.update(
              db.terrains,
            )..where((t) => t.id.equals(existing.id))).write(companion);
          } else {
            await db.into(db.terrains).insert(companion);
          }
        }
      });
    },
  );
}
