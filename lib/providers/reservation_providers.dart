import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../presentation/providers/database_provider.dart';
import '../presentation/providers/auth_providers.dart';
import '../providers/sync_providers.dart';
import '../data/database/app_database.dart';
import '../data/firestore/models/reservation_firestore_model.dart';
import '../domain/enums/role.dart';
import '../services/listener_monitor.dart';

part 'reservation_providers.g.dart';

// Helper to combine date and time for sorting
DateTime _combineDateAndTime(DateTime date, String time) {
  try {
    final parts = time.split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  } catch (e) {
    return date; // Fallback
  }
}

@Riverpod(keepAlive: true)
Stream<List<Reservation>> userReservationsStream(
  UserReservationsStreamRef ref,
  String userId, // This is Firestore UID or Local ID? The prompt says "userId", usually meaning UID in this app context or just "userId" string.
  // The prompt usage: `ref.watch(userReservationsStreamProvider('user123'));`
  // The drift table has `userId` as Int (FK).
  // The prompt says "filtered by userId".
  // If the parameter is String (UID), I need to find the Int ID first.
  // Or maybe the prompt meant the Int ID?
  // "usage: ref.watch(userReservationsStreamProvider('user123'))" -> 'user123' looks like UID.
  // I will assume UID.
) {
  final monitor = ListenerMonitor();
  monitor.registerListener('userReservationsStreamProvider');
  ref.onDispose(() => monitor.unregisterListener('userReservationsStreamProvider'));

  final db = ref.watch(databaseProvider);

  // We need to resolve UID to Int ID
  // But we can't await in a stream provider body easily without being async*.
  // But this is `Stream<List<Reservation>>`, so we can `async*`.
  // Wait, drift watch returns a stream.
  // I can switch map to async map? No.

  // Strategy: Watch Users table for that UID to get the ID, then switch map?
  // Or just query once? If user ID changes (unlikely), we'd want to know.
  // Let's assume we pass the Int ID? No, prompt says 'user123'.

  // Watch the user table to react when user is synced/inserted
  return (db.select(db.users)..where((u) => u.firestoreUid.equals(userId)))
      .watchSingleOrNull()
      .asyncExpand((user) {
        if (user == null) {
          return Stream.value([]);
        }

        return (db.select(db.reservations)
          ..where((r) => r.userId.equals(user.id) & r.status.isNotValue('cancelled'))
        ).watch().map((reservations) {
          return reservations
            ..sort((a, b) {
               final dtA = _combineDateAndTime(a.date, a.startTime);
               final dtB = _combineDateAndTime(b.date, b.startTime);
               return dtB.compareTo(dtA); // DESC
            });
        });
      });
}

@Riverpod(keepAlive: true)
Stream<List<Reservation>> allReservationsStream(AllReservationsStreamRef ref) {
  final monitor = ListenerMonitor();
  monitor.registerListener('allReservationsStreamProvider');
  ref.onDispose(() => monitor.unregisterListener('allReservationsStreamProvider'));

  final auth = ref.watch(currentUserProvider);
  if (auth == null || auth.role != Role.admin) {
    throw Exception('Unauthorized: Admin only');
  }

  final db = ref.watch(databaseProvider);

  return db.select(db.reservations)
    .watch()
    .map((reservations) {
      return reservations
        ..sort((a, b) {
           final dtA = _combineDateAndTime(a.date, a.startTime);
           final dtB = _combineDateAndTime(b.date, b.startTime);
           return dtB.compareTo(dtA); // DESC
        });
    });
}

@Riverpod()
Future<void> refreshReservations(RefreshReservationsRef ref) async {
  final sync = ref.read(syncServiceProvider);
  final db = ref.read(databaseProvider);
  final currentUser = ref.read(currentUserProvider);

  if (currentUser == null) return;

  final isAdmin = currentUser.role == Role.admin;

  // Get firestore UID for query
  final userRow = await (db.select(db.users)..where((u) => u.id.equals(currentUser.id))).getSingleOrNull();
  final firestoreUid = userRow?.firestoreUid;

  if (!isAdmin && firestoreUid == null) return;

  await sync.refreshCollection<ReservationFirestoreModel>(
    collection: 'reservations',
    queryFn: (q) => isAdmin ? q : q.where('userId', isEqualTo: firestoreUid),
    fromFirestore: (doc) => ReservationFirestoreModel.fromFirestore(doc),
    saveToLocal: (items) async {
      await db.transaction(() async {
         // If admin, delete all. If user, delete only theirs.
         if (isAdmin) {
           await db.delete(db.reservations).go();
         } else {
           // We need to delete reservations for this user.
           // But items contains the new list.
           // We should delete all for this user locally to handle removals.
           await (db.delete(db.reservations)..where((r) => r.userId.equals(currentUser.id))).go();
         }

         for (final item in items) {
           // Resolve dependencies
           final u = await (db.select(db.users)..where((u) => u.firestoreUid.equals(item.userId))).getSingleOrNull();
           if (u == null) continue; // Skip if user not found

           final t = await (db.select(db.terrains)..where((t) => t.remoteId.equals(item.terrainId))).getSingleOrNull();
           if (t == null) continue; // Skip if terrain not found

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

           await db.into(db.reservations).insert(companion);
         }
      });
    },
  );
}
