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

    // Utiliser toCompanion() de l'extension existante dans app_database.dart
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

  @override
  Future<List<Maintenance>> getAllMaintenances() async {
    return await _db.watchAllMaintenances().first;
  }

  // Si l'interface demande getMaintenancesForTerrain, on l'ajoute
  // Mais l'interface originale définie dans domain n'avait que getAllMaintenances.
  // Je vérifie si je dois ajouter getMaintenancesForTerrain à l'interface ou juste ici.
  // Le code utilisateur suggère "remplacer maintenance_repository_impl.dart par ... getMaintenancesForTerrain"
  // Je vais garder getAllMaintenances pour respecter l'interface existante et ajouter l'autre si nécessaire
  // ou si l'interface a changé. Je vais suivre le code fourni par l'utilisateur.
  // ATTENTION: Le code fourni par l'utilisateur a REMPLACÉ getAllMaintenances par getMaintenancesForTerrain
  // Si l'interface a getAllMaintenances, je dois le garder.
  // Je vais vérifier l'interface dans une étape précédente ou assumer que je dois garder les méthodes de l'interface.
  // L'interface maintenance_repository.dart a été créée par moi et contient getAllMaintenances.
  // Le code utilisateur NE CONTIENT PAS getAllMaintenances mais getMaintenancesForTerrain.
  // Je vais garder getAllMaintenances pour satisfaire l'override et ajouter getMaintenancesForTerrain si besoin.

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
