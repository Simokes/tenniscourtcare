import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tenniscourtcare/data/database/app_database.dart';
import 'package:tenniscourtcare/data/mappers/maintenance_mapper.dart';
import 'package:tenniscourtcare/data/mappers/stock_item_mapper.dart';
import 'package:tenniscourtcare/data/mappers/terrain_mapper.dart';
import 'package:tenniscourtcare/data/mappers/event_mapper.dart';
import 'package:tenniscourtcare/data/models/terrain_model.dart';
import 'package:tenniscourtcare/data/models/maintenance_model.dart';
import 'package:tenniscourtcare/data/models/stock_item_model.dart';
import 'package:tenniscourtcare/data/models/app_event_model.dart';
import 'package:tenniscourtcare/data/services/firebase_event_service.dart';
import 'package:tenniscourtcare/data/services/firebase_maintenance_service.dart';
import 'package:tenniscourtcare/data/services/firebase_stock_service.dart';
import 'package:tenniscourtcare/data/services/firebase_terrain_service.dart';
import 'package:tenniscourtcare/domain/entities/sync_status.dart';

/// Service responsible for syncing local Drift database with Firebase.
/// Implements offline-first: writes to Drift first, then syncs to Firestore.
///
/// Sync flow:
/// 1. User mutation → Write to Drift (optimistic)
/// 2. Check network → If online, push to Firebase
/// 3. Firebase success → Update sync_status to "synced"
/// 4. Firebase failure → Keep sync_status as "local" (retry on network restore)
class FirebaseSyncService {
  final AppDatabase _db;
  final FirebaseFirestore _firestore;

  late final FirebaseTerrainService _terrainService;
  late final FirebaseMaintenanceService _maintenanceService;
  late final FirebaseStockService _stockService;
  late final FirebaseEventService _eventService;

  /// Stream controller for real-time sync status updates
  /// Maps entity type → current SyncStatus
  final BehaviorSubject<Map<String, SyncStatus>> _syncStatusController =
      BehaviorSubject.seeded({
    'terrains': SyncStatus.local,
    'maintenances': SyncStatus.local,
    'stock': SyncStatus.local,
    'events': SyncStatus.local,
  });

  FirebaseSyncService(this._firestore, this._db) {
    _terrainService = FirebaseTerrainService(_firestore);
    _maintenanceService = FirebaseMaintenanceService(_firestore);
    _stockService = FirebaseStockService(_firestore);
    _eventService = FirebaseEventService(_firestore);
  }

  /// Watch sync status changes for all entities
  ///
  /// Usage:
  /// ```dart
  /// final syncStatus = ref.watch(syncStatusProvider);
  /// syncStatus.when(
  ///   data: (status) => SyncStatusBanner(status: status),
  ///   loading: () => SizedBox.shrink(),
  ///   error: (e, st) => SizedBox.shrink(),
  /// );
  /// ```
  Stream<Map<String, SyncStatus>> watchSyncStatus() =>
      _syncStatusController.stream;

  /// Get current sync status for specific entity type
  SyncStatus getSyncStatus(String key) =>
      _syncStatusController.value[key] ?? SyncStatus.local;

  /// Update sync status for specific entity type
  void _updateStatus(String key, SyncStatus status) {
    final current = Map<String, SyncStatus>.from(_syncStatusController.value);
    current[key] = status;
    _syncStatusController.add(current);
  }

  // ============================================================================
  // PULL METHODS (NEW) - Sync from Firestore to local Drift DB
  // ============================================================================

