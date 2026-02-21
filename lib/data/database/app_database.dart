import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'tables/terrain_table.dart';
import 'tables/maintenances.dart';
import 'tables/stock_items.dart'; // Nouvelle table

import '../../domain/entities/terrain.dart' as dom;
import '../../domain/entities/maintenance.dart' as domm;
import '../../domain/entities/stock_item.dart' as doms;
import '../../utils/date_utils.dart'
    as cc; // éviter collision avec Flutter DateUtils

import '../mappers/terrain_mapper.dart'; 
import '../mappers/stock_item_mapper.dart'; // Nouveau mapper

part 'app_database.g.dart';

@DriftDatabase(tables: [Terrains, Maintenances, StockItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 2; // Incrémenté pour la nouvelle table

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seedStockItems();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(stockItems);
        await _seedStockItems();
      }
    },
  );

  Future<void> _seedStockItems() async {
    final now = DateTime.now();
    final items = [
      doms.StockItem(name: 'Manto', quantity: 0, unit: 'sacs', isCustom: false, minThreshold: 24, updatedAt: now),
      doms.StockItem(name: 'SottoManto', quantity: 0, unit: 'sacs', isCustom: false, minThreshold: 24, updatedAt: now),
      doms.StockItem(name: 'Scilice', quantity: 0, unit: 'sacs', isCustom: false, minThreshold: 24, updatedAt: now),
      doms.StockItem(name: 'Filets', quantity: 0, unit: 'pcs', isCustom: false, minThreshold: 1, updatedAt: now),
      doms.StockItem(name: 'Raclettes', quantity: 0, unit: 'pcs', isCustom: false, minThreshold: 10, updatedAt: now),
      doms.StockItem(name: 'Balais', quantity: 0, unit: 'pcs', isCustom: false, minThreshold: 2, updatedAt: now),
      doms.StockItem(name: 'Sacs poubelle', quantity: 0, unit: 'pcs', isCustom: false, minThreshold: 50, updatedAt: now),
      doms.StockItem(name: 'Peinture', quantity: 0, unit: 'L', isCustom: false, minThreshold: 5, updatedAt: now),
    ];
    
    await batch((b) {
      b.insertAll(stockItems, items.map((i) => i.toCompanion()).toList());
    });
  }

  // ========== STOCK ITEMS ==========

  Stream<List<doms.StockItem>> watchAllStockItems() {
    return (select(stockItems)..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch()
        .map((rows) => rows.map((r) => r.toDomain()).toList());
  }

  Future<int> insertStockItem(doms.StockItem item) {
    return into(stockItems).insert(item.toCompanion());
  }

  Future<bool> updateStockItem(doms.StockItem item) {
    return update(stockItems).replace(item.toCompanion());
  }

  Future<int> deleteStockItem(int id) {
    return (delete(stockItems)..where((t) => t.id.equals(id))).go();
  }

  // ========== TERRAINS ==========

  Future<List<dom.Terrain>> getAllTerrains() async {
    final rows = await select(terrains).get();
    return rows.map((r) => r.toDomain()).toList();
  }

  Future<dom.Terrain?> getTerrainById(int id) async {
    final row = await (select(
      terrains,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row?.toDomain();
  }

  Future<int> insertTerrain(dom.Terrain terrain) {
    final companion = terrain.toCompanion(includeId: false);
    return into(terrains).insert(companion);
  }

  Future<int> updateTerrain(dom.Terrain terrain) {
    return (update(terrains)..where((t) => t.id.equals(terrain.id))).write(
      terrain.toCompanion(includeId: false),
    );
  }

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
            .get();
    return rows.map(_maintenanceFromRow).toList();
  }

  Future<domm.Maintenance?> getMaintenanceById(int id) async {
    final row = await (select(
      maintenances,
    )..where((m) => m.id.equals(id))).getSingleOrNull();
    return row != null ? _maintenanceFromRow(row) : null;
  }

  Future<int> insertMaintenance(domm.Maintenance m) {
    return into(maintenances).insert(
      MaintenancesCompanion.insert(
        terrainId: m.terrainId,
        type: m.type,
        date: m.date,
        commentaire: Value(m.commentaire),
        sacsMantoUtilises: Value(m.sacsMantoUtilises),
        sacsSottomantoUtilises: Value(m.sacsSottomantoUtilises),
        sacsSiliceUtilises: Value(m.sacsSiliceUtilises),
      ),
    );
  }

  Future<int> updateMaintenance(MaintenancesCompanion companion) {
    return update(maintenances).write(companion);
  }

  Future<int> deleteMaintenance(int id) {
    return (delete(maintenances)..where((m) => m.id.equals(id))).go();
  }

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

  Stream<List<({int date, int manto, int sottomanto, int silice})>>
  watchDailySacsSeriesForTerrains({
    required Set<int> terrainIds,
    int? start,
    int? end,
  }) {
    return watchDailySeries(terrainIds: terrainIds, start: start, end: end);
  }

  Stream<({int manto, int sottomanto, int silice})>
  watchMonthlyTotalsByTerrain({
    required int terrainId,
    required DateTime anyDay,
  }) {
    final start = cc.DateUtils.startOfMonth(anyDay);
    final end = cc.DateUtils.endOfMonth(anyDay);
    return watchSacsTotals(terrainId: terrainId, start: start, end: end);
  }

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
    if (Platform.isAndroid || Platform.isIOS) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'court_care.db'));
    return NativeDatabase.createInBackground(file);
  });
}
