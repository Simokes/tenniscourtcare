// filepath: lib/data/repositories/maintenance_repository_impl.dart

import 'package:drift/drift.dart';
import 'package:tenniscourtcare/data/database/app_database.dart';
import 'package:tenniscourtcare/data/services/firebase_maintenance_service.dart';
import 'package:tenniscourtcare/domain/entities/maintenance.dart';
import 'package:tenniscourtcare/domain/entities/sync_status.dart';
import 'package:tenniscourtcare/domain/repositories/maintenance_repository.dart';

class MaintenanceRepositoryImpl implements MaintenanceRepository {
  final AppDatabase _db;
  final FirebaseMaintenanceService _firebaseService;

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

    // Créer MaintenancesCompanion manuellement
    final companion = MaintenancesCompanion(
      id: updatedMaintenance.id != null ? Value(updatedMaintenance.id!) : const Value.absent(),
      terrainId: Value(updatedMaintenance.terrainId),
      type: Value(updatedMaintenance.type),
      commentaire: Value(updatedMaintenance.commentaire),
      date: Value(updatedMaintenance.date),
      sacsMantoUtilises: Value(updatedMaintenance.sacsMantoUtilises),
      sacsSottomantoUtilises: Value(updatedMaintenance.sacsSottomantoUtilises),
      sacsSiliceUtilises: Value(updatedMaintenance.sacsSiliceUtilises),
      imagePath: Value(updatedMaintenance.imagePath),
      syncStatus: Value(updatedMaintenance.syncStatus.name),
      createdAt: Value(updatedMaintenance.createdAt),
      updatedAt: Value(updatedMaintenance.updatedAt),
      firebaseId: Value(updatedMaintenance.firebaseId),
      createdBy: Value(updatedMaintenance.createdBy),
      modifiedBy: Value(updatedMaintenance.modifiedBy),
    );

    final result = await _db.updateMaintenance(companion);
    _syncMaintenanceToFirebase(updatedMaintenance);

    return result > 0;
  }

  @override
  Future<bool> deleteMaintenance(int id) async {
    final result = await _db.deleteMaintenance(id);
    return result > 0;
  }

  @override
  Future<List<Maintenance>> getMaintenancesForTerrain(int terrainId) async {
    return await _db.getMaintenancesForTerrain(terrainId);
  }

  @override
  Future<Maintenance?> getMaintenanceById(int id) async {
    return _db.getMaintenanceById(id);
  }

  Future<void> _syncMaintenanceToFirebase(Maintenance maintenance) async {
    try {
      await _firebaseService.uploadMaintenanceToFirestore(maintenance);
    } catch (e) {
      print('Failed to sync maintenance: $e');
    }
  }
}