  /// Pull terrains from Firestore and save to local Drift DB
  Future<void> _pullTerrains() async {
    try {
      debugPrint('⬇️ FirebaseSync: Pulling terrains from Firestore...');

      final snapshot = await _firestore.collection('terrains').get();

      for (final doc in snapshot.docs) {
        try {
          final model = TerrainModel.fromFirestore(doc);

          // Find local record by firebaseId
          final localRow = await (_db.select(_db.terrains)..where((t) => t.firebaseId.equals(doc.id))).getSingleOrNull();

          if (localRow != null) {
            // Update existing if not local-only changes
            if (localRow.syncStatus != SyncStatus.local.name) {
               // Cloud wins
               final companion = model.toDomain().toCompanion(includeId: true).copyWith(
                 id: drift.Value(localRow.id), // Bind local ID
                 syncStatus: drift.Value(SyncStatus.synced.name),
               );
               await _db.update(_db.terrains).replace(companion);
            }
          } else {
            // Insert new
            final companion = model.toDomain().toCompanion(includeId: false).copyWith(
               syncStatus: drift.Value(SyncStatus.synced.name),
               remoteId: drift.Value(doc.id),
               firebaseId: drift.Value(doc.id),
            );
            await _db.into(_db.terrains).insert(companion);
          }
        } catch (e) {
          debugPrint('❌ Failed to save terrain ${doc.id}: $e');
        }
      }
      debugPrint('✅ FirebaseSync: Terrains pulled (${snapshot.docs.length})');
    } catch (e, st) {
      debugPrint('❌ _pullTerrains error: $e\n$st');
      rethrow;
    }
  }

  /// Pull maintenances from Firestore and save to local Drift DB
  Future<void> _pullMaintenances() async {
    try {
      debugPrint('⬇️ FirebaseSync: Pulling maintenances from Firestore...');

      final snapshot = await _firestore.collection('maintenance').get();

      for (final doc in snapshot.docs) {
        try {
          final model = MaintenanceModel.fromFirestore(doc);

          final localRow = await (_db.select(_db.maintenances)..where((t) => t.firebaseId.equals(doc.id))).getSingleOrNull();

          if (localRow != null) {
            if (localRow.syncStatus != SyncStatus.local.name) {
               final companion = model.toDomain().toCompanion().copyWith(
                 id: drift.Value(localRow.id),
                 syncStatus: drift.Value(SyncStatus.synced.name),
               );
               await _db.update(_db.maintenances).replace(companion);
            }
          } else {
            final companion = model.toDomain().toCompanion().copyWith(
               id: const drift.Value.absent(), // Force auto-increment (model has id=0)
               syncStatus: drift.Value(SyncStatus.synced.name),
               remoteId: drift.Value(doc.id),
               firebaseId: drift.Value(doc.id),
            );
            await _db.into(_db.maintenances).insert(companion);
          }
        } catch (e) {
          debugPrint('❌ Failed to save maintenance ${doc.id}: $e');
        }
      }
      debugPrint('✅ FirebaseSync: Maintenances pulled (${snapshot.docs.length})');
    } catch (e, st) {
      debugPrint('❌ _pullMaintenances error: $e\n$st');
      rethrow;
    }
  }

  /// Pull stock items from Firestore and save to local Drift DB
  Future<void> _pullStock() async {
    try {
      debugPrint('⬇️ FirebaseSync: Pulling stock from Firestore...');

      final snapshot = await _firestore.collection('stock').get();

      for (final doc in snapshot.docs) {
        try {
          final model = StockItemModel.fromFirestore(doc);

          final localRow = await (_db.select(_db.stockItems)..where((t) => t.firebaseId.equals(doc.id))).getSingleOrNull();

          if (localRow != null) {
            if (localRow.syncStatus != SyncStatus.local.name) {
               final companion = model.toDomain().toCompanion().copyWith(
                 id: drift.Value(localRow.id),
                 syncStatus: drift.Value(SyncStatus.synced.name),
               );
               await _db.update(_db.stockItems).replace(companion);
            }
          } else {
            final companion = model.toDomain().toCompanion().copyWith(
               id: const drift.Value.absent(), // Force auto-increment
               syncStatus: drift.Value(SyncStatus.synced.name),
               remoteId: drift.Value(doc.id),
               firebaseId: drift.Value(doc.id),
            );
            await _db.into(_db.stockItems).insert(companion);
          }
        } catch (e) {
          debugPrint('❌ Failed to save stock ${doc.id}: $e');
        }
      }
      debugPrint('✅ FirebaseSync: Stock pulled (${snapshot.docs.length})');
    } catch (e, st) {
      debugPrint('❌ _pullStock error: $e\n$st');
      rethrow;
    }
  }

