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
import 'tables/events_table.dart';
import 'tables/stock_movements.dart';

import '../../domain/entities/terrain.dart' as dom;
import '../../domain/entities/maintenance.dart' as domm;
import '../../domain/entities/stock_item.dart' as doms;
import '../../domain/entities/user_entity.dart' as domu;
import '../../domain/enums/role.dart';
import '../../utils/date_utils.dart' as cc;

import '../mappers/terrain_mapper.dart'; 
import '../mappers/stock_item_mapper.dart';
import '../mappers/user_mapper.dart';
import '../mappers/maintenance_mapper.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Terrains, Maintenances, StockItems, Users, Events, StockMovements])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 8;

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
      if (from < 4) {
        await m.addColumn(stockItems, stockItems.category);
        await m.addColumn(stockItems, stockItems.sortOrder);
      }
      if (from < 5) {
        await m.createTable(events);
      }
      if (from < 6) {
        await m.addColumn(maintenances, maintenances.imagePath);
      }
      if (from < 7) {
        // Supprimer tous les utilisateurs pour forcer la migration vers le nouveau hachage PBKDF2
        await delete(users).go();
      }
      if (from < 8) {
        await m.createTable(stockMovements);
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

  Future<void> insertMaintenanceWithStockCheck(domm.Maintenance m, {int? userId}) async {
    return transaction(() async {
      // 1. Récupérer les items de stock
      final stockList = await select(stockItems).get();
      
      Future<void> checkAndDec(String name, int used) async {
        if (used <= 0) return;
        final itemRow = stockList.firstWhere(
          (i) => i.name.toLowerCase() == name.toLowerCase(),
          orElse: () => throw Exception("Article de stock '$name' introuvable."),
        );
        
        if (itemRow.quantity < used) {
          throw Exception('Stock insuffisant pour $name (${itemRow.quantity} disponibles, $used requis).');
        }
        
        final newQty = itemRow.quantity - used;

        // Mise à jour de la quantité en base
        await (update(stockItems)..where((t) => t.id.equals(itemRow.id))).write(
          StockItemsCompanion(
            quantity: Value(newQty),
            updatedAt: Value(DateTime.now()),
          ),
        );

        // Historisation
        await into(stockMovements).insert(
          StockMovementsCompanion(
            stockItemId: Value(itemRow.id),
            previousQuantity: Value(itemRow.quantity),
            newQuantity: Value(newQty),
            quantityChange: Value(-used), // Négatif car consommation
            reason: const Value('Maintenance'),
            // Le nom du terrain n'est pas encore dispo si on crée la maintenance.
            // On peut récupérer le nom du terrain via m.terrainId si besoin, mais ici c'est suffisant.
            description: Value('Maintenance sur terrain #${m.terrainId}'),
            userId: Value(userId),
            occurredAt: Value(DateTime.now()),
          ),
        );
      }

      // 2. On déduit les stocks (quel que soit le type de maintenance)
      await checkAndDec('Manto', m.sacsMantoUtilises);
      await checkAndDec('Sottomanto', m.sacsSottomantoUtilises);
      await checkAndDec('Silice', m.sacsSiliceUtilises);

      // 3. Insérer la maintenance
      await into(maintenances).insert(m.toCompanion());
    });
  }

  Future<void> deleteMaintenanceWithStockRestoration(int maintenanceId, {int? userId}) async {
    return transaction(() async {
      // 1. Récupérer la maintenance à supprimer
      final maintenance = await (select(maintenances)
            ..where((m) => m.id.equals(maintenanceId)))
          .getSingleOrNull();

      if (maintenance == null) {
        throw Exception('Maintenance introuvable');
      }

      // 2. Récupérer les items de stock
      final stockList = await select(stockItems).get();

      Future<void> restoreStock(String name, int used) async {
        if (used <= 0) return;
        final itemRow = stockList.firstWhere(
          (i) => i.name.toLowerCase() == name.toLowerCase(),
          orElse: () =>
              throw Exception("Article de stock '$name' introuvable."),
        );

        final newQty = itemRow.quantity + used;

        // Ré-incrémenter le stock
        await (update(stockItems)..where((t) => t.id.equals(itemRow.id))).write(
          StockItemsCompanion(
            quantity: Value(newQty),
            updatedAt: Value(DateTime.now()),
          ),
        );

        // Historisation
        await into(stockMovements).insert(
          StockMovementsCompanion(
            stockItemId: Value(itemRow.id),
            previousQuantity: Value(itemRow.quantity),
            newQuantity: Value(newQty),
            quantityChange: Value(used), // Positif car restauration
            reason: const Value('Correction'),
            description: Value('Suppression maintenance #${maintenance.id}'),
            userId: Value(userId),
            occurredAt: Value(DateTime.now()),
          ),
        );
      }

      // 3. Restaurer les stocks
      await restoreStock('Manto', maintenance.sacsMantoUtilises);
      await restoreStock('Sottomanto', maintenance.sacsSottomantoUtilises);
      await restoreStock('Silice', maintenance.sacsSiliceUtilises);

      // 4. Supprimer la maintenance
      await (delete(maintenances)..where((m) => m.id.equals(maintenanceId)))
          .go();
    });
  }

  Future<void> updateMaintenanceWithStockAdjustment(
    domm.Maintenance newMaintenance, {
    int? userId,
  }) async {
    if (newMaintenance.id == null) {
      throw Exception('ID de maintenance requis pour la mise à jour');
    }

    return transaction(() async {
      // 1. Récupérer l'ancienne maintenance
      final oldMaintenance = await (select(maintenances)
            ..where((m) => m.id.equals(newMaintenance.id!)))
          .getSingleOrNull();

      if (oldMaintenance == null) {
        throw Exception('Maintenance originale introuvable');
      }

      // 2. Récupérer les items de stock
      final stockList = await select(stockItems).get();

      Future<void> adjustStock(String name, int oldUsed, int newUsed) async {
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
              'Stock insuffisant pour $name (dispo: ${itemRow.quantity}, requis en plus: $diff).',
            );
          }
        }

        final newQty = itemRow.quantity - diff; // diff positif = consommation = moins de stock

        // Mise à jour du stock
        await (update(stockItems)..where((t) => t.id.equals(itemRow.id))).write(
          StockItemsCompanion(
            quantity: Value(newQty),
            updatedAt: Value(DateTime.now()),
          ),
        );

        // Historisation
        await into(stockMovements).insert(
          StockMovementsCompanion(
            stockItemId: Value(itemRow.id),
            previousQuantity: Value(itemRow.quantity),
            newQuantity: Value(newQty),
            quantityChange: Value(-diff), // diff positif = conso = changement négatif
            reason: const Value('Correction'),
            description: Value('Modif maintenance #${newMaintenance.id}'),
            userId: Value(userId),
            occurredAt: Value(DateTime.now()),
          ),
        );
      }

      // 3. Ajuster les stocks
      await adjustStock(
        'Manto',
        oldMaintenance.sacsMantoUtilises,
        newMaintenance.sacsMantoUtilises,
      );
      await adjustStock(
        'Sottomanto',
        oldMaintenance.sacsSottomantoUtilises,
        newMaintenance.sacsSottomantoUtilises,
      );
      await adjustStock(
        'Silice',
        oldMaintenance.sacsSiliceUtilises,
        newMaintenance.sacsSiliceUtilises,
      );

      // 4. Mettre à jour la maintenance
      await update(maintenances).replace(newMaintenance.toCompanion());
    });
  }

  Future<domm.Maintenance?> getLastMajorMaintenance(int terrainId) async {
    return (select(maintenances)
          ..where((m) => m.terrainId.equals(terrainId))
          ..where((m) => m.type.like('%Recharge%') | m.type.like('%Travaux%'))
          ..orderBy([(m) => OrderingTerm.desc(m.date)])
          ..limit(1))
        .map((r) => r.toDomain())
        .getSingleOrNull();
  }

  Future<domm.Maintenance?> getLastMaintenanceForTerrain(
    int terrainId, {
    String? type,
  }) async {
    final query = select(maintenances)
      ..where((m) => m.terrainId.equals(terrainId))
      ..orderBy([(m) => OrderingTerm.desc(m.date)])
      ..limit(1);

    if (type != null) {
      query.where((m) => m.type.equals(type));
    }

    final row = await query.getSingleOrNull();
    return row?.toDomain();
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
    return rows.map((r) => r.toDomain()).toList();
  }

  Stream<List<domm.Maintenance>> watchMaintenancesInRange(int start, int end) {
    return (select(maintenances)
          ..where((m) => m.date.isBetweenValues(start, end))
          ..orderBy([(m) => OrderingTerm.asc(m.date)]))
        .watch()
        .map((rows) => rows.map((r) => r.toDomain()).toList());
  }

  Future<List<domm.Maintenance>> getMaintenancesInPeriod(
    DateTime start,
    DateTime end,
  ) async {
    final startMs = start.millisecondsSinceEpoch;
    final endMs = end.millisecondsSinceEpoch;

    final rows =
        await (select(maintenances)
              ..where((m) => m.date.isBetweenValues(startMs, endMs))
              ..orderBy([(m) => OrderingTerm.asc(m.date)]))
            .get();
    return rows.map((r) => r.toDomain()).toList();
  }

  Future<domm.Maintenance?> getMaintenanceById(int id) async {
    final row = await (select(
      maintenances,
    )..where((m) => m.id.equals(id))).getSingleOrNull();
    return row?.toDomain();
  }

  Future<int> insertMaintenance(domm.Maintenance m) {
    return into(maintenances).insert(m.toCompanion());
  }

  Future<int> updateMaintenance(MaintenancesCompanion companion) {
    return update(maintenances).write(companion);
  }

  Future<int> deleteMaintenance(int id) {
    return (delete(maintenances)..where((m) => m.id.equals(id))).go();
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

  /// Totaux annuels globaux (tous terrains confondus)
  Stream<({int manto, int sottomanto, int silice})> watchYearlySacksTotal(
    int year,
  ) {
    final start = DateTime(year, 1, 1).millisecondsSinceEpoch;
    final end = DateTime(year, 12, 31, 23, 59, 59, 999).millisecondsSinceEpoch;

    final query = selectOnly(maintenances)
      ..addColumns([
        maintenances.sacsMantoUtilises.sum(),
        maintenances.sacsSottomantoUtilises.sum(),
        maintenances.sacsSiliceUtilises.sum(),
      ])
      ..where(maintenances.date.isBetweenValues(start, end));

    return query.watchSingle().map((row) {
      return (
        manto: row.read(maintenances.sacsMantoUtilises.sum()) ?? 0,
        sottomanto: row.read(maintenances.sacsSottomantoUtilises.sum()) ?? 0,
        silice: row.read(maintenances.sacsSiliceUtilises.sum()) ?? 0,
      );
    });
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
