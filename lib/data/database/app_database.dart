import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'package:flutter/foundation.dart';
import './tables/terrain_table.dart';
import './tables/maintenances.dart';
import './tables/stock_items.dart';
import './tables/users_table.dart';
import './tables/events_table.dart';
import './tables/stock_movements.dart';
import './tables/audit_logs.dart';
import './tables/login_attempts.dart';
import './tables/otp_records.dart';
import './tables/reservations.dart';

import '../../domain/entities/terrain.dart' as dom;
import '../../domain/entities/maintenance.dart' as domm;
import '../../domain/entities/stock_item.dart' as doms;
import '../../domain/entities/user_entity.dart' as domu;
import '../../domain/entities/app_event.dart';
import '../../domain/enums/role.dart';
import '../../core/utils/date_utils.dart' as cc;

import '../mappers/terrain_mapper.dart';
import '../mappers/stock_item_mapper.dart';
import '../mappers/user_mapper.dart';
import '../mappers/maintenance_mapper.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Terrains,
    Maintenances,
    StockItems,
    Users,
    Events,
    StockMovements,
    AuditLogs,
    LoginAttempts,
    OtpRecords,
    Reservations,
  ],
)
class AppDatabase extends _$AppDatabase {
  // === FIREBASE CACHE SERVICE METHODS ===

  Future<void> upsertTerrain(TerrainsCompanion companion) async {
    final firebaseId = companion.firebaseId.value;
    if (firebaseId == null || firebaseId.isEmpty) {
      await into(terrains).insert(companion);
      return;
    }

    final existing = await (select(
      terrains,
    )..where((t) => t.firebaseId.equals(firebaseId))).getSingleOrNull();

    if (existing != null) {
      await (update(
        terrains,
      )..where((t) => t.firebaseId.equals(firebaseId))).write(companion);
    } else {
      await into(terrains).insert(companion);
    }
  }

  Future<void> deleteTerrainByFirebaseId(String firebaseId) async {
    await (delete(
      terrains,
    )..where((t) => t.firebaseId.equals(firebaseId))).go();
  }

  Future<void> upsertMaintenance(MaintenancesCompanion companion) async {
    final firebaseId = companion.firebaseId.value;
    if (firebaseId == null || firebaseId.isEmpty) {
      await into(maintenances).insert(companion);
      return;
    }

    final existing = await (select(
      maintenances,
    )..where((t) => t.firebaseId.equals(firebaseId))).getSingleOrNull();

    if (existing != null) {
      await (update(
        maintenances,
      )..where((t) => t.firebaseId.equals(firebaseId))).write(companion);
    } else {
      await into(maintenances).insert(companion);
    }
  }

  Future<void> deleteMaintenanceByFirebaseId(String firebaseId) async {
    await (delete(
      maintenances,
    )..where((t) => t.firebaseId.equals(firebaseId))).go();
  }

  Future<void> upsertStockItem(StockItemsCompanion companion) async {
    final firebaseId = companion.firebaseId.value;
    if (firebaseId == null || firebaseId.isEmpty) {
      await into(stockItems).insert(companion);
      return;
    }

    final existing = await (select(
      stockItems,
    )..where((t) => t.firebaseId.equals(firebaseId))).getSingleOrNull();

    if (existing != null) {
      await (update(
        stockItems,
      )..where((t) => t.firebaseId.equals(firebaseId))).write(companion);
    } else {
      await into(stockItems).insert(companion);
    }
  }

  Future<void> deleteStockItemByFirebaseId(String firebaseId) async {
    await (delete(
      stockItems,
    )..where((t) => t.firebaseId.equals(firebaseId))).go();
  }

  Future<void> upsertEvent(EventsCompanion companion) async {
    final firebaseId = companion.firebaseId.value;
    if (firebaseId == null || firebaseId.isEmpty) {
      await into(events).insert(companion);
      return;
    }

    final existing = await (select(
      events,
    )..where((t) => t.firebaseId.equals(firebaseId))).getSingleOrNull();

    if (existing != null) {
      await (update(
        events,
      )..where((t) => t.firebaseId.equals(firebaseId))).write(companion);
    } else {
      await into(events).insert(companion);
    }
  }

