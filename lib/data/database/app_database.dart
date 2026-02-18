import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'tables/terrain_table.dart';
import 'tables/maintenances.dart';
import '../../domain/entities/terrain.dart';
import '../../domain/entities/maintenance.dart';
import '../../utils/date_utils.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Terrains, Maintenances])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Migrations futures ici
      },
    );
  }

  // ========== TERRAINS ==========

  Future<List<Terrain>> getAllTerrains() async {
    final rows = await (select(terrains)).get();
    return rows.map((row) => _terrainFromRow(row)).toList();
  }

  Future<Terrain?> getTerrainById(int id) async {
    final row = await (select(terrains)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row != null ? _terrainFromRow(row) : null;
  }

  Future<int> insertTerrain(Terrain terrain) {
    return into(terrains).insert(TerrainsCompanion.insert(
      nom: terrain.nom,
      type: terrain.type.index,
    ));
  }

  Future<bool> updateTerrain(Terrain terrain) {
    return update(terrains).replace(TerrainsRow(
      id: terrain.id,
      nom: terrain.nom,
      type: terrain.type.index,
    ));
  }

  Future<bool> deleteTerrain(int id) {
    return delete(terrains).delete(TerrainsRow(
      id: id,
      nom: '',
      type: 0,
    ));
  }

  Terrain _terrainFromRow(TerrainsRow row) {
    return Terrain(
      id: row.id,
      nom: row.nom,
      type: TerrainType.values[row.type],
    );
  }

  // ========== MAINTENANCES ==========

  Future<List<Maintenance>> getMaintenancesForTerrain(int terrainId) async {
    final rows = await (select(maintenances)
          ..where((m) => m.terrainId.equals(terrainId))
          ..orderBy([(m) => OrderingTerm.desc(m.date)]))
        .get();
    return rows.map((row) => _maintenanceFromRow(row)).toList();
  }

  Future<Maintenance?> getMaintenanceById(int id) async {
    final row = await (select(maintenances)..where((m) => m.id.equals(id)))
        .getSingleOrNull();
    return row != null ? _maintenanceFromRow(row) : null;
  }

  Future<int> insertMaintenance(Maintenance maintenance) {
    return into(maintenances).insert(MaintenancesCompanion.insert(
      terrainId: maintenance.terrainId,
      type: maintenance.type,
      commentaire: Value(maintenance.commentaire),
      date: maintenance.date,
      sacsMantoUtilises: maintenance.sacsMantoUtilises,
      sacsSottomantoUtilises: maintenance.sacsSottomantoUtilises,
      sacsSiliceUtilises: maintenance.sacsSiliceUtilises,
    ));
  }

  Future<bool> updateMaintenance(MaintenancesCompanion companion) {
    return update(maintenances).write(companion);
  }

  Future<bool> deleteMaintenance(int id) {
    return (delete(maintenances)..where((m) => m.id.equals(id))).go();
  }

  Maintenance _maintenanceFromRow(MaintenancesRow row) {
    return Maintenance(
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

  /// Watcher pour les totaux de sacs avec filtres optionnels
  Stream<({int manto, int sottomanto, int silice})> watchSacsTotals({
    int? terrainId,
    int? start,
    int? end,
  }) {
    var query = selectOnly(maintenances)
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

  /// Watcher pour les totaux de sacs pour plusieurs terrains
  Stream<({int manto, int sottomanto, int silice})>
      watchSacsTotalsAllTerrains({
    required Set<int> terrainIds,
    int? start,
    int? end,
  }) {
    var query = selectOnly(maintenances)
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

  /// Watcher pour les totaux mensuels par terrain
  Stream<({int manto, int sottomanto, int silice})>
      watchMonthlyTotalsByTerrain({
    required int terrainId,
    required DateTime anyDay,
  }) {
    final start = DateUtils.startOfMonth(anyDay);
    final end = DateUtils.endOfMonth(anyDay);

    return watchSacsTotals(
      terrainId: terrainId,
      start: start,
      end: end,
    );
  }

  /// Watcher pour les totaux mensuels tous terrains
  Stream<({int manto, int sottomanto, int silice})>
      watchMonthlyTotalsAllTerrains({
    required Set<int> terrainIds,
    required DateTime anyDay,
  }) {
    final start = DateUtils.startOfMonth(anyDay);
    final end = DateUtils.endOfMonth(anyDay);

    return watchSacsTotalsAllTerrains(
      terrainIds: terrainIds,
      start: start,
      end: end,
    );
  }

  /// Watcher pour les séries journalières (par jour)
  Stream<List<({int date, int manto, int sottomanto, int silice})>>
      watchDailySeries({
    required Set<int> terrainIds,
    int? start,
    int? end,
  }) {
    var query = selectOnly(maintenances)
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

  /// Watcher pour les séries hebdomadaires (par semaine)
  Stream<List<({int weekStart, int manto, int sottomanto, int silice})>>
      watchWeeklySeries({
    required Set<int> terrainIds,
    int? start,
    int? end,
  }) {
    // Pour simplifier, on groupe par semaine en utilisant date_trunc équivalent
    // En SQLite, on utilise strftime pour extraire l'année et le numéro de semaine
    var query = selectOnly(maintenances)
      ..addColumns([
        // On calcule le début de semaine pour chaque date
        // SQLite: strftime('%Y-%W', datetime(date/1000, 'unixepoch'))
        // Mais on veut l'epoch ms du début de semaine, donc on fait un GROUP BY approximatif
        // Pour l'instant, on groupe par date et on agrège manuellement côté Dart
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
      // Grouper par semaine côté Dart
      final Map<int, ({int manto, int sottomanto, int silice})> weeklyMap = {};
      for (final row in rows) {
        final dateMs = row.read(maintenances.date)!;
        final date = DateTime.fromMillisecondsSinceEpoch(dateMs);
        final weekStart = DateUtils.startOfWeek(date);

        final existing = weeklyMap[weekStart] ?? (manto: 0, sottomanto: 0, silice: 0);
        weeklyMap[weekStart] = (
          manto: existing.manto + (row.read(maintenances.sacsMantoUtilises.sum()) ?? 0),
          sottomanto: existing.sottomanto + (row.read(maintenances.sacsSottomantoUtilises.sum()) ?? 0),
          silice: existing.silice + (row.read(maintenances.sacsSiliceUtilises.sum()) ?? 0),
        );
      }

      return weeklyMap.entries
          .map((e) => (weekStart: e.key, manto: e.value.manto, sottomanto: e.value.sottomanto, silice: e.value.silice))
          .toList()
        ..sort((a, b) => a.weekStart.compareTo(b.weekStart));
    });
  }

  /// Watcher pour les séries mensuelles (par mois)
  Stream<List<({int monthStart, int manto, int sottomanto, int silice})>>
      watchMonthlySeries({
    required Set<int> terrainIds,
    int? start,
    int? end,
  }) {
    var query = selectOnly(maintenances)
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
      // Grouper par mois côté Dart
      final Map<int, ({int manto, int sottomanto, int silice})> monthlyMap = {};
      for (final row in rows) {
        final dateMs = row.read(maintenances.date)!;
        final date = DateTime.fromMillisecondsSinceEpoch(dateMs);
        final monthStart = DateUtils.startOfMonth(date);

        final existing = monthlyMap[monthStart] ?? (manto: 0, sottomanto: 0, silice: 0);
        monthlyMap[monthStart] = (
          manto: existing.manto + (row.read(maintenances.sacsMantoUtilises.sum()) ?? 0),
          sottomanto: existing.sottomanto + (row.read(maintenances.sacsSottomantoUtilises.sum()) ?? 0),
          silice: existing.silice + (row.read(maintenances.sacsSiliceUtilises.sum()) ?? 0),
        );
      }

      return monthlyMap.entries
          .map((e) => (monthStart: e.key, manto: e.value.manto, sottomanto: e.value.sottomanto, silice: e.value.silice))
          .toList()
        ..sort((a, b) => a.monthStart.compareTo(b.monthStart));
    });
  }

  /// Watcher pour les séries journalières de sacs pour plusieurs terrains
  Stream<List<({int date, int manto, int sottomanto, int silice})>>
      watchDailySacsSeriesForTerrains({
    required Set<int> terrainIds,
    int? start,
    int? end,
  }) {
    return watchDailySeries(
      terrainIds: terrainIds,
      start: start,
      end: end,
    );
  }

  /// Watcher pour les comptes de types de maintenance par jour
  Stream<List<({int date, String type, int count})>>
      watchDailyMaintenanceTypeCounts({
    required Set<int> terrainIds,
    int? start,
    int? end,
  }) {
    var query = selectOnly(maintenances)
      ..addColumns([
        maintenances.date,
        maintenances.type,
        maintenances.id.count(),
      ])
      ..where(maintenances.terrainId.isIn(terrainIds))
      ..groupBy([maintenances.date, maintenances.type])
      ..orderBy([OrderingTerm.asc(maintenances.date), OrderingTerm.asc(maintenances.type)]);

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
          type: row.read(maintenances.type)!,
          count: row.read(maintenances.id.count()) ?? 0,
        );
      }).toList();
    });
  }

  /// Compte le nombre de maintenances pour un terrain
  Future<int> getMaintenanceCount(int terrainId) async {
    final result = await (selectOnly(maintenances)
          ..addColumns([maintenances.id.count()])
          ..where(maintenances.terrainId.equals(terrainId)))
        .getSingle();
    return result.read(maintenances.id.count()) ?? 0;
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    // Initialiser sqlite3_flutter_libs pour mobile
    if (Platform.isAndroid || Platform.isIOS) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }

    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'court_care.db'));

    return NativeDatabase.createInBackground(file);
  });
}
