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
    late int terrainDurId;

    setUp(() async {
      database = AppDatabase(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(database),
        ],
      );

      // Initialiser le stock pour éviter les erreurs "Stock insuffisant"
      // On récupère les items seedés (Manto est probablement ID 1, etc.)
      // Pour faire propre, on cherche par nom
      final items = await database.watchAllStockItems().first;
      for (final item in items) {
        await database.updateStockItem(item.copyWith(quantity: 100));
      }

      // Créer des terrains de test
      terrainTerreBattueId = await database.insertTerrain(
        Terrain(
          id: 0,
          nom: 'Terre battue',
          type: TerrainType.terreBattue,
        ),
      );

      // Synthétique non utilisé dans ces tests spécifiques
      await database.insertTerrain(
        Terrain(
          id: 0,
          nom: 'Synthétique',
          type: TerrainType.synthetique,
        ),
      );

      terrainDurId = await database.insertTerrain(
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

      expect(container.read(maintenanceNotifierProvider).hasValue, true);
      final count = await database.getMaintenanceCount(terrainTerreBattueId);
      expect(count, 1);
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

    test('deleteMaintenance supprime et met à jour l\'état', () async {
      final maintenance = Maintenance(
        terrainId: terrainTerreBattueId,
        type: 'Nettoyage',
        date: DateTime.now().millisecondsSinceEpoch,
        sacsMantoUtilises: 2,
        sacsSottomantoUtilises: 0,
        sacsSiliceUtilises: 0,
      );

      final id = await database.insertMaintenance(maintenance);
      final notifier = container.read(maintenanceNotifierProvider.notifier);

      await notifier.deleteMaintenance(id, terrainTerreBattueId);

      final count = await database.getMaintenanceCount(terrainTerreBattueId);
      expect(count, 0);
      expect(container.read(maintenanceNotifierProvider), isA<AsyncData>());
    });

    test('updateMaintenance valide aussi les règles', () async {
      final notifier = container.read(maintenanceNotifierProvider.notifier);

      final maintenance = Maintenance(
        terrainId: terrainTerreBattueId,
        type: 'Nettoyage',
        date: DateTime.now().millisecondsSinceEpoch,
        sacsMantoUtilises: 5,
        sacsSottomantoUtilises: 0,
        sacsSiliceUtilises: 0,
      );

      final id = await database.insertMaintenance(maintenance);

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
