// filepath: lib/data/repositories/maintenance_repository_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:tenniscourtcare/data/database/app_database.dart';
import 'package:tenniscourtcare/data/mappers/maintenance_mapper.dart';
import 'package:tenniscourtcare/domain/entities/maintenance.dart';
import 'package:tenniscourtcare/domain/models/repository_exception.dart';
import 'package:tenniscourtcare/domain/repositories/maintenance_repository.dart';

class MaintenanceRepositoryImpl implements MaintenanceRepository {
  const MaintenanceRepositoryImpl({
    required AppDatabase db,
    required FirebaseFirestore fs,
  })  : _db = db,
        _fs = fs;

  final AppDatabase _db;
  final FirebaseFirestore _fs;

  @override
  Future<String> addMaintenance(Maintenance maintenance) async {
    try {
      final docRef = await _fs
          .collection('maintenance')
          .add(MaintenanceMapper.toFirestore(maintenance));
      return docRef.id;
    } on FirebaseException catch (e) {
      debugPrint('❌ MaintenanceRepository: Failed to add maintenance: ${e.message}');
      throw RepositoryException('Failed to add maintenance: ${e.message}', cause: e);
    }
  }

  @override
  Future<void> updateMaintenance(Maintenance maintenance) async {
    if (maintenance.firebaseId == null) {
      throw const RepositoryException('Cannot update maintenance without a firebaseId');
    }

    try {
      await _fs
          .collection('maintenance')
          .doc(maintenance.firebaseId)
          .update(MaintenanceMapper.toFirestore(maintenance));
    } on FirebaseException catch (e) {
      debugPrint('❌ MaintenanceRepository: Failed to update maintenance: ${e.message}');
      throw RepositoryException('Failed to update maintenance: ${e.message}', cause: e);
    }
  }

  @override
  Future<void> deleteMaintenance(String firebaseId) async {
    try {
      await _fs.collection('maintenance').doc(firebaseId).delete();
    } on FirebaseException catch (e) {
      debugPrint('❌ MaintenanceRepository: Failed to delete maintenance: ${e.message}');
      throw RepositoryException('Failed to delete maintenance: ${e.message}', cause: e);
    }
  }

  Future<List<Maintenance>> getMaintenancesForTerrain(int terrainId) async {
    return _db.getMaintenancesForTerrain(terrainId);
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
