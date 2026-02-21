import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:tenniscourtcare/data/database/app_database.dart';
import 'package:tenniscourtcare/presentation/providers/database_provider.dart';
import 'package:tenniscourtcare/presentation/providers/maintenance_provider.dart';
import 'package:tenniscourtcare/domain/entities/terrain.dart';
import 'package:tenniscourtcare/domain/entities/maintenance.dart';

void main() {
  group('MaintenanceNotifier - Validation métier', () {
    late ProviderContainer container;
    late AppDatabase database;
    late int terrainTerreBattueId;
    late int terrainSynthetiqueId;
    late int terrainDurId;

    setUp(() async {
      database = AppDatabase(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(database),
        ],
      );

      // Créer des terrains de test
      terrainTerreBattueId = await container.read(databaseProvider).insertTerrain(
            Terrain(
              id: 0,
              nom: 'Terre battue',
              type: TerrainType.terreBattue,
            ),
          );

      terrainSynthetiqueId = await container.read(databaseProvider).insertTerrain(
            Terrain(
              id: 0,
              nom: 'Synthétique',
              type: TerrainType.synthetique,
            ),
          );

      terrainDurId = await container.read(databaseProvider).insertTerrain(
            Terrain(
              id: 0,
              nom: 'Dur',
              type: TerrainType.dur,
            ),
          );
    });

    tearDown(() async {
      container.dispose();
      await database.close();
    });

    test('terre battue: autorise manto et sottomanto', () async {
      final notifier = container.read(maintenanceNotifierProvider.notifier);

      final maintenance = Maintenance(
        terrainId: terrainTerreBattueId,
        type: 'Nettoyage',
        date: DateTime.now().millisecondsSinceEpoch,
        sacsMantoUtilises: 5,
        sacsSottomantoUtilises: 3,
        sacsSiliceUtilises: 0,
      );

      await notifier.addMaintenance(maintenance);

      // Pas d'erreur = succès
      expect(container.read(maintenanceNotifierProvider).hasValue, true);
    });

    test('terre battue: rejette silice', () async {
      final notifier = container.read(maintenanceNotifierProvider.notifier);

      final maintenance = Maintenance(
        terrainId: terrainTerreBattueId,
        type: 'Nettoyage',
        date: DateTime.now().millisecondsSinceEpoch,
        sacsMantoUtilises: 5,
        sacsSottomantoUtilises: 3,
        sacsSiliceUtilises: 1, // ❌ Interdit
      );

      expect(
        () => notifier.addMaintenance(maintenance),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('silice'),
        )),
      );
    });

    test('synthétique: autorise silice uniquement', () async {
      final notifier = container.read(maintenanceNotifierProvider.notifier);

      final maintenance = Maintenance(
        terrainId: terrainSynthetiqueId,
        type: 'Nettoyage',
        date: DateTime.now().millisecondsSinceEpoch,
        sacsMantoUtilises: 0,
        sacsSottomantoUtilises: 0,
        sacsSiliceUtilises: 8,
      );

      await notifier.addMaintenance(maintenance);

      expect(container.read(maintenanceNotifierProvider).hasValue, true);
    });

    test('synthétique: rejette manto', () async {
      final notifier = container.read(maintenanceNotifierProvider.notifier);

      final maintenance = Maintenance(
        terrainId: terrainSynthetiqueId,
        type: 'Nettoyage',
        date: DateTime.now().millisecondsSinceEpoch,
        sacsMantoUtilises: 1, // ❌ Interdit
        sacsSottomantoUtilises: 0,
        sacsSiliceUtilises: 8,
      );

      expect(
        () => notifier.addMaintenance(maintenance),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('synthétique'),
        )),
      );
    });

    test('synthétique: rejette sottomanto', () async {
      final notifier = container.read(maintenanceNotifierProvider.notifier);

      final maintenance = Maintenance(
        terrainId: terrainSynthetiqueId,
        type: 'Nettoyage',
        date: DateTime.now().millisecondsSinceEpoch,
        sacsMantoUtilises: 0,
        sacsSottomantoUtilises: 1, // ❌ Interdit
        sacsSiliceUtilises: 8,
      );

      expect(
        () => notifier.addMaintenance(maintenance),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('synthétique'),
        )),
      );
    });

    test('dur: autorise maintenance sans matériaux', () async {
      final notifier = container.read(maintenanceNotifierProvider.notifier);

      final maintenance = Maintenance(
        terrainId: terrainDurId,
        type: 'Nettoyage',
        date: DateTime.now().millisecondsSinceEpoch,
        sacsMantoUtilises: 0,
        sacsSottomantoUtilises: 0,
        sacsSiliceUtilises: 0, // Aucun matériau autorisé
      );

      await notifier.addMaintenance(maintenance);

      expect(container.read(maintenanceNotifierProvider).hasValue, true);
    });

    test('dur: rejette manto', () async {
      final notifier = container.read(maintenanceNotifierProvider.notifier);

      final maintenance = Maintenance(
        terrainId: terrainDurId,
        type: 'Nettoyage',
        date: DateTime.now().millisecondsSinceEpoch,
        sacsMantoUtilises: 1, // ❌ Interdit
        sacsSottomantoUtilises: 0,
        sacsSiliceUtilises: 0,
      );

      expect(
        () => notifier.addMaintenance(maintenance),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('matériaux'),
        )),
      );
    });

    test('dur: rejette sottomanto', () async {
      final notifier = container.read(maintenanceNotifierProvider.notifier);

      final maintenance = Maintenance(
        terrainId: terrainDurId,
        type: 'Nettoyage',
        date: DateTime.now().millisecondsSinceEpoch,
        sacsMantoUtilises: 0,
        sacsSottomantoUtilises: 1, // ❌ Interdit
        sacsSiliceUtilises: 0,
      );

      expect(
        () => notifier.addMaintenance(maintenance),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('matériaux'),
        )),
      );
    });

    test('dur: rejette silice', () async {
      final notifier = container.read(maintenanceNotifierProvider.notifier);

      final maintenance = Maintenance(
        terrainId: terrainDurId,
        type: 'Nettoyage',
        date: DateTime.now().millisecondsSinceEpoch,
        sacsMantoUtilises: 0,
        sacsSottomantoUtilises: 0,
        sacsSiliceUtilises: 1, // ❌ Interdit
      );

      expect(
        () => notifier.addMaintenance(maintenance),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('matériaux'),
        )),
      );
    });

    test('dur: rejette type "Recharge"', () async {
      final notifier = container.read(maintenanceNotifierProvider.notifier);

      final maintenance = Maintenance(
        terrainId: terrainDurId,
        type: 'Recharge', // ❌ Interdit
        date: DateTime.now().millisecondsSinceEpoch,
        sacsMantoUtilises: 0,
        sacsSottomantoUtilises: 0,
        sacsSiliceUtilises: 0,
      );

      expect(
        () => notifier.addMaintenance(maintenance),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Recharge'),
        )),
      );
    });

    test('dur: rejette type "Compactage"', () async {
      final notifier = container.read(maintenanceNotifierProvider.notifier);

      final maintenance = Maintenance(
        terrainId: terrainDurId,
        type: 'Compactage', // ❌ Interdit
        date: DateTime.now().millisecondsSinceEpoch,
        sacsMantoUtilises: 0,
        sacsSottomantoUtilises: 0,
        sacsSiliceUtilises: 0,
      );

      expect(
        () => notifier.addMaintenance(maintenance),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Compactage'),
        )),
      );
    });

    test('dur: rejette type "Décompactage"', () async {
      final notifier = container.read(maintenanceNotifierProvider.notifier);

      final maintenance = Maintenance(
        terrainId: terrainDurId,
        type: 'Décompactage', // ❌ Interdit
        date: DateTime.now().millisecondsSinceEpoch,
        sacsMantoUtilises: 0,
        sacsSottomantoUtilises: 0,
        sacsSiliceUtilises: 0,
      );

      expect(
        () => notifier.addMaintenance(maintenance),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Décompactage'),
        )),
      );
    });

    test('dur: rejette type "Travail de ligne"', () async {
      final notifier = container.read(maintenanceNotifierProvider.notifier);

      final maintenance = Maintenance(
        terrainId: terrainDurId,
        type: 'Travail de ligne', // ❌ Interdit
        date: DateTime.now().millisecondsSinceEpoch,
        sacsMantoUtilises: 0,
        sacsSottomantoUtilises: 0,
        sacsSiliceUtilises: 0,
      );

      expect(
        () => notifier.addMaintenance(maintenance),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Travail de ligne'),
        )),
      );
    });

    test('updateMaintenance valide aussi les règles', () async {
      final notifier = container.read(maintenanceNotifierProvider.notifier);

      // Créer une maintenance valide
      final maintenance = Maintenance(
        terrainId: terrainTerreBattueId,
        type: 'Nettoyage',
        date: DateTime.now().millisecondsSinceEpoch,
        sacsMantoUtilises: 5,
        sacsSottomantoUtilises: 0,
        sacsSiliceUtilises: 0,
      );

      final id = await container.read(databaseProvider).insertMaintenance(
            maintenance,
          );

      // Essayer de mettre à jour avec silice (interdit)
      final updated = maintenance.copyWith(
        id: id,
        sacsSiliceUtilises: 1, // ❌ Interdit
      );

      expect(
        () => notifier.updateMaintenance(updated),
        throwsA(isA<Exception>()),
      );
    });
  });
}
