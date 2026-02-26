// filepath: lib/data/services/firebase_maintenance_service.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tenniscourtcare/data/models/maintenance_model.dart';
import 'package:tenniscourtcare/domain/entities/maintenance.dart';
import 'package:tenniscourtcare/domain/entities/sync_status.dart';

class FirebaseMaintenanceService {
  final FirebaseFirestore _firestore;

  FirebaseMaintenanceService(this._firestore);

  static const String _collectionPath = 'maintenances';

  /// Upload une maintenance vers Firestore
  Future<void> uploadMaintenanceToFirestore(Maintenance maintenance) async {
    try {
      final model = MaintenanceModel.fromDomain(maintenance);
      // Ensure we have an ID for the document path
      String docId;
      if (maintenance.firebaseId != null) {
        docId = maintenance.firebaseId!;
      } else if (maintenance.id != null) {
        docId = 'maintenance_${maintenance.id}';
      } else {
        throw Exception('Cannot upload maintenance without ID or Firebase ID');
      }

      await _firestore
          .collection(_collectionPath)
          .doc(docId)
          .set(model.toJson(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to upload maintenance: $e');
    }
  }

  /// Écouter les changements Firestore (stream temps réel)
  Stream<List<Maintenance>> watchMaintenances() {
    return _firestore
        .collection(_collectionPath)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            final model = MaintenanceModel.fromJson(data);
            return model.toDomain();
          }).toList();
        })
        .handleError((e) {
          debugPrint('Error watching maintenances: $e');
          return <Maintenance>[];
        });
  }

  /// Récupérer les maintenances non-syncés
  Future<List<Maintenance>> getUnsyncedMaintenances(
    List<Maintenance> allMaintenances,
  ) async {
    return allMaintenances
        .where(
          (m) =>
              m.syncStatus == SyncStatus.local ||
              m.syncStatus == SyncStatus.error,
        )
        .toList();
  }

  /// Marquer une maintenance comme syncé
  Future<void> markAsSynced(int maintenanceId) async {
    // Ceci sera utilisé par le repository après sync réussi
  }

  /// Marquer une maintenance comme erreur de sync
  Future<void> markAsSyncError(int maintenanceId) async {
    // Ceci sera utilisé par le repository après erreur de sync
  }
}
