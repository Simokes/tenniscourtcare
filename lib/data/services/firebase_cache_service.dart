import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:tenniscourtcare/data/database/app_database.dart';
import 'package:tenniscourtcare/data/mappers/event_mapper.dart';
import 'package:tenniscourtcare/data/mappers/maintenance_mapper.dart';
import 'package:tenniscourtcare/data/mappers/stock_item_mapper.dart';
import 'package:tenniscourtcare/data/mappers/terrain_mapper.dart';
import 'package:drift/drift.dart' as drift;
import 'package:tenniscourtcare/domain/enums/role.dart';

/// Listens to Firestore collections and keeps Drift cache in sync.
/// This is the ONLY component authorized to write into Drift.
/// Start on login via [startListening], stop on logout via [stopListening].
class FirebaseCacheService {
  FirebaseCacheService(this._db, this._fs);

  final AppDatabase _db;
  final FirebaseFirestore _fs;
  final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
  _subscriptions = [];

  bool _stockServerSyncDone = false;
  bool _terrainsServerSyncDone = false;
  bool _maintenancesServerSyncDone = false;
  bool _eventsServerSyncDone = false;
  bool _usersServerSyncDone = false;

  bool _shouldListen = false;
  int _restartAttempts = 0;
  Timer? _restartTimer;
  StreamSubscription<bool>? _connectivitySubscription;

  static const _baseRestartDelay = Duration(seconds: 3);
  static const _maxRestartDelay = Duration(seconds: 30);

  bool get isListening => _subscriptions.isNotEmpty;

  Duration get _nextRestartDelay {
    final seconds =
        _baseRestartDelay.inSeconds * (1 << _restartAttempts.clamp(0, 3));
    return Duration(
      seconds: seconds.clamp(
        _baseRestartDelay.inSeconds,
        _maxRestartDelay.inSeconds,
      ),
    );
  }

  void _scheduleRestart() {
    if (!_shouldListen) return;
    _restartTimer?.cancel();
    final delay = _nextRestartDelay;
    debugPrint(
      '⚠️ CacheService: Restart scheduled in ${delay.inSeconds}s (attempt ${_restartAttempts + 1})',
    );
    _restartTimer = Timer(delay, () {
      if (!_shouldListen) return;
      _restartAttempts++;
      stopListening();
      startListening();
      debugPrint(
        '🔄 CacheService: Listeners restarted (attempt $_restartAttempts)',
      );
    });
  }

  void startConnectivityMonitoring(Stream<bool> connectivityStream) {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = connectivityStream.listen((isOnline) {
      if (isOnline && _shouldListen && !isListening) {
        debugPrint('🌐 CacheService: Back online — restarting listeners');
        _restartAttempts = 0;
        startListening();
      }
    });
  }

  void startListening() {
    if (isListening) {
      debugPrint('⚠️ CacheService: Already listening, skipping');
      return;
    }
    _shouldListen = true;
    _restartAttempts = 0;
    _restartTimer?.cancel();
    _stockServerSyncDone = false;
    _terrainsServerSyncDone = false;
    _maintenancesServerSyncDone = false;
    _eventsServerSyncDone = false;
    _usersServerSyncDone = false;
    _subscriptions.addAll([
      _listenStock(),
      _listenTerrains(),
      _listenMaintenances(),
      _listenEvents(),
      _listenUsers(),
    ]);
    debugPrint('🔥 CacheService: ${_subscriptions.length} listeners started');
  }

