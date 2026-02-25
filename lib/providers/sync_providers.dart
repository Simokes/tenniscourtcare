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
import '../domain/enums/role.dart';

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
Stream<bool> isOnlineStatus(IsOnlineStatusRef ref) async* {
  final connectivity = Connectivity();

  // Initial check
  final initialResult = await connectivity.checkConnectivity();
  yield initialResult != ConnectivityResult.none;

  // Listen to changes
  await for (final result in connectivity.onConnectivityChanged) {
    yield result != ConnectivityResult.none;
  }
}


@Riverpod(keepAlive: true)
Stream<void> backgroundTerrainsSync(BackgroundTerrainsSyncRef ref) async* {
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
            updatedAt: Value(item.updatedAt ?? item.createdAt),
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
}

@Riverpod(keepAlive: true)
Stream<void> backgroundReservationsSync(BackgroundReservationsSyncRef ref) async* {
  final db = ref.watch(databaseProvider);
  final sync = ref.watch(syncServiceProvider);
  final currentUser = ref.watch(currentUserProvider);

  if (currentUser == null) {
    return;
  }

  // Get firestoreUid
  // We need to ensure we re-fetch this if the user changes or if the user row is updated (e.g. initial sync)
  // Watching the user row specifically might be better, but currentUserProvider changes on login/logout.
  // However, firestoreUid might be null initially and then populated by sync.
  // We should probably watch the user row here too?
  // But the prompt specifically asked to handle currentUser change.
  // `ref.watch(currentUserProvider)` already handles the auth state change.
  // The issue is if we just do `await ... getSingleOrNull()`, we don't react if the local user row updates (e.g. firestoreUid arrives).
  // But `backgroundReservationsSync` is a Stream provider.
  // If we want it to restart when `firestoreUid` becomes available, we should watch that.

  // Let's watch the local user row corresponding to the auth user.
  final userRow = await (db.select(db.users)..where((u) => u.id.equals(currentUser.id))).watchSingleOrNull().first;

  // If we want this provider to rebuild when userRow changes (e.g. firestoreUid added),
  // we should use `watch` inside the body if it were a functional provider returning a value.
  // But this is `Stream<void>`.
  // The prompt suggestion:
  // "Remplacer: if (currentUser == null) { return; } Par: final currentUserAsync = ref.watch(currentUserProvider); ..."
  // My code already has `final currentUser = ref.watch(currentUserProvider);` (which returns UserEntity? directly in this codebase usually, or AsyncValue?)
  // Let's check `auth_providers.dart`.
  // If it returns `UserEntity?`, then `ref.watch` re-runs the provider when it changes.
  // So `currentUser` variable updates, and the provider body re-runs?
  // Yes, if `currentUserProvider` notifies.
  // So the "Risk: Data leak" is if we don't cancel the previous subscription.
  // `ref.onDispose` handles cancellation of the *current* execution's subscription.
  // When `currentUser` changes, the provider is re-evaluated. The old state is disposed (calling onDispose -> sub.cancel()), and a new execution starts.
  // So the logic seems correct IF `currentUserProvider` is watched.
  //
  // However, the prompt says "If User A log out, User B log in -> sync continue for User A".
  // This implies `ref.watch` is NOT correctly triggering a dispose/rebuild or `currentUser` is not what I think.
  // `currentUserProvider` usually returns `UserEntity?`.
  // If I use `ref.watch(currentUserProvider)`, the provider `backgroundReservationsSync` SHOULD invalidate when user changes.
  //
  // BUT, inside the `async*`, if we are suspended at `yield` or `await`, and the dependency changes...
  // Riverpod streams: if dependency changes, the stream is re-created.
  //
  // The prompt suggested explicitly handling AsyncValue.
  // Maybe `currentUserProvider` returns `AsyncValue<UserEntity>`?
  // Let's check `auth_providers.dart`.

  // I will apply the fix as requested to be safe, assuming currentUserProvider might be AsyncValue or just to ensure explicit handling.
  // Wait, I need to check if `currentUserProvider` returns Stream/Future/Data.
  // If it returns `UserEntity?` (state), then `ref.watch` gives the value.

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
}
