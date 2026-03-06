import 'package:flutter_test/flutter_test.dart';
import 'package:tenniscourtcare/domain/entities/maintenance.dart';
import 'package:tenniscourtcare/domain/logic/maintenance_scheduler.dart';

void main() {
  group('MaintenanceScheduler', () {
    final now = DateTime(2023, 10, 27, 10, 0); // Oct 27, 2023, 10:00 AM

    Maintenance createMaintenance(
      int id,
      int terrainId,
      DateTime date,
      int startHour,
      int durationMinutes,
    ) {
      return Maintenance(
        id: id,
        terrainId: terrainId,
        date: date.millisecondsSinceEpoch,
        type: 'Test',
        isPlanned: true,
        startHour: startHour,
        durationMinutes: durationMinutes,
        sacsMantoUtilises: 0,
        sacsSottomantoUtilises: 0,
        sacsSiliceUtilises: 0,
        createdBy: 'test',
        modifiedBy: 'test',
      );
    }

    test('terrainsToSetInMaintenance returns correct terrain IDs', () {
      final plannedMaintenances = [
        createMaintenance(1, 101, now, 8, 60),
        createMaintenance(2, 102, now, 9, 90),
        createMaintenance(3, 103, now, 11, 60),
      ];

      final result = MaintenanceScheduler.terrainsToSetInMaintenance(
        plannedMaintenances,
        now,
      );

      expect(result, contains(102));
      expect(result, isNot(contains(101)));
      expect(result, isNot(contains(103)));
    });

    test('terrainsToRestoreToPlayable returns correct terrain IDs', () {
      final plannedMaintenances = [createMaintenance(2, 102, now, 9, 90)];

      final currentMaintenanceTerrainIds = [101, 102, 104];

      final result = MaintenanceScheduler.terrainsToRestoreToPlayable(
        plannedMaintenances,
        currentMaintenanceTerrainIds,
        now,
      );

      expect(result, contains(101));
      expect(result, contains(104));
      expect(result, isNot(contains(102)));
    });
  });
}
