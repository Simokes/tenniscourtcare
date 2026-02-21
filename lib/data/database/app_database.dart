import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'tables/terrain_table.dart';
import 'tables/maintenances.dart';

import '../../domain/entities/terrain.dart' as dom;
import '../../domain/entities/maintenance.dart' as domm;
import '../../utils/date_utils.dart'
    as cc; // éviter collision avec Flutter DateUtils

import '../mappers/terrain_mapper.dart'; // contient row.toDomain() & domain.toCompanion()

part 'app_database.g.dart';

@DriftDatabase(tables: [Terrains, Maintenances])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async => m.createAll(),
    onUpgrade: (m, from, to) async {
      // migrations futures
    },
  );

  // ========== TERRAINS ==========

  /// Récupérer tous les terrains -> type domaine
  Future<List<dom.Terrain>> getAllTerrains() async {
    final rows = await select(terrains).get(); // List<TerrainRow>
    return rows.map((r) => r.toDomain()).toList(); // List<dom.Terrain>
  }

  /// Récupérer un terrain par id -> type domaine
  Future<dom.Terrain?> getTerrainById(int id) async {
    final row = await (select(
      terrains,
    )..where((t) => t.id.equals(id))).getSingleOrNull(); // TerrainRow?
    return row?.toDomain(); // dom.Terrain?
  }

  /// INSERT (retourne l'id auto-incrémenté)
  Future<int> insertTerrain(dom.Terrain terrain) {
    // on n’envoie pas l’id (autoIncrement)
    final companion = terrain.toCompanion(includeId: false);
    return into(terrains).insert(companion);
  }

  // UPDATE ciblé par id (WHERE + write)
  // write(...) -> Future<int> (nb de lignes affectées)
  Future<int> updateTerrain(dom.Terrain terrain) {
    return (update(terrains)..where((t) => t.id.equals(terrain.id))).write(
      terrain.toCompanion(includeId: false),
    );
  }

  // DELETE par id
  // go() -> Future<int> (nb de lignes supprimées)
  Future<int> deleteTerrain(int id) {
    return (delete(terrains)..where((t) => t.id.equals(id))).go();
  }

  // ========== MAINTENANCES ==========

  Future<List<domm.Maintenance>> getMaintenancesForTerrain(
    int terrainId,
  ) async {
    final rows =
        await (select(maintenances)
              ..where((m) => m.terrainId.equals(terrainId))
              ..orderBy([(m) => OrderingTerm.desc(m.date)]))
            .get(); // List<MaintenanceRow>
    return rows.map(_maintenanceFromRow).toList();
  }

  Future<domm.Maintenance?> getMaintenanceById(int id) async {
    final row = await (select(
      maintenances,
    )..where((m) => m.id.equals(id))).getSingleOrNull(); // MaintenanceRow?
    return row != null ? _maintenanceFromRow(row) : null;
  }

  Future<int> insertMaintenance(domm.Maintenance m) {
    return into(maintenances).insert(
      MaintenancesCompanion.insert(
        terrainId: m.terrainId, // int brut (obligatoire)
        type: m.type, // String brut (obligatoire)
        date: m.date, // int brut (obligatoire)
        commentaire: Value(m.commentaire), // Value<String?> (nullable)
        sacsMantoUtilises: Value(
          m.sacsMantoUtilises,
        ), // Value<int> si colonne a un default
        sacsSottomantoUtilises: Value(m.sacsSottomantoUtilises),
        sacsSiliceUtilises: Value(m.sacsSiliceUtilises),
      ),
    );
  }

  // write(...) -> Future<int>
  Future<int> updateMaintenance(MaintenancesCompanion companion) {
    return update(maintenances).write(companion);
  }

  // go() -> Future<int>
  Future<int> deleteMaintenance(int id) {
    return (delete(maintenances)..where((m) => m.id.equals(id))).go();
  }

  /// Mapping DB -> Domaine (row Maintenance -> entity)
  domm.Maintenance _maintenanceFromRow(MaintenanceRow row) {
    return domm.Maintenance(
      id: row.id,
      terrainId: row.terrainId,
      type: row.type,
      commentaire: row.commentaire,
      date: row.date,
      sacsMantoUtilises: row.sacsMantoUtilises,
      sacsSottomantoUtilises: row.sacsSottomantoUtilises,
      sacsSiliceUtilises: row.sacsSiliceUtilises,
    );
  }

  // ========== WATCHERS & AGRÉGATIONS ==========

  /// Totaux de sacs, avec filtres optionnels
  Stream<({int manto, int sottomanto, int silice})> watchSacsTotals({
    int? terrainId,
    int? start,
    int? end,
  }) {
    final query = selectOnly(maintenances)
      ..addColumns([
        maintenances.sacsMantoUtilises.sum(),
        maintenances.sacsSottomantoUtilises.sum(),
        maintenances.sacsSiliceUtilises.sum(),
      ]);

    if (terrainId != null) {
      query.where(maintenances.terrainId.equals(terrainId));
    }
    if (start != null) {
      query.where(maintenances.date.isBiggerOrEqualValue(start));
    }
    if (end != null) {
      query.where(maintenances.date.isSmallerOrEqualValue(end));
    }

    return query.watchSingle().map((row) {
      return (
        manto: row.read(maintenances.sacsMantoUtilises.sum()) ?? 0,
        sottomanto: row.read(maintenances.sacsSottomantoUtilises.sum()) ?? 0,
        silice: row.read(maintenances.sacsSiliceUtilises.sum()) ?? 0,
      );
    });
  }

  /// Totaux de sacs pour plusieurs terrains
  Stream<({int manto, int sottomanto, int silice})> watchSacsTotalsAllTerrains({
    required Set<int> terrainIds,
    int? start,
    int? end,
  }) {
    final query = selectOnly(maintenances)
      ..addColumns([
        maintenances.sacsMantoUtilises.sum(),
        maintenances.sacsSottomantoUtilises.sum(),
        maintenances.sacsSiliceUtilises.sum(),
      ])
      ..where(maintenances.terrainId.isIn(terrainIds));

    if (start != null) {
      query.where(maintenances.date.isBiggerOrEqualValue(start));
    }
    if (end != null) {
      query.where(maintenances.date.isSmallerOrEqualValue(end));
    }

    return query.watchSingle().map((row) {
      return (
        manto: row.read(maintenances.sacsMantoUtilises.sum()) ?? 0,
        sottomanto: row.read(maintenances.sacsSottomantoUtilises.sum()) ?? 0,
        silice: row.read(maintenances.sacsSiliceUtilises.sum()) ?? 0,
      );
    });
  }

  /// Séries journalières (par jour)
  Stream<List<({int date, int manto, int sottomanto, int silice})>>
  watchDailySeries({required Set<int> terrainIds, int? start, int? end}) {
    final query = selectOnly(maintenances)
      ..addColumns([
        maintenances.date,
        maintenances.sacsMantoUtilises.sum(),
        maintenances.sacsSottomantoUtilises.sum(),
        maintenances.sacsSiliceUtilises.sum(),
      ])
      ..where(maintenances.terrainId.isIn(terrainIds))
      ..groupBy([maintenances.date])
      ..orderBy([OrderingTerm.asc(maintenances.date)]);

    if (start != null) {
      query.where(maintenances.date.isBiggerOrEqualValue(start));
    }
    if (end != null) {
      query.where(maintenances.date.isSmallerOrEqualValue(end));
    }

    return query.watch().map((rows) {
      return rows.map((row) {
        return (
          date: row.read(maintenances.date)!,
          manto: row.read(maintenances.sacsMantoUtilises.sum()) ?? 0,
          sottomanto: row.read(maintenances.sacsSottomantoUtilises.sum()) ?? 0,
          silice: row.read(maintenances.sacsSiliceUtilises.sum()) ?? 0,
        );
      }).toList();
    });
  }

  /// Séries hebdomadaires (groupement côté Dart)
  Stream<List<({int weekStart, int manto, int sottomanto, int silice})>>
  watchWeeklySeries({required Set<int> terrainIds, int? start, int? end}) {
    final query = selectOnly(maintenances)
      ..addColumns([
        maintenances.date,
        maintenances.sacsMantoUtilises.sum(),
        maintenances.sacsSottomantoUtilises.sum(),
        maintenances.sacsSiliceUtilises.sum(),
      ])
      ..where(maintenances.terrainId.isIn(terrainIds))
      ..orderBy([OrderingTerm.asc(maintenances.date)]);

    if (start != null) {
      query.where(maintenances.date.isBiggerOrEqualValue(start));
    }
    if (end != null) {
      query.where(maintenances.date.isSmallerOrEqualValue(end));
    }

    return query.watch().map((rows) {
      final Map<int, ({int manto, int sottomanto, int silice})> weeklyMap = {};
      for (final row in rows) {
        final dateMs = row.read(maintenances.date)!;
        final date = DateTime.fromMillisecondsSinceEpoch(dateMs);
        final weekStart = cc.DateUtils.startOfWeek(date);

        final existing =
            weeklyMap[weekStart] ?? (manto: 0, sottomanto: 0, silice: 0);
        weeklyMap[weekStart] = (
          manto:
              existing.manto +
              (row.read(maintenances.sacsMantoUtilises.sum()) ?? 0),
          sottomanto:
              existing.sottomanto +
              (row.read(maintenances.sacsSottomantoUtilises.sum()) ?? 0),
          silice:
              existing.silice +
              (row.read(maintenances.sacsSiliceUtilises.sum()) ?? 0),
        );
      }

      return weeklyMap.entries
          .map(
            (e) => (
              weekStart: e.key,
              manto: e.value.manto,
              sottomanto: e.value.sottomanto,
              silice: e.value.silice,
            ),
          )
          .toList()
        ..sort((a, b) => a.weekStart.compareTo(b.weekStart));
    });
  }

  /// Séries mensuelles (groupement côté Dart)
  Stream<List<({int monthStart, int manto, int sottomanto, int silice})>>
  watchMonthlySeries({required Set<int> terrainIds, int? start, int? end}) {
    final query = selectOnly(maintenances)
      ..addColumns([
        maintenances.date,
        maintenances.sacsMantoUtilises.sum(),
        maintenances.sacsSottomantoUtilises.sum(),
        maintenances.sacsSiliceUtilises.sum(),
      ])
      ..where(maintenances.terrainId.isIn(terrainIds))
      ..orderBy([OrderingTerm.asc(maintenances.date)]);

    if (start != null) {
      query.where(maintenances.date.isBiggerOrEqualValue(start));
    }
    if (end != null) {
      query.where(maintenances.date.isSmallerOrEqualValue(end));
    }

    return query.watch().map((rows) {
      final Map<int, ({int manto, int sottomanto, int silice})> monthlyMap = {};
      for (final row in rows) {
        final dateMs = row.read(maintenances.date)!;
        final date = DateTime.fromMillisecondsSinceEpoch(dateMs);
        final monthStart = cc.DateUtils.startOfMonth(date);

        final existing =
            monthlyMap[monthStart] ?? (manto: 0, sottomanto: 0, silice: 0);
        monthlyMap[monthStart] = (
          manto:
              existing.manto +
              (row.read(maintenances.sacsMantoUtilises.sum()) ?? 0),
          sottomanto:
              existing.sottomanto +
              (row.read(maintenances.sacsSottomantoUtilises.sum()) ?? 0),
          silice:
              existing.silice +
              (row.read(maintenances.sacsSiliceUtilises.sum()) ?? 0),
        );
      }

      return monthlyMap.entries
          .map(
            (e) => (
              monthStart: e.key,
              manto: e.value.manto,
              sottomanto: e.value.sottomanto,
              silice: e.value.silice,
            ),
          )
          .toList()
        ..sort((a, b) => a.monthStart.compareTo(b.monthStart));
    });
  }

  /// Délégation pour les séries journalières de sacs (multi-terrains)
  Stream<List<({int date, int manto, int sottomanto, int silice})>>
  watchDailySacsSeriesForTerrains({
    required Set<int> terrainIds,
    int? start,
    int? end,
  }) {
    return watchDailySeries(terrainIds: terrainIds, start: start, end: end);
  }

  /// Totaux mensuels pour **un** terrain donné
  Stream<({int manto, int sottomanto, int silice})>
  watchMonthlyTotalsByTerrain({
    required int terrainId,
    required DateTime anyDay,
  }) {
    final start = cc.DateUtils.startOfMonth(anyDay);
    final end = cc.DateUtils.endOfMonth(anyDay);
    return watchSacsTotals(terrainId: terrainId, start: start, end: end);
  }

  /// Totaux mensuels pour **plusieurs** terrains
  Stream<({int manto, int sottomanto, int silice})>
  watchMonthlyTotalsAllTerrains({
    required Set<int> terrainIds,
    required DateTime anyDay,
  }) {
    final start = cc.DateUtils.startOfMonth(anyDay);
    final end = cc.DateUtils.endOfMonth(anyDay);
    return watchSacsTotalsAllTerrains(
      terrainIds: terrainIds,
      start: start,
      end: end,
    );
  }

  /// Comptage des types de maintenance par jour
  Stream<List<({int date, String type, int count})>>
  watchDailyMaintenanceTypeCounts({
    required Set<int> terrainIds,
    int? start,
    int? end,
  }) {
    final query = selectOnly(maintenances)
      ..addColumns([
        maintenances.date,
        maintenances.type,
        maintenances.id.count(),
      ])
      ..where(maintenances.terrainId.isIn(terrainIds))
      ..groupBy([maintenances.date, maintenances.type])
      ..orderBy([
        OrderingTerm.asc(maintenances.date),
        OrderingTerm.asc(maintenances.type),
      ]);

    if (start != null) {
      query.where(maintenances.date.isBiggerOrEqualValue(start));
    }
    if (end != null) {
      query.where(maintenances.date.isSmallerOrEqualValue(end));
    }

    return query.watch().map((rows) {
      return rows
          .map(
            (row) => (
              date: row.read(maintenances.date)!,
              type: row.read(maintenances.type)!,
              count: row.read(maintenances.id.count()) ?? 0,
            ),
          )
          .toList();
    });
  }

  /// Compte le nombre de maintenances pour un terrain
  Future<int> getMaintenanceCount(int terrainId) async {
    final result =
        await (selectOnly(maintenances)
              ..addColumns([maintenances.id.count()])
              ..where(maintenances.terrainId.equals(terrainId)))
            .getSingle();
    return result.read(maintenances.id.count()) ?? 0;
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    // sqlite3_flutter_libs pour Android/iOS
    if (Platform.isAndroid || Platform.isIOS) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'court_care.db'));
    return NativeDatabase.createInBackground(file);
  });
}