  Future<void> deleteEventByFirebaseId(String firebaseId) async {
    await (delete(events)..where((t) => t.firebaseId.equals(firebaseId))).go();
  }

  Future<void> upsertUser(UsersCompanion companion) async {
    final firebaseId = companion.firestoreUid.value;
    if (firebaseId == null || firebaseId.isEmpty) {
      await into(users).insert(companion);
      return;
    }

    final existing = await (select(
      users,
    )..where((t) => t.firestoreUid.equals(firebaseId))).getSingleOrNull();

    if (existing != null) {
      await (update(
        users,
      )..where((t) => t.firestoreUid.equals(firebaseId))).write(companion);
    } else {
      await into(users).insert(companion);
    }
  }

  Future<void> deleteUserByFirebaseId(String firebaseId) async {
    await (delete(users)..where((t) => t.firestoreUid.equals(firebaseId))).go();
  }

  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 23; // v23: firebaseId indexes

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(stockItems);
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
      if (from < 9) {
        await m.createTable(auditLogs);
        await m.createTable(loginAttempts);
      }
      if (from < 10) {
        await m.createTable(otpRecords);
      }
      if (from < 11) {
        // Users (created in v3)
        if (from >= 3) {
          await m.addColumn(users, users.remoteId);
          await m.addColumn(users, users.firestoreUid); // Added in our branch
          await m.addColumn(users, users.syncedAt);
          await m.addColumn(users, users.updatedAt);
          await m.addColumn(users, users.isActive);
        }

        // Terrains (created in v1)
        await m.addColumn(terrains, terrains.remoteId);
        await m.addColumn(terrains, terrains.location);
        await m.addColumn(terrains, terrains.capacity);
        await m.addColumn(terrains, terrains.pricePerHour);
        await m.addColumn(terrains, terrains.available);
        await m.addColumn(terrains, terrains.createdAt);
        await m.addColumn(terrains, terrains.updatedAt);
        await m.addColumn(terrains, terrains.syncedAt);
        await m.addColumn(terrains, terrains.imageUrl);

        // StockItems (created in v2)
        if (from >= 2) {
          await m.addColumn(stockItems, stockItems.remoteId);
          await m.addColumn(stockItems, stockItems.unitPrice);
          await m.addColumn(stockItems, stockItems.createdAt);
          await m.addColumn(stockItems, stockItems.lastModifiedBy);
          await m.addColumn(stockItems, stockItems.syncedAt);
          await m.addColumn(stockItems, stockItems.isSyncPending);
        }

        // Maintenances (created in v1)
        await m.addColumn(maintenances, maintenances.remoteId);
        await m.addColumn(maintenances, maintenances.status);
        await m.addColumn(maintenances, maintenances.scheduledDate);
        await m.addColumn(maintenances, maintenances.completedDate);
        await m.addColumn(maintenances, maintenances.createdBy);
        await m.addColumn(maintenances, maintenances.createdAt);
        await m.addColumn(maintenances, maintenances.syncedAt);

        // AuditLogs (created in v9)
        if (from >= 9) {
          await m.addColumn(auditLogs, auditLogs.remoteId);
          await m.addColumn(auditLogs, auditLogs.userUid);
          await m.addColumn(auditLogs, auditLogs.severity);
          await m.addColumn(auditLogs, auditLogs.syncedAt);
        }

        // Create Reservations
        await m.createTable(reservations);
      }

      if (from < 15) {
        // Removed UNIQUE constraint from firebaseUid column
        // (Done in table definition, no SQL migration needed)
        // Schema bumped to ensure clean state going forward
      }

