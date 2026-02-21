import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:tenniscourtcare/data/database/app_database.dart';
import 'package:tenniscourtcare/domain/entities/terrain.dart';
import 'package:tenniscourtcare/domain/entities/maintenance.dart';
import 'package:tenniscourtcare/utils/date_utils.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;

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
      final expectedManto = 7;
      
      // On utilise expectLater pour s'assurer de capturer le flux d'événements
      final expectation = expectLater(
        database.watchSacsTotals(terrainId: terrainTerreBattueId),
        emitsInOrder([
          (manto: 0, sottomanto: 0, silice: 0), // Valeur initiale (vide)
          (manto: expectedManto, sottomanto: 3, silice: 0), // Après insertion
        ]),
      );

      await database.insertMaintenance(
        Maintenance(
          terrainId: terrainTerreBattueId,
          type: 'Nettoyage',
          date: DateTime.now().millisecondsSinceEpoch,
          sacsMantoUtilises: expectedManto,
          sacsSottomantoUtilises: 3,
          sacsSiliceUtilises: 0,
        ),
      );

      await expectation;
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

      // La première valeur émise après les inserts devrait être 5
      final value = await stream.firstWhere((v) => v.manto > 0);
      expect(value.manto, 5); 
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

      final value = await stream.firstWhere((v) => v.manto == 5 && v.silice == 8);
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
      final todayStart = DateUtils.startOfDay(DateTime.now());
      
      // On insère deux maintenances avec EXACTEMENT le même timestamp (début de journée)
      // car le SQL groupe par la valeur brute de la colonne 'date'.
      await database.insertMaintenance(
        Maintenance(
          terrainId: terrainId,
          type: 'Nettoyage',
          date: todayStart,
          sacsMantoUtilises: 5,
          sacsSottomantoUtilises: 0,
          sacsSiliceUtilises: 0,
        ),
      );

      await database.insertMaintenance(
        Maintenance(
          terrainId: terrainId,
          type: 'Réparation',
          date: todayStart,
          sacsMantoUtilises: 3,
          sacsSottomantoUtilises: 0,
          sacsSiliceUtilises: 0,
        ),
      );

      final series = await database.watchDailySacsSeriesForTerrains(
        terrainIds: {terrainId},
        start: todayStart,
        end: DateUtils.endOfDay(DateTime.now()),
      ).firstWhere((s) => s.isNotEmpty);

      expect(series.length, 1);
      expect(series.first.manto, 8); // 5 + 3
      expect(series.first.date, todayStart);
    });
  });
}
