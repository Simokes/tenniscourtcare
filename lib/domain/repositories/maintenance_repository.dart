import '../entities/maintenance.dart';

abstract class MaintenanceRepository {
  Future<int> addMaintenance(Maintenance maintenance);
  Future<bool> updateMaintenance(Maintenance maintenance);
  Future<bool> deleteMaintenance(int id);
  Future<List<Maintenance>> getAllMaintenances();
  Future<Maintenance?> getMaintenanceById(int id);
}
