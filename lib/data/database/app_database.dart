import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'tables/terrain_table.dart';
import 'tables/maintenances.dart';
import 'tables/stock_items.dart';
import 'tables/users_table.dart';

import '../../domain/entities/terrain.dart' as dom;
import '../../domain/entities/maintenance.dart' as domm;
import '../../domain/entities/stock_item.dart' as doms;
import '../../domain/entities/user_entity.dart' as domu;
import '../../domain/enums/role.dart';
import '../../utils/date_utils.dart' as cc;

import '../mappers/terrain_mapper.dart'; 
import '../mappers/stock_item_mapper.dart';
import '../mappers/user_mapper.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Terrains, Maintenances, StockItems, Users])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 3;

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
      if (from < 3) {
        await m.createTable(users);
      }
    },
  );

  Future<void> _seedStockItems() async {
    final now = DateTime.now();
    final items = [
      doms.StockItem(name: 'Manto', quantity: 0, unit: 'sacs', isCustom: false, minThreshold: 10, updatedAt: now),
      doms.StockItem(name: 'Sottomanto', quantity: 0, unit: 'sacs', isCustom: false, minThreshold: 5, updatedAt: now),
      doms.StockItem(name: 'Silice', quantity: 0, unit: 'sacs', isCustom: false, minThreshold: 10, updatedAt: now),
      doms.StockItem(name: 'Balles', quantity: 0, unit: 'pcs', isCustom: false, minThreshold: 24, updatedAt: now),
      doms.StockItem(name: 'Filets', quantity: 0, unit: 'pcs', isCustom: false, minThreshold: 1, updatedAt: now),
      doms.StockItem(name: 'Peinture', quantity: 0, unit: 'L', isCustom: false, minThreshold: 5, updatedAt: now),
      doms.StockItem(name: 'Balais', quantity: 0, unit: 'pcs', isCustom: false, minThreshold: 2, updatedAt: now),
    ];
    
    await batch((b) {
      b.insertAll(stockItems, items.map((i) => i.toCompanion()).toList());
    });
  }

  // ========== USERS ==========

  Future<domu.UserEntity?> getUserByEmail(String email) async {
    final row = await (select(users)..where((u) => u.email.equals(email))).getSingleOrNull();
    return row?.toDomain();
  }

  // Cette méthode retourne le UserRow complet (avec hash) pour la vérification du mot de passe
  Future<UserRow?> getUserRowByEmail(String email) async {
    return (select(users)..where((u) => u.email.equals(email))).getSingleOrNull();
  }

  Future<List<domu.UserEntity>> getAllUsers() async {
    final rows = await select(users).get();
    return rows.map((r) => r.toDomain()).toList();
  }

  Future<int> insertUser(UsersCompanion companion) {
    return into(users).insert(companion);
  }

  Future<int> updateUserRole(int userId, Role newRole) {
    return (update(users)..where((u) => u.id.equals(userId))).write(
      UsersCompanion(role: Value(newRole)),
    );
  }

  Future<int> updateLastLogin(int userId) {
    return (update(users)..where((u) => u.id.equals(userId))).write(
      UsersCompanion(lastLoginAt: Value(DateTime.now())),
    );
  }

  Future<int> countUsersByRole(Role role) async {
    final count = await (selectOnly(users)
      ..addColumns([users.id.count()])
      ..where(users.role.equals(role.name)) // Drift enum stored as string? No, mapped via enum.
      // Wait, if I used textEnum<Role>(), Drift handles the mapping automatically in Dart code
      // but generates SQL as text.
      // However, for selectOnly and where, I should pass the enum value if Drift generated the code correctly.
      // But since I am using textEnum(), the column is TextColumn but typed as Role in Dart?
      // Actually with textEnum, the generated column is of type EnumColumn<Role> effectively?
      // No, let's check generated code behavior.
      // If I used `textEnum<Role>()`, then `users.role` is an `Expression<Role>`.
      // So I should just pass `role` (the enum value).
    ).getSingle();
    return count.read(users.id.count()) ?? 0;
  }

  // Correction for countUsersByRole:
  // With textEnum, we might need to rely on the generated code.
  // I will write a simple version first.
  Future<int> countUsers() async {
     final count = await (selectOnly(users)..addColumns([users.id.count()])).getSingle();
     return count.read(users.id.count()) ?? 0;
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

  Future<void> updateStockItemOrder(List<StockItemsCompanion> items) async {
    await batch((batch) {
      for (final item in items) {
        batch.replace(stockItems, item);
      }
    });
  }

  // ========== MAINTENANCES AVEC STOCK ==========

  Future<void> insertMaintenanceWithStockCheck(domm.Maintenance m) async {
    return transaction(() async {
      // 1. Récupérer les items de stock
      final stockList = await select(stockItems).get();
      
      void checkAndDec(String name, int used) {
        if (used <= 0) return;
        final itemRow = stockList.firstWhere(
          (i) => i.name.toLowerCase() == name.toLowerCase(),
          orElse: () => throw Exception("Article de stock '$name' introuvable."),
        );
        
        if (itemRow.quantity < used) {
          throw Exception("Stock insuffisant pour $name (${itemRow.quantity} disponibles, $used requis).");
        }
        
        // Mise à jour de la quantité en base
        (update(stockItems)..where((t) => t.id.equals(itemRow.id))).write(
          StockItemsCompanion(
            quantity: Value(itemRow.quantity - used),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }

      // 2. On déduit les stocks (quel que soit le type de maintenance)
      checkAndDec('Manto', m.sacsMantoUtilises);
      checkAndDec('Sottomanto', m.sacsSottomantoUtilises);
      checkAndDec('Silice', m.sacsSiliceUtilises);

      // 3. Insérer la maintenance
      await into(maintenances).insert(
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
    });
  }

  Future<void> deleteMaintenanceWithStockRestoration(int maintenanceId) async {
    return transaction(() async {
      // 1. Récupérer la maintenance à supprimer
      final maintenance = await (select(maintenances)
            ..where((m) => m.id.equals(maintenanceId)))
          .getSingleOrNull();

      if (maintenance == null) {
        throw Exception("Maintenance introuvable");
      }

      // 2. Récupérer les items de stock
      final stockList = await select(stockItems).get();

      void restoreStock(String name, int used) {
        if (used <= 0) return;
        final itemRow = stockList.firstWhere(
          (i) => i.name.toLowerCase() == name.toLowerCase(),
          orElse: () =>
              throw Exception("Article de stock '$name' introuvable."),
        );

        // Ré-incrémenter le stock
        (update(stockItems)..where((t) => t.id.equals(itemRow.id))).write(
          StockItemsCompanion(
            quantity: Value(itemRow.quantity + used),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }

      // 3. Restaurer les stocks
      restoreStock('Manto', maintenance.sacsMantoUtilises);
      restoreStock('Sottomanto', maintenance.sacsSottomantoUtilises);
      restoreStock('Silice', maintenance.sacsSiliceUtilises);

      // 4. Supprimer la maintenance
      await (delete(maintenances)..where((m) => m.id.equals(maintenanceId)))
          .go();
    });
  }

  Future<void> updateMaintenanceWithStockAdjustment(
    domm.Maintenance newMaintenance,
  ) async {
    if (newMaintenance.id == null) {
      throw Exception('ID de maintenance requis pour la mise à jour');
    }

    return transaction(() async {
      // 1. Récupérer l'ancienne maintenance
      final oldMaintenance = await (select(maintenances)
            ..where((m) => m.id.equals(newMaintenance.id!)))
          .getSingleOrNull();

      if (oldMaintenance == null) {
        throw Exception("Maintenance originale introuvable");
      }

      // 2. Récupérer les items de stock
      final stockList = await select(stockItems).get();

      void adjustStock(String name, int oldUsed, int newUsed) {
        final diff = newUsed - oldUsed;
        if (diff == 0) return;

        final itemRow = stockList.firstWhere(
          (i) => i.name.toLowerCase() == name.toLowerCase(),
          orElse: () =>
              throw Exception("Article de stock '$name' introuvable."),
        );

        if (diff > 0) {
          // On consomme plus -> vérifier si stock suffisant
          if (itemRow.quantity < diff) {
            throw Exception(
              "Stock insuffisant pour $name (dispo: ${itemRow.quantity}, requis en plus: $diff).",
            );
          }
        }

        // Mise à jour du stock (diff peut être positif ou négatif)
        // Si diff > 0, on consomme (quantité - diff)
        // Si diff < 0, on rend (quantité - diff) car diff est négatif -> quantité + abs(diff)
        (update(stockItems)..where((t) => t.id.equals(itemRow.id))).write(
          StockItemsCompanion(
            quantity: Value(itemRow.quantity - diff),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }

      // 3. Ajuster les stocks
      adjustStock(
        'Manto',
        oldMaintenance.sacsMantoUtilises,
        newMaintenance.sacsMantoUtilises,
      );
      adjustStock(
        'Sottomanto',
        oldMaintenance.sacsSottomantoUtilises,
        newMaintenance.sacsSottomantoUtilises,
      );
      adjustStock(
        'Silice',
        oldMaintenance.sacsSiliceUtilises,
        newMaintenance.sacsSiliceUtilises,
      );

      // 4. Mettre à jour la maintenance
      await update(maintenances).replace(
        MaintenancesCompanion(
          id: Value(newMaintenance.id!),
          terrainId: Value(newMaintenance.terrainId),
          type: Value(newMaintenance.type),
          date: Value(newMaintenance.date),
          commentaire: Value(newMaintenance.commentaire),
          sacsMantoUtilises: Value(newMaintenance.sacsMantoUtilises),
          sacsSottomantoUtilises: Value(newMaintenance.sacsSottomantoUtilises),
          sacsSiliceUtilises: Value(newMaintenance.sacsSiliceUtilises),
        ),
      );
    });
  }

  Future<domm.Maintenance?> getLastMajorMaintenance(int terrainId) async {
    return (select(maintenances)
          ..where((m) => m.terrainId.equals(terrainId))
          ..where((m) => m.type.like('%Recharge%') | m.type.like('%Travaux%'))
          ..orderBy([(m) => OrderingTerm.desc(m.date)])
          ..limit(1))
        .map(_maintenanceFromRow)
        .getSingleOrNull();
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