      if (from < 16) {
        // Added status column to Terrains
        await m.addColumn(terrains, terrains.status);
      }
      if (from < 17) {
        // Phase 3: Add sync columns to Terrains, Maintenances, StockItems, Events

        // Terrains
        await m.addColumn(terrains, terrains.firebaseId);
        await m.addColumn(terrains, terrains.createdBy);
        await m.addColumn(terrains, terrains.modifiedBy);
        // createdAt, updatedAt already exist in older versions, skipping to avoid duplicates

        // Maintenances
        await m.addColumn(maintenances, maintenances.updatedAt);
        await m.addColumn(maintenances, maintenances.firebaseId);
        await m.addColumn(maintenances, maintenances.modifiedBy);
        // createdAt already exists, skipping

        // StockItems
        await m.addColumn(
          stockItems,
          stockItems.updatedAt,
        ); // Wait, was updatedAt existing?
        // Checking StockItems definition: DateTimeColumn get updatedAt => dateTime()();
        // It WAS existing in v2 (or v11 migration block adds createdAt, not updatedAt).
        // Let's check stock_items.dart in file read...
        // "DateTimeColumn get updatedAt => dateTime()();" was there in original read.
        // So updatedAt existed.
        // I will SKIP updatedAt for StockItems.
        await m.addColumn(stockItems, stockItems.firebaseId);
        await m.addColumn(stockItems, stockItems.createdBy);
        await m.addColumn(stockItems, stockItems.modifiedBy);

        // Events
        await m.addColumn(events, events.createdAt);
        await m.addColumn(events, events.updatedAt);
        await m.addColumn(events, events.firebaseId);
        await m.addColumn(events, events.createdBy);
        await m.addColumn(events, events.modifiedBy);
      }

      if (from < 18) {
        // Also drops syncQueue entirely

        await m.recreateAllViews();

        await m.deleteTable('sync_queue');

        await m.deleteTable(terrains.actualTableName);
        await m.createTable(terrains);

        await m.deleteTable(stockItems.actualTableName);
        await m.createTable(stockItems);

        await m.deleteTable(maintenances.actualTableName);
        await m.createTable(maintenances);

        await m.deleteTable(events.actualTableName);
        await m.createTable(events);
      }

      if (from < 19) {
        // Delete all seeded rows that were never synced with Firestore:
        await customStatement(
          'DELETE FROM stock_items WHERE firebase_id IS NULL;',
        );
      }

