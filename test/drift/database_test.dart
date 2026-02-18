import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:tenniscourtcare/data/database/app_database.dart';
import 'package:tenniscourtcare/data/database/tables/terrain_table.dart';
import 'package:tenniscourtcare/data/database/tables/maintenances.dart';
import 'package:tenniscourtcare/domain/entities/terrain.dart';
import 'package:tenniscourtcare/domain/entities/maintenance.dart';
import 'package:tenniscourtcare/utils/date_utils.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  group('Terrains', () {
    test('insert et get terrain', () async {
      final terrain = Terrain(
        id: 0,
        nom: 'Court 1',
        type: TerrainType.terreBattue,
      );

      final id = await database.insertTerrain(terrain);
      expect(id, greaterThan(0));

      final retrieved = await database.getTerrainById(id);
      expect(retrieved, isNotNull);
      expect(retrieved!.nom, 'Court 1');
      expect(retrieved.type, TerrainType.terreBattue);
    });

    test('getAllTerrains retourne tous les terrains', () async {
      await database.insertTerrain(
        Terrain(id: 0, nom: 'Court 1', type: TerrainType.terreBattue),
      );
      await database.insertTerrain(
        Terrain(id: 0, nom: 'Court 2', type: TerrainType.synthetique),
      );

      final terrains = await database.getAllTerrains();
      expect(terrains.length, 2);
    });
  });

  group('Maintenances', () {
    late int terrainId;

    setUp(() async {
      terrainId = await database.insertTerrain(
        Terrain(id: 0, nom: 'Court 1', type: TerrainType.terreBattue),
      );
    });

    test('insert et get maintenance', () async {
      final maintenance = Maintenance(
        terrainId: terrainId,
        type: 'Nettoyage',
        date: DateTime.now().millisecondsSinceEpoch,
        sacsMantoUtilises: 5,
        sacsSottomantoUtilises: 3,
        sacsSiliceUtilises: 0,
      );

      final id = await database.insertMaintenance(maintenance);
      expect(id, greaterThan(0));

      final retrieved = await database.getMaintenanceById(id);
      expect(retrieved, isNotNull);
      expect(retrieved!.type, 'Nettoyage');
      expect(retrieved.sacsMantoUtilises, 5);
    });

    test('getMaintenancesForTerrain retourne les maintenances du terrain',
        () async {
      await database.insertMaintenance(
        Maintenance(
          terrainId: terrainId,
          type: 'Nettoyage',
          date: DateTime.now().millisecondsSinceEpoch,
          sacsMantoUtilises: 5,
          sacsSottomantoUtilises: 0,
          sacsSiliceUtilises: 0,
        ),
      );

      final maintenances = await database.getMaintenancesForTerrain(terrainId);
      expect(maintenances.length, 1);
    });

    test('updateMaintenance met à jour correctement', () async {
      final id = await database.insertMaintenance(
        Maintenance(
          terrainId: terrainId,
          type: 'Nettoyage',
          date: DateTime.now().millisecondsSinceEpoch,
          sacsMantoUtilises: 5,
          sacsSottomantoUtilises: 0,
          sacsSiliceUtilises: 0,
        ),
      );

      await database.updateMaintenance(
        MaintenancesCompanion(
          id: Value(id),
          type: const Value('Réparation'),
        ),
      );

      final updated = await database.getMaintenanceById(id);
      expect(updated!.type, 'Réparation');
    });

    test('deleteMaintenance supprime correctement', () async {
      final id = await database.insertMaintenance(
        Maintenance(
          terrainId: terrainId,
          type: 'Nettoyage',
          date: DateTime.now().millisecondsSinceEpoch,
          sacsMantoUtilises: 5,
          sacsSottomantoUtilises: 0,
          sacsSiliceUtilises: 0,
        ),
      );

      await database.deleteMaintenance(id);

      final deleted = await database.getMaintenanceById(id);
      expect(deleted, isNull);
    });
  });

  group('Watchers - Totaux', () {
    late int terrainTerreBattueId;
    late int terrainSynthetiqueId;

    setUp(() async {
      terrainTerreBattueId = await database.insertTerrain(
        Terrain(id: 0, nom: 'Terre battue', type: TerrainType.terreBattue),
      );
      terrainSynthetiqueId = await database.insertTerrain(
        Terrain(id: 0, nom: 'Synthétique', type: TerrainType.synthetique),
      );
    });

    test('watchSacsTotals réémet sur insert', () async {
      final stream = database.watchSacsTotals(terrainId: terrainTerreBattueId);
      final values = <({int manto, int sottomanto, int silice})>[];

      final subscription = stream.listen((value) {
        values.add(value);
      });

      // Attendre la valeur initiale
      await Future.delayed(const Duration(milliseconds: 100));

      // Insérer une maintenance
      await database.insertMaintenance(
        Maintenance(
          terrainId: terrainTerreBattueId,
          type: 'Nettoyage',
          date: DateTime.now().millisecondsSinceEpoch,
          sacsMantoUtilises: 5,
          sacsSottomantoUtilises: 3,
          sacsSiliceUtilises: 0,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 100));

      expect(values.length, greaterThanOrEqualTo(1));
      final lastValue = values.last;
      expect(lastValue.manto, 5);
      expect(lastValue.sottomanto, 3);
      expect(lastValue.silice, 0);

      await subscription.cancel();
    });

    test('watchSacsTotals respecte les bornes temporelles', () async {
      final now = DateTime.now();
      final start = DateUtils.startOfDay(now);
      final end = DateUtils.endOfDay(now);

      final stream = database.watchSacsTotals(
        terrainId: terrainTerreBattueId,
        start: start,
        end: end,
      );

      // Insérer une maintenance aujourd'hui
      await database.insertMaintenance(
        Maintenance(
          terrainId: terrainTerreBattueId,
          type: 'Nettoyage',
          date: now.millisecondsSinceEpoch,
          sacsMantoUtilises: 5,
          sacsSottomantoUtilises: 0,
          sacsSiliceUtilises: 0,
        ),
      );

      // Insérer une maintenance hier (hors période)
      final yesterday = now.subtract(const Duration(days: 1));
      await database.insertMaintenance(
        Maintenance(
          terrainId: terrainTerreBattueId,
          type: 'Nettoyage',
          date: yesterday.millisecondsSinceEpoch,
          sacsMantoUtilises: 10,
          sacsSottomantoUtilises: 0,
          sacsSiliceUtilises: 0,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 100));

      final value = await stream.first;
      expect(value.manto, 5); // Seulement celle d'aujourd'hui
    });

    test('watchSacsTotalsAllTerrains agrège plusieurs terrains', () async {
      final stream = database.watchSacsTotalsAllTerrains(
        terrainIds: {terrainTerreBattueId, terrainSynthetiqueId},
      );

      await database.insertMaintenance(
        Maintenance(
          terrainId: terrainTerreBattueId,
          type: 'Nettoyage',
          date: DateTime.now().millisecondsSinceEpoch,
          sacsMantoUtilises: 5,
          sacsSottomantoUtilises: 0,
          sacsSiliceUtilises: 0,
        ),
      );

      await database.insertMaintenance(
        Maintenance(
          terrainId: terrainSynthetiqueId,
          type: 'Nettoyage',
          date: DateTime.now().millisecondsSinceEpoch,
          sacsMantoUtilises: 0,
          sacsSottomantoUtilises: 0,
          sacsSiliceUtilises: 8,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 100));

      final value = await stream.first;
      expect(value.manto, 5);
      expect(value.silice, 8);
    });
  });

  group('Watchers - Séries', () {
    late int terrainId;

    setUp(() async {
      terrainId = await database.insertTerrain(
        Terrain(id: 0, nom: 'Court 1', type: TerrainType.terreBattue),
      );
    });

    test('watchDailySeries groupe par jour', () async {
      final now = DateTime.now();
      final stream = database.watchDailySacsSeriesForTerrains(
        terrainIds: {terrainId},
        start: DateUtils.startOfDay(now),
        end: DateUtils.endOfDay(now),
      );

      // Insérer 2 maintenances le même jour
      await database.insertMaintenance(
        Maintenance(
          terrainId: terrainId,
          type: 'Nettoyage',
          date: now.millisecondsSinceEpoch,
          sacsMantoUtilises: 5,
          sacsSottomantoUtilises: 0,
          sacsSiliceUtilises: 0,
        ),
      );

      await database.insertMaintenance(
        Maintenance(
          terrainId: terrainId,
          type: 'Réparation',
          date: now.millisecondsSinceEpoch,
          sacsMantoUtilises: 3,
          sacsSottomantoUtilises: 0,
          sacsSiliceUtilises: 0,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 100));

      final series = await stream.first;
      expect(series.length, greaterThanOrEqualTo(1));
      final dayData = series.firstWhere(
        (d) => d.date == DateUtils.startOfDay(now),
        orElse: () => (date: 0, manto: 0, sottomanto: 0, silice: 0),
      );
      expect(dayData.manto, 8); // 5 + 3
    });
  });

  group('Invariants métier', () {
    test('terre battue ne doit pas avoir de silice en base', () async {
      final terrainId = await database.insertTerrain(
        Terrain(id: 0, nom: 'Terre battue', type: TerrainType.terreBattue),
      );

      // On peut insérer directement en base (la validation est côté Notifier)
      // Mais on vérifie que les watchers retournent silice = 0
      await database.insertMaintenance(
        Maintenance(
          terrainId: terrainId,
          type: 'Nettoyage',
          date: DateTime.now().millisecondsSinceEpoch,
          sacsMantoUtilises: 5,
          sacsSottomantoUtilises: 3,
          sacsSiliceUtilises: 0, // Correct
        ),
      );

      final stream = database.watchSacsTotals(terrainId: terrainId);
      final value = await stream.first;
      expect(value.silice, 0);
    });
  });
}
