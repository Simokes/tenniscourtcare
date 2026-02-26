// filepath: lib/data/repositories/maintenance_repository_impl.dart

import 'package:drift/drift.dart';
import 'package:tenniscourtcare/data/database/app_database.dart';
import 'package:tenniscourtcare/domain/entities/maintenance.dart';
import 'package:tenniscourtcare/domain/entities/sync_status.dart';
import 'package:tenniscourtcare/domain/repositories/maintenance_repository.dart';

class MaintenanceRepositoryImpl implements MaintenanceRepository {
  final AppDatabase _db;

  MaintenanceRepositoryImpl(this._db);

  @override
  Future<int> addMaintenance(Maintenance maintenance) async {
    final localMaintenance = maintenance.copyWith(
      syncStatus: SyncStatus.local,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return _db.insertMaintenance(localMaintenance);
  }

  @override
  Future<bool> updateMaintenance(Maintenance maintenance) async {
    final updatedMaintenance = maintenance.copyWith(
      syncStatus: SyncStatus.local,
      updatedAt: DateTime.now(),
    );

    // Créer MaintenancesCompanion manuellement
    final companion = MaintenancesCompanion(
      id: updatedMaintenance.id != null
          ? Value(updatedMaintenance.id!)
          : const Value.absent(),
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
    return result > 0;
  }

  @override
  Future<bool> deleteMaintenance(int id) async {
    final result = await _db.deleteMaintenance(id);
    return result > 0;
  }

  Future<List<Maintenance>> getMaintenancesForTerrain(int terrainId) async {
    return await _db.getMaintenancesForTerrain(terrainId);
  }

  @override
  Future<Maintenance?> getMaintenanceById(int id) async {
    return _db.getMaintenanceById(id);
  }

  @override
  Future<List<Maintenance>> getAllMaintenances() async {
    // Récupérer toutes les maintenances de tous les terrains
    // À optimiser en Phase 8 avec une vraie requête
    // Pour l'instant on retourne une liste vide pour éviter les erreurs de compilation
    // si la méthode n'existe pas dans la DB, ou on utilise watchAllMaintenances si disponible.
    // Le user snippet met une liste vide. Je vais essayer de remettre watchAllMaintenances().first
    // si c'est ce qui est attendu, mais le snippet est explicite sur "allMaintenances = []".
    // Je vais suivre le snippet pour être sûr.
    return [];
  }
}
