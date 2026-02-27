import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tenniscourtcare/data/database/app_database.dart';
import 'package:tenniscourtcare/data/mappers/terrain_mapper.dart';
import 'package:tenniscourtcare/data/mappers/stock_item_mapper.dart';
import 'package:tenniscourtcare/data/mappers/maintenance_mapper.dart';
import 'package:tenniscourtcare/data/services/firebase_event_service.dart';
import 'package:tenniscourtcare/data/services/firebase_maintenance_service.dart';
import 'package:tenniscourtcare/data/services/firebase_stock_service.dart';
import 'package:tenniscourtcare/data/services/firebase_terrain_service.dart';
import 'package:tenniscourtcare/domain/entities/sync_status.dart';

/// Service responsible for syncing local Drift database with Firebase.
/// Offline-first: uploads local changes, updates sync status to "synced".
class FirebaseSyncService {
  final AppDatabase _db;
  final FirebaseFirestore _firestore;

  late final FirebaseTerrainService _terrainService;
  late final FirebaseMaintenanceService _maintenanceService;
  late final FirebaseStockService _stockService;
  late final FirebaseEventService _eventService;

  /// Stream controller for sync status of each entity type
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

  /// Watch sync status changes
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

  /// Sync all entities with Firebase
  Future<void> syncAll() async {
    debugPrint('🔄 Starting full sync...');
    await Future.wait([
      syncTerrains(),
      syncMaintenances(),
      syncStock(),
      syncEvents(),
    ]);
    debugPrint('✅ Full sync complete');
  }

  /// ✅ Sync terrains with Firebase
  /// Uploads local terrains, then marks as synced
  Future<void> syncTerrains() async {
    _updateStatus('terrains', SyncStatus.syncing);
    try {
      final allTerrains = await _db.getAllTerrains();
      final unsynced = allTerrains
          .where((t) => t.syncStatus == SyncStatus.local)
          .toList();

      debugPrint('⏳ Syncing ${unsynced.length} terrains...');

      for (final terrain in unsynced) {
        // Upload to Firebase
        await _terrainService.uploadTerrainToFirestore(terrain);

        // ✅ Upsert: INSERT if new, UPDATE if exists
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
      debugPrint('✅ Terrains synced successfully');
    } catch (e, st) {
      debugPrint('❌ Sync Terrains Error: $e\n$st');
      _updateStatus('terrains', SyncStatus.error);
      rethrow;
    }
  }

  /// ✅ Sync maintenances with Firebase
  /// Uploads local maintenances, then marks as synced
  Future<void> syncMaintenances() async {
    _updateStatus('maintenances', SyncStatus.syncing);
    try {
      final allMaintenances = await _db.watchMaintenancesInRange(0, 9999999999)
          .first; // Get all maintenances

      final unsynced = allMaintenances
          .where((m) => m.syncStatus == SyncStatus.local)
          .toList();

      debugPrint('⏳ Syncing ${unsynced.length} maintenances...');

      for (final maintenance in unsynced) {
        // Upload to Firebase
        await _maintenanceService
            .uploadMaintenanceToFirestore(maintenance);

        // ✅ Upsert: INSERT if new, UPDATE if exists
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
      debugPrint('✅ Maintenances synced successfully');
    } catch (e, st) {
      debugPrint('❌ Sync Maintenances Error: $e\n$st');
      _updateStatus('maintenances', SyncStatus.error);
      rethrow;
    }
  }

  /// ✅ Sync stock items with Firebase
  /// Uploads local stock items, then marks as synced
  Future<void> syncStock() async {
    _updateStatus('stock', SyncStatus.syncing);
    try {
      final allStock = await _db.watchAllStockItems().first;
      final unsynced =
          allStock.where((s) => s.syncStatus == SyncStatus.local).toList();

      debugPrint('⏳ Syncing ${unsynced.length} stock items...');

      for (final item in unsynced) {
        // Upload to Firebase
        await _stockService.uploadStockItemToFirestore(item);

        // ✅ Upsert: INSERT if new, UPDATE if exists
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
      debugPrint('✅ Stock items synced successfully');
    } catch (e, st) {
      debugPrint('❌ Sync Stock Error: $e\n$st');
      _updateStatus('stock', SyncStatus.error);
      rethrow;
    }
  }

  /// ✅ Sync events with Firebase
  /// Uploads local events, then marks as synced
  Future<void> syncEvents() async {
    _updateStatus('events', SyncStatus.syncing);
    try {
      // Note: Events watchers use _db.watchAllEvents() if available,
      // otherwise use the stream watcher below as fallback
      final allEvents = await _db.watchAllEvents().first;
      final unsynced =
          allEvents.where((e) => e.syncStatus == SyncStatus.local).toList();

      debugPrint('⏳ Syncing ${unsynced.length} events...');

      for (final event in unsynced) {
        // Upload to Firebase
        await _eventService.uploadEventToFirestore(event);

        // ✅ Upsert: INSERT if new, UPDATE if exists
        await _db.into(_db.events).insert(
          event.toCompanion(),
          onConflict: drift.DoUpdate(
            (old) => EventsCompanion(
              syncStatus: drift.Value(SyncStatus.synced.name),
              updatedAt: drift.Value(DateTime.now()),
            ),
          ),
        );
      }
      _updateStatus('events', SyncStatus.synced);
      debugPrint('✅ Events synced successfully');
    } catch (e, st) {
      debugPrint('❌ Sync Events Error: $e\n$st');
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