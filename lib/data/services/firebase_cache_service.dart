import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:tenniscourtcare/data/database/app_database.dart';
import 'package:tenniscourtcare/data/mappers/event_mapper.dart';
import 'package:tenniscourtcare/data/mappers/maintenance_mapper.dart';
import 'package:tenniscourtcare/data/mappers/stock_item_mapper.dart';
import 'package:tenniscourtcare/data/mappers/terrain_mapper.dart';

/// Listens to Firestore collections and keeps Drift cache in sync.
/// This is the ONLY component authorized to write into Drift.
/// Start on login via [startListening], stop on logout via [stopListening].
class FirebaseCacheService {
  FirebaseCacheService(this._db, this._fs);

  final AppDatabase _db;
  final FirebaseFirestore _fs;
  final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
      _subscriptions = [];

  bool get isListening => _subscriptions.isNotEmpty;

  /// Start all Firestore → Drift listeners.
  /// Call after successful authentication.
  void startListening() {
    if (isListening) {
      debugPrint('⚠️ CacheService: Already listening, skipping');
      return;
    }
    _subscriptions.addAll([
      _listenStock(),
      _listenTerrains(),
      _listenMaintenances(),
      _listenEvents(),
    ]);
    debugPrint('🔥 CacheService: ${_subscriptions.length} listeners started');
  }

  /// Stop all Firestore listeners.
  /// Call before logout to prevent writes after session ends.
  void stopListening() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    debugPrint('🔥 CacheService: All listeners stopped');
  }

   StreamSubscription<QuerySnapshot<Map<String, dynamic>>> _listenStock() {
    return _fs.collection('stocks').snapshots().listen(
      (snapshot) async {
        for (final change in snapshot.docChanges) {
          try {
            if (change.type == DocumentChangeType.added ||
                change.type == DocumentChangeType.modified) {
              await _db.upsertStockItem(
                StockItemMapper.toCompanion(
                  change.doc as QueryDocumentSnapshot<Map<String, dynamic>>,
                ),
              );
            } else if (change.type == DocumentChangeType.removed) {
              // ✅ Supprimer de Drift quand supprimé de Firebase:
              await _db.deleteStockItemByFirebaseId(change.doc.id);
              debugPrint('🗑️ CacheService: Stock supprimé → ${change.doc.id}');
            }
          } catch (e) {
            debugPrint('❌ CacheService: Error processing stock change: $e');
          }
        }
      },
      onError: (e) => debugPrint('❌ CacheService: Stock listener error: $e'),
    );
  }

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>> _listenTerrains() {
    return _fs.collection('terrains').snapshots().listen(
      (snapshot) async {
        for (final change in snapshot.docChanges) {
          try {
            switch (change.type) {
              case DocumentChangeType.added:
              case DocumentChangeType.modified:
                await _db.upsertTerrain(
                  TerrainMapper.toCompanion(change.doc as QueryDocumentSnapshot<Map<String, dynamic>>),
                );
                break;
              case DocumentChangeType.removed:
                await _db.deleteTerrainByFirebaseId(change.doc.id);
                break;
            }
          } catch (e) {
            debugPrint('❌ CacheService: Error processing terrains change: $e');
          }
        }
      },
      onError: (Object e) =>
          debugPrint('❌ CacheService: Terrains listener error: $e'),
    );
  }

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>> _listenMaintenances() {
    return _fs.collection('maintenance').snapshots().listen(
      (snapshot) async {
        for (final change in snapshot.docChanges) {
          try {
            switch (change.type) {
              case DocumentChangeType.added:
              case DocumentChangeType.modified:
                await _db.upsertMaintenance(
                  MaintenanceMapper.toCompanion(change.doc as QueryDocumentSnapshot<Map<String, dynamic>>),
                );
                break;
              case DocumentChangeType.removed:
                await _db.deleteMaintenanceByFirebaseId(change.doc.id);
                break;
            }
          } catch (e) {
            debugPrint('❌ CacheService: Error processing maintenance change: $e');
          }
        }
      },
      onError: (Object e) =>
          debugPrint('❌ CacheService: Maintenance listener error: $e'),
    );
  }

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>> _listenEvents() {
    return _fs.collection('events').snapshots().listen(
      (snapshot) async {
        for (final change in snapshot.docChanges) {
          try {
            switch (change.type) {
              case DocumentChangeType.added:
              case DocumentChangeType.modified:
                await _db.upsertEvent(
                  EventMapper.toCompanion(change.doc as QueryDocumentSnapshot<Map<String, dynamic>>),
                );
                break;
              case DocumentChangeType.removed:
                await _db.deleteEventByFirebaseId(change.doc.id);
                break;
            }
          } catch (e) {
            debugPrint('❌ CacheService: Error processing events change: $e');
          }
        }
      },
      onError: (Object e) =>
          debugPrint('❌ CacheService: Events listener error: $e'),
    );
  }
}
