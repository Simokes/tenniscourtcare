import '../entities/maintenance.dart';

abstract class MaintenanceRepository {
  Future<void> addMaintenance(Maintenance maintenance);
  Future<void> updateMaintenance(Maintenance maintenance);
  Future<void> deleteMaintenance(String firebaseId);
  Future<List<Maintenance>> getAllMaintenances();
  Future<Maintenance?> getMaintenanceById(int id);
}