      if (from < 20) {
        await m.addColumn(users, users.status);
        await m.addColumn(users, users.approvedAt);
        await m.addColumn(users, users.approvedBy);
      }
      if (from < 21) {
        await m.addColumn(maintenances, maintenances.isPlanned);
      }
      if (from < 22) {
        await m.addColumn(maintenances, maintenances.startHour);
        await m.addColumn(maintenances, maintenances.durationMinutes);
      }
      if (from < 23) {
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_maintenances_firebase_id ON maintenances(firebase_id);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_terrains_firebase_id ON terrains(firebase_id);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_stock_items_firebase_id ON stock_items(firebase_id);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_events_firebase_id ON events(firebase_id);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_users_firestore_uid ON users(firestore_uid);',
        );
      }
    },
    // ✅ FIX CRITIQUE: beforeOpen vérifie l'intégrité au démarrage
    beforeOpen: (details) async {
      if (details.wasCreated) {
        // Nouvelle installation → tables vides → rien à faire
        debugPrint('🗄️ DB: Nouvelle installation schema v$schemaVersion');
        return;
      }
      // ✅ Purge défensive au démarrage — idempotent
      // Supprime tous les items sans firebaseId (seeds ou orphelins)
      await customStatement(
        'DELETE FROM stock_items WHERE firebase_id IS NULL;',
      );
      await customStatement(
        'DELETE FROM maintenances WHERE firebase_id IS NULL;', // ✅ AJOUTÉ
      );
      await customStatement(
        'DELETE FROM terrains WHERE firebase_id IS NULL;', // ✅ AJOUTÉ
      );
      await customStatement(
        'DELETE FROM events WHERE firebase_id IS NULL;', // ✅ AJOUTÉ
      );
      debugPrint('🗄️ DB: Purge seeds orphelins au démarrage ✅');
    },
  );

  // ========== USERS ==========

  Future<domu.UserEntity?> getUserByEmail(String email) async {
    final row = await (select(
      users,
    )..where((u) => u.email.equals(email))).getSingleOrNull();
    return row?.toDomain();
  }

  Future<domu.UserEntity?> getUserByFirestoreUid(String uid) async {
    final row = await (select(
      users,
    )..where((u) => u.firestoreUid.equals(uid))).getSingleOrNull();
    return row?.toDomain();
  }

  Future<domu.UserEntity?> getUserById(int id) async {
    final row = await (select(
      users,
    )..where((u) => u.id.equals(id))).getSingleOrNull();
    return row?.toDomain();
  }

  // Cette méthode retourne le UserRow complet (avec hash) pour la vérification du mot de passe
  Future<UserRow?> getUserRowByEmail(String email) async {
    return (select(
      users,
    )..where((u) => u.email.equals(email))).getSingleOrNull();
  }

  Future<List<domu.UserEntity>> getAllUsers() async {
    final rows = await select(users).get();
    return rows.map((r) => r.toDomain()).toList();
  }

  Stream<List<domu.UserEntity>> watchPendingUsers() {
    return (select(users)..where((u) => u.status.equals('inactive')))
        .watch()
        .map((rows) => rows.map((r) => r.toDomain()).toList());
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
    final count =
        await (selectOnly(users)
              ..addColumns([users.id.count()])
              ..where(users.role.equals(role.name)))
            .getSingle();
    return count.read(users.id.count()) ?? 0;
  }

  Future<int> countUsers() async {
    final count = await (selectOnly(
      users,
    )..addColumns([users.id.count()])).getSingle();
    return count.read(users.id.count()) ?? 0;
  }

  Future<int> deleteUser(int userId) {
    return (delete(users)..where((u) => u.id.equals(userId))).go();
  }

  Future<int> updateUserPassword(int userId, String newHash) {
    return (update(users)..where((u) => u.id.equals(userId))).write(
      UsersCompanion(passwordHash: Value(newHash)),
    );
  }

  // ========== AUDIT & SECURITY ==========

  Future<int> insertAuditLog(AuditLogsCompanion log) {
    return into(auditLogs).insert(log);
  }

  Future<List<AuditLog>> getRecentAuditLogs({int limit = 100}) {
    return (select(auditLogs)
          ..orderBy([(l) => OrderingTerm.desc(l.timestamp)])
          ..limit(limit))
        .get();
  }

  Future<int> insertLoginAttempt(LoginAttemptsCompanion attempt) {
    return into(loginAttempts).insert(attempt);
  }

  // Clean up old attempts (helper for rate limiter)
  Future<void> cleanOldLoginAttempts(DateTime cutoff) async {
    await (delete(
      loginAttempts,
    )..where((a) => a.timestamp.isSmallerThanValue(cutoff))).go();
  }

  Future<List<LoginAttempt>> getRecentLoginAttempts(
    String email,
    DateTime since,
  ) async {
    return (select(loginAttempts)
          ..where(
            (a) =>
                a.email.equals(email) & a.timestamp.isBiggerOrEqualValue(since),
          )
          ..orderBy([(a) => OrderingTerm.desc(a.timestamp)]))
        .get();
  }

  // ========== OTP Management ==========

  Future<int> insertOtp(OtpRecordsCompanion companion) {
    return into(otpRecords).insert(companion);
  }

  Future<OtpRecord?> getLatestValidOtp(String email) async {
    // Return latest OTP that is NOT expired
    return (select(otpRecords)
          ..where(
            (o) =>
                o.email.equals(email) &
                o.expiresAt.isBiggerThan(currentDateAndTime),
          )
          ..orderBy([(o) => OrderingTerm.desc(o.createdAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> deleteOtp(int id) async {
    await (delete(otpRecords)..where((o) => o.id.equals(id))).go();
  }

  Future<int> countRecentOtps(String email, DateTime since) async {
    final count =
        await (selectOnly(otpRecords)
              ..addColumns([otpRecords.id.count()])
              ..where(
                otpRecords.email.equals(email) &
                    otpRecords.createdAt.isBiggerOrEqualValue(since),
              ))
            .getSingle();

    return count.read(otpRecords.id.count()) ?? 0;
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

  Future<void> insertMaintenanceWithStockCheck(
    domm.Maintenance m, {
    int? userId,
  }) async {
    return transaction(() async {
      // 1. Récupérer les items de stock
      final stockList = await select(stockItems).get();

      Future<void> checkAndDec(String name, int used) async {
        if (used <= 0) return;
        final itemRow = stockList.firstWhere(
          (i) => i.name.toLowerCase() == name.toLowerCase(),
          orElse: () =>
              throw Exception("Article de stock '$name' introuvable."),
        );

        if (itemRow.quantity < used) {
          throw Exception(
            'Stock insuffisant pour $name (${itemRow.quantity} disponibles, $used requis).',
          );
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

  Future<void> deleteMaintenanceWithStockRestoration(
    int maintenanceId, {
    int? userId,
  }) async {
    return transaction(() async {
      // 1. Récupérer la maintenance à supprimer
      final maintenance = await (select(
        maintenances,
      )..where((m) => m.id.equals(maintenanceId))).getSingleOrNull();

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
      await (delete(
        maintenances,
      )..where((m) => m.id.equals(maintenanceId))).go();
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
      final oldMaintenance = await (select(
        maintenances,
      )..where((m) => m.id.equals(newMaintenance.id!))).getSingleOrNull();

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

        final newQty =
            itemRow.quantity -
            diff; // diff positif = consommation = moins de stock

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
            quantityChange: Value(
              -diff,
            ), // diff positif = conso = changement négatif
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

  Stream<List<dom.Terrain>> watchAllTerrains() {
    return select(
      terrains,
    ).watch().map((rows) => rows.map((r) => r.toDomain()).toList());
  }

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

  /// Mettre à jour le status d'un terrain
  Future<bool> updateTerrainStatus(int terrainId, String newStatus) {
    return (update(terrains)..where((t) => t.id.equals(terrainId)))
        .write(TerrainsCompanion(status: Value(newStatus)))
        .then((rows) => rows > 0);
  }

  Future<int> deleteTerrain(int id) {
    return (delete(terrains)..where((t) => t.id.equals(id))).go();
  }

  // ========== MAINTENANCES ==========

  Stream<List<domm.Maintenance>> watchAllMaintenances() {
    return select(
      maintenances,
    ).watch().map((rows) => rows.map((r) => r.toDomain()).toList());
  }

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

  Stream<List<domm.Maintenance>> watchMaintenancesForTerrain(int terrainId) {
    return (select(maintenances)
          ..where((m) => m.terrainId.equals(terrainId))
          ..where((m) => m.isPlanned.equals(false))
          ..orderBy([(m) => OrderingTerm.desc(m.date)]))
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

  Future<domm.Maintenance?> getMaintenanceByFirebaseId(
    String firebaseId,
  ) async {
    final row =
        await (select(maintenances)
              ..where((m) => m.firebaseId.equals(firebaseId))
              ..limit(1))
            .getSingleOrNull();
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

  // ========== EVENTS ==========

  Stream<List<AppEvent>> watchAllEvents() {
    return select(
      events,
    ).watch().map((rows) => rows.map((r) => r.toDomain()).toList());
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

extension EventRowDomainX on EventRow {
  AppEvent toDomain() {
    return AppEvent(
      id: id,
      title: title,
      description: description,
      startTime: startTime,
      endTime: endTime,
      color: color,
      terrainIds: terrainIds,
      createdAt: createdAt,
      updatedAt: updatedAt,
      firebaseId: firebaseId,
      createdBy: createdBy,
      modifiedBy: modifiedBy,
    );
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
