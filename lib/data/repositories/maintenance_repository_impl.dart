// filepath: lib/data/repositories/maintenance_repository_impl.dart

import 'package:tenniscourtcare/data/database/app_database.dart';
import 'package:tenniscourtcare/data/services/firebase_sync_service.dart';
import 'package:tenniscourtcare/domain/entities/maintenance.dart';
import 'package:tenniscourtcare/domain/entities/sync_status.dart';
import 'package:tenniscourtcare/domain/repositories/maintenance_repository.dart';

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

    final result = await _db.updateMaintenance(
      updatedMaintenance.toCompanion(includeId: true)
    );

    _syncMaintenanceToFirebase(updatedMaintenance);

    return result > 0;
  }

  @override
  Future<bool> deleteMaintenance(int id) async {
    final result = await _db.deleteMaintenance(id);
    return result > 0;
  }

  // Not strictly part of interface but good to have if needed by new providers or legacy
  // However interface defines getAllMaintenances
  @override
  Future<List<Maintenance>> getAllMaintenances() async {
    return await _db.watchAllMaintenances().first;
  }

  @override
  Future<Maintenance?> getMaintenanceById(int id) async {
    return _db.getMaintenanceById(id);
  }

  Future<void> _syncMaintenanceToFirebase(Maintenance maintenance) async {
    try {
      await _firebaseService.maintenanceService.uploadMaintenanceToFirestore(maintenance);
    } catch (e) {
      print('Failed to sync maintenance: $e');
    }
  }
}
