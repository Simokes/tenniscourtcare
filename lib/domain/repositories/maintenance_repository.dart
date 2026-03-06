import '../entities/maintenance.dart';

abstract class MaintenanceRepository {
  Future<String> addMaintenance(Maintenance maintenance);
  Future<void> updateMaintenance(Maintenance maintenance);
  Future<void> deleteMaintenance(String firebaseId);
  Future<List<Maintenance>> getAllMaintenances();
  Future<Maintenance?> getMaintenanceById(int id);
  Stream<List<Maintenance>> watchPlannedMaintenances();
  Future<void> markAsCompleted({
    required String firebaseId,
    required Maintenance completed,
  });
}
