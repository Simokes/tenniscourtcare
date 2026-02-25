import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/sync/sync_service.dart';
import '../data/database/app_database.dart';
import '../presentation/providers/database_provider.dart';
import '../presentation/providers/auth_providers.dart';
import '../data/firestore/models/terrain_firestore_model.dart';
import '../data/firestore/models/reservation_firestore_model.dart';
import '../domain/entities/terrain.dart' as dom;
import '../domain/enums/role.dart';
import '../data/mappers/terrain_mapper.dart';

part 'sync_providers.g.dart';

@Riverpod(keepAlive: true)
SyncService syncService(SyncServiceRef ref) {
  final db = ref.watch(databaseProvider);
  final service = SyncService(db, FirebaseFirestore.instance);
  service.initialize();
  ref.onDispose(() => service.dispose());
  return service;
}

@Riverpod(keepAlive: true)
Stream<bool> isOnlineStatus(IsOnlineStatusRef ref) {
  return Connectivity().onConnectivityChanged.map((list) => list.any((r) => r != ConnectivityResult.none));
}

@Riverpod()
Stream<int> pendingChangesCount(PendingChangesCountRef ref) async* {
  final service = ref.watch(syncServiceProvider);
  yield await service.getPendingChangesCount();

  await for (final _ in service.onQueueChanged) {
    yield await service.getPendingChangesCount();
  }
}

@Riverpod(keepAlive: true)
Stream<List<dom.Terrain>> terrainsStream(TerrainsStreamRef ref) {
  final db = ref.watch(databaseProvider);
  final sync = ref.watch(syncServiceProvider);

  final sub = sync.syncDown<TerrainFirestoreModel>(
    collection: 'terrains',
    fromFirestore: (doc) => TerrainFirestoreModel.fromFirestore(doc),
    getId: (item) => item.id,
    saveToLocal: (items) async {
      await db.transaction(() async {
        for (final item in items) {
          final existing = await (db.select(db.terrains)..where((t) => t.remoteId.equals(item.id))).getSingleOrNull();

          final companion = TerrainsCompanion(
            remoteId: Value(item.id),
            nom: Value(item.name),
            type: const Value(0),
            location: Value(item.location),
            capacity: Value(item.capacity),
            pricePerHour: Value(item.pricePerHour),
            available: Value(item.available),
            createdAt: Value(item.createdAt),
            updatedAt: Value(item.updatedAt),
            syncedAt: Value(DateTime.now()),
            imageUrl: Value(item.imageUrl),
          );

          if (existing != null) {
            await (db.update(db.terrains)..where((t) => t.id.equals(existing.id))).write(companion);
          } else {
            await db.into(db.terrains).insert(companion);
          }
        }
      });
    }
  );

  ref.onDispose(() => sub.cancel());

  return db.select(db.terrains).watch().map((rows) => rows.map((r) => r.toDomain()).toList());
}

@Riverpod(keepAlive: true)
Stream<List<Reservation>> reservationsStream(ReservationsStreamRef ref) async* {
  final db = ref.watch(databaseProvider);
  final sync = ref.watch(syncServiceProvider);
  final currentUser = ref.watch(currentUserProvider);

  if (currentUser == null) {
    yield [];
    return;
  }

  // Get firestoreUid
  final userRow = await (db.select(db.users)..where((u) => u.id.equals(currentUser.id))).getSingleOrNull();
  final firestoreUid = userRow?.firestoreUid;

  final isAdmin = currentUser.role == Role.admin;

  if (isAdmin || firestoreUid != null) {
      final sub = sync.syncDown<ReservationFirestoreModel>(
        collection: 'reservations',
        queryFn: (q) => isAdmin ? q : q.where('userId', isEqualTo: firestoreUid),
        fromFirestore: (doc) => ReservationFirestoreModel.fromFirestore(doc),
        getId: (item) => item.id,
        saveToLocal: (items) async {
           await db.transaction(() async {
             for (final item in items) {
               // Resolve User
               final u = await (db.select(db.users)..where((u) => u.firestoreUid.equals(item.userId))).getSingleOrNull();
               if (u == null) continue;

               // Resolve Terrain
               final t = await (db.select(db.terrains)..where((t) => t.remoteId.equals(item.terrainId))).getSingleOrNull();
               if (t == null) continue;

               final existing = await (db.select(db.reservations)..where((r) => r.remoteId.equals(item.id))).getSingleOrNull();

               final companion = ReservationsCompanion(
                 remoteId: Value(item.id),
                 userId: Value(u.id),
                 terrainId: Value(t.id),
                 date: Value(item.date),
                 startTime: Value(item.startTime),
                 endTime: Value(item.endTime),
                 status: Value(item.status),
                 notes: Value(item.notes),
                 createdAt: Value(item.createdAt),
                 updatedAt: Value(item.updatedAt),
                 syncedAt: Value(DateTime.now()),
                 isSyncPending: const Value(false),
               );

               if (existing != null) {
                  await (db.update(db.reservations)..where((r) => r.id.equals(existing.id))).write(companion);
               } else {
                  await db.into(db.reservations).insert(companion);
               }
             }
           });
        }
      );
      ref.onDispose(() => sub.cancel());
  }

  // Watch local
  final query = db.select(db.reservations);
  if (!isAdmin) {
    query.where((r) => r.userId.equals(currentUser.id));
  }
  yield* query.watch();
}
