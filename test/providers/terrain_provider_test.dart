import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:tenniscourtcare/data/database/app_database.dart';
import 'package:tenniscourtcare/presentation/providers/database_provider.dart';
import 'package:tenniscourtcare/presentation/providers/terrain_provider.dart';
import 'package:tenniscourtcare/domain/entities/terrain.dart';

void main() {
  group('Terrain Providers - CRUD', () {
    late ProviderContainer container;
    late AppDatabase database;

    setUp(() async {
      database = AppDatabase(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(database),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await database.close();
    });

    test('addTerrainProvider inserts a terrain and invalidates terrainsProvider',
        () async {
      final addTerrain = container.read(addTerrainProvider);

      final terrain = Terrain(
        id: 0,
        nom: 'Nouveau Terrain',
        type: TerrainType.terreBattue,
      );

      await addTerrain(terrain);

      final terrains = await container.read(terrainsProvider.future);
      expect(terrains, hasLength(1));
      expect(terrains.first.nom, 'Nouveau Terrain');
      expect(terrains.first.type, TerrainType.terreBattue);
    });

    test('updateTerrainProvider updates a terrain', () async {
      final addTerrain = container.read(addTerrainProvider);
      final updateTerrain = container.read(updateTerrainProvider);

      // Add initial terrain
      final terrain = Terrain(id: 0, nom: 'Terrain 1', type: TerrainType.dur);
      await addTerrain(terrain);

      var terrains = await container.read(terrainsProvider.future);
      var createdTerrain = terrains.first;

      final updated = createdTerrain.copyWith(nom: 'Terrain Modifié');
      await updateTerrain(updated);

      terrains = await container.read(terrainsProvider.future);
      expect(terrains.first.nom, 'Terrain Modifié');
      expect(terrains.first.type, TerrainType.dur);
    });

    test('deleteTerrainProvider deletes a terrain', () async {
      final addTerrain = container.read(addTerrainProvider);
      final deleteTerrain = container.read(deleteTerrainProvider);

      final terrain = Terrain(id: 0, nom: 'Terrain A', type: TerrainType.dur);
      await addTerrain(terrain);

      var terrains = await container.read(terrainsProvider.future);
      expect(terrains, hasLength(1));
      final idToDelete = terrains.first.id;

      await deleteTerrain(idToDelete);

      terrains = await container.read(terrainsProvider.future);
      expect(terrains, isEmpty);
    });
  });
}
