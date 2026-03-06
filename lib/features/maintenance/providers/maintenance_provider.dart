import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/mappers/maintenance_mapper.dart';
import '../../../data/repositories/maintenance_repository_impl.dart';
import '../../../domain/entities/maintenance.dart';
import '../../../domain/models/repository_exception.dart';
import '../../../domain/repositories/maintenance_repository.dart';
import '../../../core/providers/core_providers.dart';

// Repository Provider
import '../../terrain/providers/terrain_provider.dart';

final maintenanceRepositoryProvider = Provider<MaintenanceRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final terrainRepo = ref.watch(terrainRepositoryProvider);
  return MaintenanceRepositoryImpl(
    db: db,
    fs: FirebaseFirestore.instance,
    terrainRepository: terrainRepo,
  );
});

final maintenancesProvider = StreamProvider<List<Maintenance>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllMaintenances();
});

final plannedMaintenancesProvider = StreamProvider<List<Maintenance>>((ref) {
  return ref.watch(maintenanceRepositoryProvider).watchPlannedMaintenances();
});

// --- Maintenance Helpers ---

final maintenancesByTerrainProvider =
    StreamProvider.family<List<Maintenance>, int>((ref, terrainId) {
      final allMaintenances = ref.watch(maintenancesProvider);
      return allMaintenances.when(
        data: (maintenances) => Stream.value(
          maintenances.where((m) => m.terrainId == terrainId).toList()
            ..sort((a, b) => b.date.compareTo(a.date)), // Sort by date desc
        ),
        loading: () => Stream.value([]),
        error: (error, stack) => Stream.value([]),
      );
    });

final lastMajorMaintenanceProvider = StreamProvider.family<Maintenance?, int>((
  ref,
  terrainId,
) {
  final maintenances =
      ref.watch(maintenancesByTerrainProvider(terrainId)).asData?.value ?? [];
  if (maintenances.isEmpty) return Stream.value(null);

  try {
    return Stream.value(
      maintenances.firstWhere(
        (m) =>
            m.type.toLowerCase().contains('annuel') ||
            m.type.toLowerCase().contains('rénovation'),
      ),
    );
  } catch (e) {
    return Stream.value(
      maintenances.first,
    ); // Fallback to most recent if no "major" found
  }
});

class MaintenanceNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // No initial loading needed as we only manage mutations
  }

  Future<void> addMaintenance(Maintenance maintenance) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(maintenanceRepositoryProvider);
      final db = ref.read(databaseProvider);

      final firebaseId = await repo.addMaintenance(maintenance);
      final updatedMaintenance = maintenance.copyWith(firebaseId: firebaseId);

      await db.upsertMaintenance(updatedMaintenance.toCompanion());
    });
  }

  Future<void> updateMaintenance(Maintenance maintenance) async {
    if (maintenance.firebaseId == null) {
      throw const RepositoryException(
        'Cannot update maintenance without a firebaseId',
      );
    }

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(maintenanceRepositoryProvider);
      await repo.updateMaintenance(maintenance);
    });
  }

  Future<void> deleteMaintenance(String firebaseId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(maintenanceRepositoryProvider);
      await repo.deleteMaintenance(firebaseId);
    });
  }

  Future<void> markAsCompleted({
    required String firebaseId,
    required Maintenance completed,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(maintenanceRepositoryProvider);
      final db = ref.read(databaseProvider);
      await repo.markAsCompleted(
        firebaseId: firebaseId,
        completed: completed,
      );

      final updatedMaintenance = completed.copyWith(isPlanned: false, firebaseId: firebaseId);
      await db.upsertMaintenance(updatedMaintenance.toCompanion());
    });
  }
}

final maintenanceNotifierProvider =
    AsyncNotifierProvider<MaintenanceNotifier, void>(MaintenanceNotifier.new);
