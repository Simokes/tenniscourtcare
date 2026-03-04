import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart';

import '../presentation/providers/core_providers.dart';
import '../presentation/providers/auth_providers.dart';
import '../data/database/app_database.dart';
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
    return date;
  }
}

@Riverpod(keepAlive: true)
Stream<List<Reservation>> userReservationsStream(
  UserReservationsStreamRef ref,
  String userId,
) {
  final monitor = ListenerMonitor();
  monitor.registerListener('userReservationsStreamProvider');
  ref.onDispose(
    () => monitor.unregisterListener('userReservationsStreamProvider'),
  );

  final db = ref.watch(databaseProvider);

  return (db.select(db.users)..where((u) => u.firestoreUid.equals(userId)))
      .watchSingleOrNull()
      .asyncExpand((user) {
        if (user == null) {
          return Stream.value([]);
        }

        return (db.select(db.reservations)
              ..where(
                (r) =>
                    r.userId.equals(user.id) &
                    r.status.equals('cancelled').not(),
              ))
            .watch()
            .map((reservations) {
              return reservations
                ..sort((a, b) {
                  final dtA = _combineDateAndTime(a.date, a.startTime);
                  final dtB = _combineDateAndTime(b.date, b.startTime);
                  return dtB.compareTo(dtA);
                });
            });
      });
}

@Riverpod(keepAlive: true)
Stream<List<Reservation>> allReservationsStream(AllReservationsStreamRef ref) {
  final monitor = ListenerMonitor();
  monitor.registerListener('allReservationsStreamProvider');
  ref.onDispose(
    () => monitor.unregisterListener('allReservationsStreamProvider'),
  );

  final auth = ref.watch(currentUserProvider);
  if (auth == null || auth.role != Role.admin) {
    throw Exception('Unauthorized: Admin only');
  }

  final db = ref.watch(databaseProvider);

  return db.select(db.reservations).watch().map((reservations) {
    return reservations
      ..sort((a, b) {
        final dtA = _combineDateAndTime(a.date, a.startTime);
        final dtB = _combineDateAndTime(b.date, b.startTime);
        return dtB.compareTo(dtA);
      });
  });
}

@Riverpod()
Future<void> refreshReservations(RefreshReservationsRef ref) async {
  // FirebaseCacheService (Phase A) handles all Firestore → Drift sync
  // automatically via realtime listeners started in AuthNotifier.signIn().
  // Manual refresh is no longer needed.
  debugPrint(
    'ℹ️ refreshReservations: handled automatically by FirebaseCacheService listeners',
  );
}