import 'package:cloud_firestore/cloud_firestore.dart';
import './terrain_firestore_model.dart';

class FirestoreTerrainRepository {
  final FirebaseFirestore _firestore;

  FirestoreTerrainRepository(this._firestore);

  CollectionReference get _terrains => _firestore.collection('terrains');

  Future<void> saveTerrain(TerrainFirestoreModel terrain) async {
    await _terrains.doc(terrain.id).set(terrain.toFirestore());
  }

  Future<TerrainFirestoreModel?> getTerrain(String id) async {
    final doc = await _terrains.doc(id).get();
    if (doc.exists) {
      return TerrainFirestoreModel.fromFirestore(doc);
    }
    return null;
  }

  Stream<List<TerrainFirestoreModel>> watchTerrains() {
    return _terrains.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => TerrainFirestoreModel.fromFirestore(doc))
          .toList();
    });
  }

  Future<void> deleteTerrain(String id) async {
    await _terrains.doc(id).delete();
  }
}
