import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' as drift;

import '../data/database/app_database.dart';
import '../providers/sync_providers.dart';
import '../services/sync/sync_service.dart';
import '../widgets/sync_status_bar.dart';
import '../presentation/providers/database_provider.dart';
import '../presentation/providers/auth_providers.dart';

class ExampleIntegrationScreen extends ConsumerWidget {
  const ExampleIntegrationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservationsAsync = ref.watch(reservationsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sync Example')),
      body: Column(
        children: [
          const SyncStatusBar(),
          Expanded(
            child: reservationsAsync.when(
              data: (reservations) {
                if (reservations.isEmpty) {
                  return const Center(child: Text('No reservations'));
                }
                return ListView.builder(
                  itemCount: reservations.length,
                  itemBuilder: (context, index) {
                    final res = reservations[index];
                    return ListTile(
                      title: Text('Res: ${res.remoteId ?? 'Local-${res.id}'}'),
                      subtitle: Text('Status: ${res.status} | Pending: ${res.isSyncPending}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteReservation(context, ref, res),
                      ),
                      onTap: () => _updateReservation(context, ref, res),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createReservation(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _createReservation(BuildContext context, WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    final sync = ref.read(syncServiceProvider);
    final currentUser = ref.read(currentUserProvider);

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No user logged in')));
      return;
    }

    // 1. Generate ID
    final remoteId = 'res_${DateTime.now().millisecondsSinceEpoch}';

    // 2. Create Local
    final companion = ReservationsCompanion(
      remoteId: drift.Value(remoteId),
      userId: drift.Value(currentUser.id),
      terrainId: const drift.Value(1), // Hardcoded valid ID for demo, assumes terrain #1 exists
      date: drift.Value(DateTime.now()),
      startTime: const drift.Value('10:00'),
      endTime: const drift.Value('11:00'),
      status: const drift.Value('pending'),
      createdAt: drift.Value(DateTime.now()),
      isSyncPending: const drift.Value(true),
    );

    await db.into(db.reservations).insert(companion);

    // 3. Sync Up
    // Get firestore UID for user
    final userRow = await (db.select(db.users)..where((u) => u.id.equals(currentUser.id))).getSingleOrNull();
    final firestoreUid = userRow?.firestoreUid ?? 'unknown_uid';

    final data = {
      'userId': firestoreUid,
      'terrainId': 'terrain_1_remote_id', // Placeholder
      'date': Timestamp.fromDate(DateTime.now()),
      'startTime': '10:00',
      'endTime': '11:00',
      'status': 'pending',
      'createdAt': Timestamp.fromDate(DateTime.now()),
    };

    final success = await sync.syncUp(
      'reservations',
      remoteId,
      data,
      action: SyncAction.create,
    );

    if (context.mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(success ? 'Synced!' : 'Queued for sync')),
       );
    }
  }

  Future<void> _updateReservation(BuildContext context, WidgetRef ref, Reservation res) async {
    final db = ref.read(databaseProvider);
    final sync = ref.read(syncServiceProvider);

    if (res.remoteId == null) return;

    // 1. Update Local
    final newStatus = res.status == 'pending' ? 'confirmed' : 'pending';
    await (db.update(db.reservations)..where((r) => r.id.equals(res.id))).write(
      ReservationsCompanion(
        status: drift.Value(newStatus),
        isSyncPending: const drift.Value(true),
      ),
    );

    // 2. Sync Up
    final success = await sync.syncUp(
      'reservations',
      res.remoteId!,
      {'status': newStatus},
      action: SyncAction.update,
    );

     if (context.mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(success ? 'Synced update!' : 'Update queued')),
       );
    }
  }

  Future<void> _deleteReservation(BuildContext context, WidgetRef ref, Reservation res) async {
    final db = ref.read(databaseProvider);
    final sync = ref.read(syncServiceProvider);

    if (res.remoteId == null) return;

    // 1. Delete Local
    await (db.delete(db.reservations)..where((r) => r.id.equals(res.id))).go();

    // 2. Sync Up
    final success = await sync.syncUp(
      'reservations',
      res.remoteId!,
      {},
      action: SyncAction.delete,
    );

     if (context.mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(success ? 'Synced delete!' : 'Delete queued')),
       );
    }
  }
}
