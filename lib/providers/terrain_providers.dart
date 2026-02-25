import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  return db.select(db.terrains)
      .watch()
      .map((rows) {
        return rows
          .map((r) => r.toDomain())
          .where((t) => t.available)
          .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
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
        // Delete all to match server state (removals)
        await db.delete(db.terrains).go();

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
            updatedAt: Value(item.updatedAt),
            syncedAt: Value(DateTime.now()),
            imageUrl: Value(item.imageUrl),
          );
          await db.into(db.terrains).insert(companion);
        }
      });
    },
  );
}
