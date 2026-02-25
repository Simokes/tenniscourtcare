import '../../domain/entities/maintenance.dart';
import '../../domain/entities/sync_status.dart';
import '../../domain/repositories/maintenance_repository.dart';
import '../database/app_database.dart';
import '../services/firebase_sync_service.dart';

class MaintenanceRepositoryImpl implements MaintenanceRepository {
  final AppDatabase _db;
  final FirebaseSyncService _firebaseService;

  MaintenanceRepositoryImpl(this._db, this._firebaseService);

  @override
  Future<int> addMaintenance(Maintenance maintenance) async {
    final localMaintenance = maintenance.copyWith(
      syncStatus: SyncStatus.local,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final id = await _db.insertMaintenance(localMaintenance);

    _syncMaintenanceToFirebase(localMaintenance.copyWith(id: id));

    return id;
  }

  @override
  Future<bool> updateMaintenance(Maintenance maintenance) async {
    final updatedMaintenance = maintenance.copyWith(
      syncStatus: SyncStatus.local,
      updatedAt: DateTime.now(),
    );
    final result = await _db.updateMaintenance(updatedMaintenance);

    _syncMaintenanceToFirebase(updatedMaintenance);

    return result;
  }

  @override
  Future<bool> deleteMaintenance(int id) async {
    final result = await _db.deleteMaintenance(id);
    return result;
  }

  @override
  Future<List<Maintenance>> getAllMaintenances() async {
    return await _db.getAllMaintenances();
  }

  @override
  Future<Maintenance?> getMaintenanceById(int id) async {
    return await _db.getMaintenanceById(id);
  }

  Future<void> _syncMaintenanceToFirebase(Maintenance maintenance) async {
    try {
      await _firebaseService.maintenanceService.uploadMaintenanceToFirestore(maintenance);
    } catch (e) {
      print('Failed to sync maintenance: $e');
    }
  }
}