  void stopListening() {
    _shouldListen = false;
    _restartTimer?.cancel();
    _restartTimer = null;
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    debugPrint('🔥 CacheService: All listeners stopped');
  }

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>> _listenStock() {
    return _fs.collection('stocks').snapshots().listen((snapshot) async {
      // Orphan cleanup uniquement sur snapshot serveur (pas cache local Firestore)
      if (!snapshot.metadata.isFromCache && !_stockServerSyncDone) {
        _stockServerSyncDone = true;
        try {
          final activeIds = snapshot.docs.map((d) => d.id).toSet();
          await _db.deleteOrphanStockItems(activeIds);
          debugPrint('🧹 CacheService: Stock orphan cleanup done (${activeIds.length} active)');
        } catch (e, st) {
          debugPrint('⚠️ CacheService: Stock orphan cleanup failed: $e\n$st');
        }
      }
      for (final change in snapshot.docChanges) {
        try {
          if (change.type == DocumentChangeType.added ||
              change.type == DocumentChangeType.modified) {
            final data = change.doc.data();
            if (data == null) continue;
            await _db.upsertStockItem(
              StockItemMapper.toCompanion(change.doc.id, data),
            );
          } else if (change.type == DocumentChangeType.removed) {
            await _db.deleteStockItemByFirebaseId(change.doc.id);
          }
        } catch (e, st) {
          debugPrint('❌ CacheService: Error processing stock change: $e\n$st');
          _scheduleRestart();
        }
      }
    }, onError: (e) {
      debugPrint('❌ CacheService: Stock listener error: $e');
      _scheduleRestart();
    });
  }

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>> _listenTerrains() {
    return _fs.collection('terrains').snapshots().listen(
      (snapshot) async {
        if (!snapshot.metadata.isFromCache && !_terrainsServerSyncDone) {
          _terrainsServerSyncDone = true;
          try {
            final activeIds = snapshot.docs.map((d) => d.id).toSet();
            await _db.deleteOrphanTerrains(activeIds);
            debugPrint('🧹 CacheService: Terrains orphan cleanup done (${activeIds.length} active)');
          } catch (e, st) {
            debugPrint('⚠️ CacheService: Terrains orphan cleanup failed: $e\n$st');
          }
        }
        for (final change in snapshot.docChanges) {
          try {
            if (change.type == DocumentChangeType.added ||
                change.type == DocumentChangeType.modified) {
              final data = change.doc.data();
              if (data == null) continue;
              await _db.upsertTerrain(
                TerrainMapper.toCompanion(change.doc.id, data),
              );
            } else if (change.type == DocumentChangeType.removed) {
              await _db.deleteTerrainByFirebaseId(change.doc.id);
            }
          } catch (e, st) {
            debugPrint('❌ CacheService: Error processing terrains change: $e\n$st');
            _scheduleRestart();
          }
        }
      },
      onError: (e) {
        debugPrint('❌ CacheService: Terrains listener error: $e');
        _scheduleRestart();
      },
    );
  }

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>
  _listenMaintenances() {
    return _fs.collection('maintenance').snapshots().listen(
      (snapshot) async {
        if (!snapshot.metadata.isFromCache && !_maintenancesServerSyncDone) {
          _maintenancesServerSyncDone = true;
          try {
            final activeIds = snapshot.docs.map((d) => d.id).toSet();
            await _db.deleteOrphanMaintenances(activeIds);
            debugPrint('🧹 CacheService: Maintenances orphan cleanup done (${activeIds.length} active)');
          } catch (e, st) {
            debugPrint('⚠️ CacheService: Maintenances orphan cleanup failed: $e\n$st');
          }
        }
        for (final change in snapshot.docChanges) {
          try {
            if (change.type == DocumentChangeType.added ||
                change.type == DocumentChangeType.modified) {
              final data = change.doc.data();
              if (data == null) continue;
              await _db.upsertMaintenance(
                MaintenanceMapper.toCompanion(change.doc.id, data),
              );
            } else if (change.type == DocumentChangeType.removed) {
              await _db.deleteMaintenanceByFirebaseId(change.doc.id);
            }
          } catch (e, st) {
            debugPrint(
              '❌ CacheService: Error processing maintenance change: $e\n$st',
            );
            _scheduleRestart();
          }
        }
      },
      onError: (e) {
        debugPrint('❌ CacheService: Maintenance listener error: $e');
        _scheduleRestart();
      },
    );
  }

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>> _listenEvents() {
    return _fs.collection('events').snapshots().listen((snapshot) async {
      if (!snapshot.metadata.isFromCache && !_eventsServerSyncDone) {
        _eventsServerSyncDone = true;
        try {
          final activeIds = snapshot.docs.map((d) => d.id).toSet();
          await _db.deleteOrphanEvents(activeIds);
          debugPrint('🧹 CacheService: Events orphan cleanup done (${activeIds.length} active)');
        } catch (e, st) {
          debugPrint('⚠️ CacheService: Events orphan cleanup failed: $e\n$st');
        }
      }
      for (final change in snapshot.docChanges) {
        try {
          if (change.type == DocumentChangeType.added ||
              change.type == DocumentChangeType.modified) {
            final data = change.doc.data();
            if (data == null) continue;
            await _db.upsertEvent(EventMapper.toCompanion(change.doc.id, data));
          } else if (change.type == DocumentChangeType.removed) {
            await _db.deleteEventByFirebaseId(change.doc.id);
          }
        } catch (e, st) {
          debugPrint('❌ CacheService: Error processing events change: $e\n$st');
          _scheduleRestart();
        }
      }
    }, onError: (e) {
      debugPrint('❌ CacheService: Events listener error: $e');
      _scheduleRestart();
    });
  }

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>> _listenUsers() {
    return _fs.collection('users').snapshots().listen((snapshot) async {
      if (!snapshot.metadata.isFromCache && !_usersServerSyncDone) {
        _usersServerSyncDone = true;
        try {
          final activeUids = snapshot.docs.map((d) => d.id).toSet();
          await _db.deleteOrphanUsers(activeUids);
          debugPrint('🧹 CacheService: Users orphan cleanup done (${activeUids.length} active)');
        } catch (e, st) {
          debugPrint('⚠️ CacheService: Users orphan cleanup failed: $e\n$st');
        }
      }
      for (final change in snapshot.docChanges) {
        try {
          if (change.type == DocumentChangeType.added ||
              change.type == DocumentChangeType.modified) {
            final data = change.doc.data();
            if (data == null) continue;

            final uid = data['uid'] as String? ?? change.doc.id;
            final roleStr = data['role'] as String? ?? 'agent';
            final role = Role.values.firstWhere(
              (r) => r.name == roleStr,
              orElse: () => Role.agent,
            );

            DateTime? parseTimestamp(dynamic ts) {
              if (ts == null) return null;
              if (ts is Timestamp) return ts.toDate();
              return null;
            }

            final companion = UsersCompanion(
              email: drift.Value(data['email'] as String? ?? ''),
              firestoreUid: drift.Value(uid),
              name: drift.Value(
                data['name'] ?? data['firstName'] ?? 'Utilisateur',
              ),
              role: drift.Value(role),
              status: drift.Value(data['status'] as String? ?? 'inactive'),
              approvedAt: drift.Value(parseTimestamp(data['approvedAt'])),
              approvedBy: drift.Value(data['approvedBy'] as String?),
              createdAt: drift.Value(
                parseTimestamp(data['createdAt']) ?? DateTime.now(),
              ),
              passwordHash: const drift.Value('FIREBASE_AUTH'),
            );

            await _db.upsertUser(companion);
          } else if (change.type == DocumentChangeType.removed) {
            await _db.deleteUserByFirebaseId(change.doc.id);
          }
        } catch (e, st) {
          debugPrint('❌ CacheService: Error processing users change: $e\n$st');
          _scheduleRestart();
        }
      }
    }, onError: (e) {
      debugPrint('❌ CacheService: Users listener error: $e');
      _scheduleRestart();
    });
  }
}
