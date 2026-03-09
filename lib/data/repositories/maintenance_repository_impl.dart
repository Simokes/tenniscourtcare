// filepath: lib/data/repositories/maintenance_repository_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:tenniscourtcare/data/database/app_database.dart';
import 'package:tenniscourtcare/data/mappers/maintenance_mapper.dart';
import 'package:tenniscourtcare/domain/entities/maintenance.dart';
import 'package:tenniscourtcare/domain/entities/stock_item.dart';
import 'package:tenniscourtcare/domain/entities/terrain.dart';
import 'package:tenniscourtcare/domain/models/repository_exception.dart';
import 'package:tenniscourtcare/domain/repositories/maintenance_repository.dart';
import 'package:tenniscourtcare/domain/repositories/stock_repository.dart';
import 'package:tenniscourtcare/domain/repositories/terrain_repository.dart';
import 'package:drift/drift.dart' as drift;

class MaintenanceRepositoryImpl implements MaintenanceRepository {
  const MaintenanceRepositoryImpl({
    required AppDatabase db,
    required FirebaseFirestore fs,
    required TerrainRepository terrainRepository,
    required StockRepository stockRepository,
  }) : _db = db,
       _fs = fs,
       _terrainRepository = terrainRepository,
       _stockRepository = stockRepository;

  final AppDatabase _db;
  final FirebaseFirestore _fs;
  final TerrainRepository _terrainRepository;
  final StockRepository _stockRepository;

  /// Deduit les sacs utilises du stock Firestore.
  /// Appelee apres une ecriture maintenance reussie.
  /// Lance une RepositoryException si le stock est insuffisant ou introuvable.
  Future<void> _deductStock(Maintenance maintenance) async {
    if (maintenance.sacsMantoUtilises == 0 &&
        maintenance.sacsSottomantoUtilises == 0 &&
        maintenance.sacsSiliceUtilises == 0) {
      return;
    }

    final stockItems = await _db.watchAllStockItems().first;

    Future<void> deduct(String name, int used) async {
      if (used <= 0) return;
      final StockItem item;
      try {
        item = stockItems.firstWhere(
          (i) => i.name.toLowerCase() == name.toLowerCase(),
        );
      } catch (_) {
        throw RepositoryException(
          "Article de stock '$name' introuvable dans le stock.",
        );
      }
      if (item.quantity < used) {
        throw RepositoryException(
          'Stock insuffisant pour $name (${item.quantity} disponibles, $used requis).',
        );
      }
      if (item.firebaseId == null) {
        throw RepositoryException(
          "Stock '$name' sans firebaseId, impossible de mettre a jour Firestore.",
        );
      }
      await _stockRepository.updateStockItem(
        item.copyWith(
          quantity: item.quantity - used,
          updatedAt: DateTime.now(),
        ),
      );
    }

    await deduct('Manto', maintenance.sacsMantoUtilises);
    await deduct('Sottomanto', maintenance.sacsSottomantoUtilises);
    await deduct('Silice', maintenance.sacsSiliceUtilises);
  }

  /// Restaure les sacs dans le stock Firestore.
  /// Appelee apres suppression d'une maintenance completee.
  Future<void> _restoreStock(Maintenance maintenance) async {
    if (maintenance.sacsMantoUtilises == 0 &&
        maintenance.sacsSottomantoUtilises == 0 &&
        maintenance.sacsSiliceUtilises == 0) {
      return;
    }

    final stockItems = await _db.watchAllStockItems().first;

    Future<void> restore(String name, int used) async {
      if (used <= 0) return;
      final matches = stockItems.where(
        (i) => i.name.toLowerCase() == name.toLowerCase(),
      );
      if (matches.isEmpty) {
        debugPrint(
          'WARNING MaintenanceRepository: Stock "$name" introuvable lors de la restauration.',
        );
        return;
      }
      final item = matches.first;
      if (item.firebaseId == null) {
        debugPrint(
          'WARNING MaintenanceRepository: Stock "$name" sans firebaseId, restauration ignoree.',
        );
        return;
      }
      await _stockRepository.updateStockItem(
        item.copyWith(
          quantity: item.quantity + used,
          updatedAt: DateTime.now(),
        ),
      );
    }

    await restore('Manto', maintenance.sacsMantoUtilises);
    await restore('Sottomanto', maintenance.sacsSottomantoUtilises);
    await restore('Silice', maintenance.sacsSiliceUtilises);
  }

  /// Verifie que le stock est suffisant sans le modifier.
  /// Lance une RepositoryException si insuffisant.
  void _checkStockSufficiency(
    List<StockItem> stockItems,
    Maintenance maintenance,
  ) {
    void check(String name, int used) {
      if (used <= 0) return;
      final matches = stockItems.where(
        (i) => i.name.toLowerCase() == name.toLowerCase(),
      );
      if (matches.isEmpty) {
        throw RepositoryException("Article de stock '$name' introuvable.");
      }
      final item = matches.first;
      if (item.quantity < used) {
        throw RepositoryException(
          'Stock insuffisant pour $name (${item.quantity} disponibles, $used requis).',
        );
      }
    }

    check('Manto', maintenance.sacsMantoUtilises);
    check('Sottomanto', maintenance.sacsSottomantoUtilises);
    check('Silice', maintenance.sacsSiliceUtilises);
  }

