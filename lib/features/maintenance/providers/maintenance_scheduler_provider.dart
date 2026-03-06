import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tenniscourtcare/domain/entities/terrain.dart';
import 'package:tenniscourtcare/domain/logic/maintenance_scheduler.dart';
import 'package:tenniscourtcare/features/maintenance/providers/maintenance_provider.dart';
import 'package:tenniscourtcare/features/terrain/providers/terrain_provider.dart';

final maintenanceSchedulerProvider = Provider<void>((ref) {
  // Run immediately on startup
  _checkAndUpdateTerrainStatuses(ref);

  // Then every 60 seconds
  final timer = Timer.periodic(const Duration(seconds: 60), (_) {
    _checkAndUpdateTerrainStatuses(ref);
  });

  ref.onDispose(() => timer.cancel());
});

Future<void> _checkAndUpdateTerrainStatuses(Ref ref) async {
  final plannedAsync = ref.read(plannedMaintenancesProvider);
  final planned = plannedAsync.valueOrNull ?? [];
  if (planned.isEmpty) return;

  final terrainRepo = ref.read(terrainRepositoryProvider);
  final now = DateTime.now();

  // Terrains that should be IN maintenance now
  final toMaintenance = MaintenanceScheduler.terrainsToSetInMaintenance(
    planned,
    now,
  );

  // Terrains that were in maintenance but window passed
  final terrains = ref.read(terrainsProvider).valueOrNull ?? [];
  final currentMaintenanceIds = terrains
      .where((t) => t.status == TerrainStatus.maintenance)
      .map((t) => t.id)
      .toList();

  final toRestore = MaintenanceScheduler.terrainsToRestoreToPlayable(
    planned,
    currentMaintenanceIds,
    now,
  );

  for (final terrainId in toMaintenance) {
    await terrainRepo.updateTerrainStatus(terrainId, TerrainStatus.maintenance);
  }
  for (final terrainId in toRestore) {
    await terrainRepo.updateTerrainStatus(terrainId, TerrainStatus.playable);
  }
}