  /// Pull events from Firestore and save to local Drift DB
  Future<void> _pullEvents() async {
    try {
      debugPrint('⬇️ FirebaseSync: Pulling events from Firestore...');

      final snapshot = await _firestore.collection('events').get();

      for (final doc in snapshot.docs) {
        try {
          final model = AppEventModel.fromFirestore(doc);

          final localRow = await (_db.select(_db.events)..where((t) => t.firebaseId.equals(doc.id))).getSingleOrNull();

          if (localRow != null) {
            if (localRow.syncStatus != SyncStatus.local.name) {
               final companion = model.toDomain().toCompanion(includeId: true).copyWith(
                 id: drift.Value(localRow.id),
                 syncStatus: drift.Value(SyncStatus.synced.name),
               );
               await _db.update(_db.events).replace(companion);
            }
          } else {
            final companion = model.toDomain().toCompanion(includeId: false).copyWith(
               syncStatus: drift.Value(SyncStatus.synced.name),
               firebaseId: drift.Value(doc.id),
            );
            await _db.into(_db.events).insert(companion);
          }
        } catch (e) {
          debugPrint('❌ Failed to save event ${doc.id}: $e');
        }
      }
      debugPrint('✅ FirebaseSync: Events pulled (${snapshot.docs.length})');
    } catch (e, st) {
      debugPrint('❌ _pullEvents error: $e\n$st');
      rethrow;
    }
  }

  /// Sync all entities with Firebase
  ///
  /// Called when:
  /// - Network connectivity restored
  /// - User manually triggers sync
  /// - App startup (if network available)
  Future<void> syncAll() async {
    try {
      debugPrint('🔄 FirebaseSyncService: Starting full bidirectional sync...');

      // STEP 1: PULL from Firestore to Drift (Cloud Wins)
      debugPrint('📥 FirebaseSyncService: Phase 1 - Pulling from Firestore...');
      await Future.wait([
        _pullTerrains(),
        _pullMaintenances(),
        _pullStock(),
        _pullEvents(),
      ]);
      debugPrint('✅ FirebaseSyncService: Pull complete');

      // STEP 2: PUSH from Drift to Firestore (local changes)
      debugPrint('📤 FirebaseSyncService: Phase 2 - Pushing to Firestore...');
      await Future.wait([
        syncTerrains(),
        syncMaintenances(),
        syncStock(),
        syncEvents(),
      ]);
      debugPrint('✅ FirebaseSyncService: Push complete');

      debugPrint('✅ FirebaseSyncService: Full sync complete');
    } catch (e, st) {
      debugPrint('❌ FirebaseSyncService.syncAll error: $e\n$st');
      rethrow;
    }
  }

  /// ✅ Sync terrains: Upload local changes to Firebase
  ///
  /// Flow:
  /// 1. Get all local terrains with sync_status == "local"
  /// 2. For each unsynced terrain:
  ///    a. Upload to Firebase
  ///    b. Update local record: sync_status = "synced"
  /// 3. Update stream status
  ///
  /// Errors:
  /// - Firebase upload failure → Keeps sync_status as "local" (retried on next sync)
  /// - Database error → Propagates to caller via rethrow
  Future<void> syncTerrains() async {
    _updateStatus('terrains', SyncStatus.syncing);
    try {
      final allTerrains = await _db.getAllTerrains();
      final unsynced = allTerrains
          .where((t) => t.syncStatus == SyncStatus.local)
          .toList();

      debugPrint(
          '⏳ FirebaseSyncService: Syncing ${unsynced.length} terrains...');

      for (final terrain in unsynced) {
        // Upload to Firebase
        await _terrainService.uploadTerrainToFirestore(terrain);

        // ✅ Upsert to Drift: INSERT if new, UPDATE if exists
        // This fixes UNIQUE constraint error by using onConflict
        await _db.into(_db.terrains).insert(
          terrain.toCompanion(includeId: true),
          onConflict: drift.DoUpdate(
            (old) => TerrainsCompanion(
              syncStatus: drift.Value(SyncStatus.synced.name),
              updatedAt: drift.Value(DateTime.now()),
            ),
          ),
        );
      }
      _updateStatus('terrains', SyncStatus.synced);
      debugPrint('✅ FirebaseSyncService: Terrains synced successfully');
    } catch (e, st) {
      debugPrint('❌ FirebaseSyncService: Sync Terrains Error: $e\n$st');
      _updateStatus('terrains', SyncStatus.error);
      rethrow;
    }
  }

