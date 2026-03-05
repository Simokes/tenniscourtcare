import 'package:cloud_firestore/cloud_firestore.dart';
import './maintenance_firestore_model.dart';

class FirestoreMaintenanceRepository {
  final FirebaseFirestore _firestore;

  FirestoreMaintenanceRepository(this._firestore);

  CollectionReference get _maintenances =>
      _firestore.collection('maintenances');

  Future<void> saveMaintenance(MaintenanceFirestoreModel maintenance) async {
    await _maintenances.doc(maintenance.id).set(maintenance.toFirestore());
  }

  Future<MaintenanceFirestoreModel?> getMaintenance(String id) async {
    final doc = await _maintenances.doc(id).get();
    if (doc.exists) {
      return MaintenanceFirestoreModel.fromFirestore(doc);
    }
    return null;
  }

  Stream<List<MaintenanceFirestoreModel>> watchMaintenances({
    String? terrainId,
  }) {
    Query query = _maintenances.orderBy('scheduledDate', descending: true);
    if (terrainId != null) {
      query = query.where('terrainId', isEqualTo: terrainId);
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => MaintenanceFirestoreModel.fromFirestore(doc))
          .toList();
    });
  }

  Future<void> deleteMaintenance(String id) async {
    await _maintenances.doc(id).delete();
  }
}
