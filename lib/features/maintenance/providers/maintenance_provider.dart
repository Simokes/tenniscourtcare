import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/maintenance_repository_impl.dart';
import '../../../domain/entities/maintenance.dart';
import '../../../domain/models/repository_exception.dart';
import '../../../domain/repositories/maintenance_repository.dart';
import '../../../core/providers/core_providers.dart';
import '../../../data/mappers/maintenance_mapper.dart';

// Repository Provider
import '../../terrain/providers/terrain_provider.dart';
import '../../inventory/providers/stock_provider.dart';

final maintenanceRepositoryProvider = Provider<MaintenanceRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final terrainRepo = ref.watch(terrainRepositoryProvider);
  final stockRepo = ref.watch(stockRepositoryProvider);
  return MaintenanceRepositoryImpl(
    db: db,
    fs: FirebaseFirestore.instance,
    terrainRepository: terrainRepo,
    stockRepository: stockRepo,
  );
});

final maintenancesProvider = StreamProvider<List<Maintenance>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllMaintenances();
});

final plannedMaintenancesProvider = StreamProvider<List<Maintenance>>((ref) {
  return ref.watch(maintenanceRepositoryProvider).watchPlannedMaintenances();
});

final overdueMaintenancesProvider = Provider<List<Maintenance>>((ref) {
  final planned = ref.watch(plannedMaintenancesProvider).valueOrNull ?? [];
  final now = DateTime.now();

  return planned.where((m) {
    final date = DateTime.fromMillisecondsSinceEpoch(m.date);
    final maintenanceStart = DateTime(
      date.year,
      date.month,
      date.day,
      m.startHour,
    );
    final maintenanceEnd = maintenanceStart.add(
      Duration(minutes: m.durationMinutes),
    );
    return maintenanceEnd.isBefore(now);
  }).toList();
});

final overdueCountProvider = Provider<int>((ref) {
  return ref.watch(overdueMaintenancesProvider).length;
});

// All maintenances grouped by terrainId (done only)
final maintenancesGroupedByTerrainProvider =
    Provider<Map<int, List<Maintenance>>>((ref) {
      final all = ref.watch(maintenancesProvider).valueOrNull ?? [];
      final map = <int, List<Maintenance>>{};
      for (final m in all) {
        if (!m.isPlanned) {
          map.putIfAbsent(m.terrainId, () => []).add(m);
        }
      }
      // Sort each list by date desc
      for (final list in map.values) {
        list.sort((a, b) => b.date.compareTo(a.date));
      }
      return map;
    });

// All unique maintenance types across all maintenances
final maintenanceTypesProvider = Provider<List<String>>((ref) {
  final all = ref.watch(maintenancesProvider).valueOrNull ?? [];
  return all.map((m) => m.type).toSet().toList()..sort();
});

// --- Maintenance Helpers ---

final maintenancesByTerrainProvider =
    StreamProvider.family<List<Maintenance>, int>((ref, terrainId) {
      final db = ref.watch(databaseProvider);
      return db.watchMaintenancesForTerrain(terrainId); // ✅ Stream Drift direct
    });

final plannedMaintenancesByTerrainProvider =
    Provider.family<List<Maintenance>, int>((ref, terrainId) {
      final allPlanned =
          ref.watch(plannedMaintenancesProvider).valueOrNull ?? [];
      return allPlanned.where((m) => m.terrainId == terrainId).toList()
        ..sort((a, b) => a.date.compareTo(b.date)); // Sort by date asc
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
      await db.upsertMaintenance(
        MaintenanceMapper.toCompanion(
          firebaseId,
          MaintenanceMapper.toFirestore(maintenance),
        ),
      );
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
      await repo.markAsCompleted(
        firebaseId: firebaseId,
        completed: completed,
      ); // ✅ repo gère déjà le upsert Drift
    });
  }
}

final maintenanceNotifierProvider =
    AsyncNotifierProvider<MaintenanceNotifier, void>(MaintenanceNotifier.new);