  @override
  Future<String> addMaintenance(Maintenance maintenance) async {
    try {
      // Verifier le stock AVANT d'ecrire dans Firestore (maintenance immediate uniquement)
      if (!maintenance.isPlanned) {
        final stockItems = await _db.watchAllStockItems().first;
        _checkStockSufficiency(stockItems, maintenance);
      }

      final docRef = await _fs
          .collection('maintenance')
          .add(MaintenanceMapper.toFirestore(maintenance));

      if (!maintenance.isPlanned) {
        // Deduire le stock dans Firestore
        await _deductStock(maintenance);
        // Terrain retourne jouable
        await _terrainRepository.updateTerrainStatus(
          maintenance.terrainId,
          TerrainStatus.playable,
        );
      }

      return docRef.id;
    } on RepositoryException {
      rethrow;
    } on FirebaseException catch (e) {
      debugPrint(
        'ERROR MaintenanceRepository: Failed to add maintenance: ${e.message}',
      );
      throw RepositoryException(
        'Failed to add maintenance: ${e.message}',
        cause: e,
      );
    } catch (e) {
      debugPrint('ERROR MaintenanceRepository: addMaintenance error: $e');
      throw RepositoryException('Failed to add maintenance: $e');
    }
  }

  @override
  Future<void> updateMaintenance(Maintenance maintenance) async {
    if (maintenance.firebaseId == null) {
      throw const RepositoryException(
        'Cannot update maintenance without a firebaseId',
      );
    }

    try {
      await _fs
          .collection('maintenance')
          .doc(maintenance.firebaseId)
          .update(MaintenanceMapper.toFirestore(maintenance));
    } on FirebaseException catch (e) {
      debugPrint(
        'ERROR MaintenanceRepository: Failed to update maintenance: ${e.message}',
      );
      throw RepositoryException(
        'Failed to update maintenance: ${e.message}',
        cause: e,
      );
    }
  }

  @override
  Future<void> deleteMaintenance(String firebaseId) async {
    Maintenance? maintenance;
    try {
      maintenance = await _db.getMaintenanceByFirebaseId(firebaseId);
    } catch (e) {
      debugPrint(
        'WARNING MaintenanceRepository: Could not fetch maintenance from Drift before delete: $e',
      );
    }

    try {
      await _fs.collection('maintenance').doc(firebaseId).delete();
    } on FirebaseException catch (e) {
      debugPrint(
        'ERROR MaintenanceRepository: Failed to delete maintenance from Firestore: ${e.message}',
      );
      throw RepositoryException(
        'Failed to delete maintenance: ${e.message}',
        cause: e,
      );
    }

    try {
      if (maintenance != null && !maintenance.isPlanned) {
        // Restaurer le stock dans Firestore (la maintenance etait completee, stock avait ete decompte)
        await _restoreStock(maintenance);
      } else if (maintenance != null && maintenance.isPlanned) {
        // Maintenance planifiee : stock jamais decompte, terrain redevient jouable
        await _terrainRepository.updateTerrainStatus(
          maintenance.terrainId,
          TerrainStatus.playable,
        );
      }
      await _db.deleteMaintenanceByFirebaseId(firebaseId);
    } catch (e) {
      debugPrint(
        'ERROR MaintenanceRepository: Error during Drift deletion or stock restore: $e',
      );
      rethrow;
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
    return [];
  }

  @override
  Stream<List<Maintenance>> watchPlannedMaintenances() {
    final query = _db.select(_db.maintenances)
      ..where((t) => t.isPlanned.equals(true))
      ..orderBy([
        (t) => drift.OrderingTerm(
          expression: t.date,
          mode: drift.OrderingMode.asc,
        ),
      ]);
    return query.watch().map((rows) => rows.map((r) => r.toDomain()).toList());
  }

  @override
  Future<void> markAsCompleted({
    required String firebaseId,
    required Maintenance completed,
  }) async {
    final updatedMaintenance = completed.copyWith(isPlanned: false);

    try {
      await _fs
          .collection('maintenance')
          .doc(firebaseId)
          .update(MaintenanceMapper.toFirestore(updatedMaintenance));

      // Deduire le stock dans Firestore maintenant que la maintenance est executee
      await _deductStock(updatedMaintenance);

      await _terrainRepository.updateTerrainStatus(
        updatedMaintenance.terrainId,
        TerrainStatus.playable,
      );
    } on RepositoryException {
      rethrow;
    } on FirebaseException catch (e) {
      debugPrint(
        'ERROR MaintenanceRepository: Failed to mark maintenance as completed: ${e.message}',
      );
      throw RepositoryException(
        'Failed to mark maintenance as completed: ${e.message}',
        cause: e,
      );
    } catch (e) {
      debugPrint(
        'ERROR MaintenanceRepository: markAsCompleted error: $e',
      );
      throw RepositoryException('Failed to mark maintenance as completed: $e');
    }
  }
}