  /// ✅ Sync maintenances: Upload local changes to Firebase
  ///
  /// Note: watchMaintenancesInRange(0, 9999999999) gets ALL maintenances
  /// (No better method available in current AppDatabase)
  Future<void> syncMaintenances() async {
    _updateStatus('maintenances', SyncStatus.syncing);
    try {
      // Get all maintenances from Drift
      final allMaintenances = await _db.watchMaintenancesInRange(0, 9999999999)
          .first; // Convert Stream to single Future

      final unsynced = allMaintenances
          .where((m) => m.syncStatus == SyncStatus.local)
          .toList();

      debugPrint(
          '⏳ FirebaseSyncService: Syncing ${unsynced.length} maintenances...');

      for (final maintenance in unsynced) {
        // Upload to Firebase
        await _maintenanceService
            .uploadMaintenanceToFirestore(maintenance);

        // ✅ Upsert to Drift: INSERT if new, UPDATE if exists
        await _db.into(_db.maintenances).insert(
          maintenance.toCompanion(),
          onConflict: drift.DoUpdate(
            (old) => MaintenancesCompanion(
              syncStatus: drift.Value(SyncStatus.synced.name),
              updatedAt: drift.Value(DateTime.now()),
            ),
          ),
        );
      }
      _updateStatus('maintenances', SyncStatus.synced);
      debugPrint('✅ FirebaseSyncService: Maintenances synced successfully');
    } catch (e, st) {
      debugPrint('❌ FirebaseSyncService: Sync Maintenances Error: $e\n$st');
      _updateStatus('maintenances', SyncStatus.error);
      rethrow;
    }
  }

  /// ✅ Sync stock items: Upload local changes to Firebase
  Future<void> syncStock() async {
    _updateStatus('stock', SyncStatus.syncing);
    try {
      final allStock = await _db.watchAllStockItems().first;
      final unsynced =
          allStock.where((s) => s.syncStatus == SyncStatus.local).toList();

      debugPrint(
          '⏳ FirebaseSyncService: Syncing ${unsynced.length} stock items...');

      for (final item in unsynced) {
        // Upload to Firebase
        await _stockService.uploadStockItemToFirestore(item);

        // ✅ Upsert to Drift: INSERT if new, UPDATE if exists
        await _db.into(_db.stockItems).insert(
          item.toCompanion(),
          onConflict: drift.DoUpdate(
            (old) => StockItemsCompanion(
              syncStatus: drift.Value(SyncStatus.synced.name),
              updatedAt: drift.Value(DateTime.now()),
            ),
          ),
        );
      }
      _updateStatus('stock', SyncStatus.synced);
      debugPrint('✅ FirebaseSyncService: Stock items synced successfully');
    } catch (e, st) {
      debugPrint('❌ FirebaseSyncService: Sync Stock Error: $e\n$st');
      _updateStatus('stock', SyncStatus.error);
      rethrow;
    }
  }

  /// ✅ Sync events: Upload local changes to Firebase
  Future<void> syncEvents() async {
    _updateStatus('events', SyncStatus.syncing);
    try {
      final allEvents = await _db.watchAllEvents().first;
      final unsynced =
          allEvents.where((e) => e.syncStatus == SyncStatus.local).toList();

      debugPrint(
          '⏳ FirebaseSyncService: Syncing ${unsynced.length} events...');

      for (final event in unsynced) {
        // Upload to Firebase
        await _eventService.uploadEventToFirestore(event);

        // ✅ Upsert to Drift: INSERT if new, UPDATE if exists
        await _db.into(_db.events).insert(
          event.toCompanion(includeId: true),
          onConflict: drift.DoUpdate(
            (old) => EventsCompanion(
              syncStatus: drift.Value(SyncStatus.synced.name),
              updatedAt: drift.Value(DateTime.now()),
            ),
          ),
        );
      }
      _updateStatus('events', SyncStatus.synced);
      debugPrint('✅ FirebaseSyncService: Events synced successfully');
    } catch (e, st) {
      debugPrint('❌ FirebaseSyncService: Sync Events Error: $e\n$st');
      _updateStatus('events', SyncStatus.error);
      rethrow;
    }
  }

  /// Dispose resources
  void dispose() {
    _syncStatusController.close();
  }

  // Public service accessors
  FirebaseTerrainService get terrainService => _terrainService;
  FirebaseMaintenanceService get maintenanceService => _maintenanceService;
  FirebaseStockService get stockService => _stockService;
  FirebaseEventService get eventService => _eventService;
}
