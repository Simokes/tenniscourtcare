import 'package:tenniscourtcare/domain/entities/maintenance.dart';

class MaintenanceScheduler {
  /// Returns terrainIds that should be set to TerrainStatus.maintenance NOW
  static List<int> terrainsToSetInMaintenance(
    List<Maintenance> plannedMaintenances,
    DateTime now,
  ) {
    return plannedMaintenances
        .where((m) {
          final maintenanceStart = DateTime(
            DateTime.fromMillisecondsSinceEpoch(m.date).year,
            DateTime.fromMillisecondsSinceEpoch(m.date).month,
            DateTime.fromMillisecondsSinceEpoch(m.date).day,
            m.startHour,
          );
          final maintenanceEnd = maintenanceStart.add(
            Duration(minutes: m.durationMinutes),
          );
          return now.isAfter(maintenanceStart) && now.isBefore(maintenanceEnd);
        })
        .map((m) => m.terrainId)
        .toList();
  }

  /// Returns terrainIds whose maintenance window has passed
  /// and should be restored to playable
  static List<int> terrainsToRestoreToPlayable(
    List<Maintenance> plannedMaintenances,
    List<int> currentMaintenanceTerrainIds,
    DateTime now,
  ) {
    final activeTerrainIds = terrainsToSetInMaintenance(
      plannedMaintenances,
      now,
    ).toSet();
    return currentMaintenanceTerrainIds
        .where((id) => !activeTerrainIds.contains(id))
        .toList();
  }
}
