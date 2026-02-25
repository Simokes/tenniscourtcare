import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart';

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
  String userId, // Firestore UID
) {
  final monitor = ListenerMonitor();
  monitor.registerListener('userReservationsStreamProvider');
  ref.onDispose(() => monitor.unregisterListener('userReservationsStreamProvider'));

  final db = ref.watch(databaseProvider);

  // Watch the user table to react when user is synced/inserted
  return (db.select(db.users)..where((u) => u.firestoreUid.equals(userId)))
      .watchSingleOrNull()
      .asyncExpand((user) {
        if (user == null) {
          return Stream.value([]);
        }

        return (db.select(db.reservations)
          ..where((r) => r.userId.equals(user.id) & r.status.equals('cancelled').not())
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
