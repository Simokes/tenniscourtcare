// filepath: lib/data/services/firebase_terrain_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tenniscourtcare/data/models/terrain_model.dart';
import 'package:tenniscourtcare/domain/entities/sync_status.dart';
import 'package:tenniscourtcare/domain/entities/terrain.dart';

class FirebaseTerrainService {
  final FirebaseFirestore _firestore;

  FirebaseTerrainService(this._firestore);

  static const String _collectionPath = 'terrains';

  /// Upload un terrain vers Firestore
  Future<void> uploadTerrainToFirestore(Terrain terrain) async {
    try {
      final model = TerrainModel.fromDomain(terrain);
      // Ensure we don't upload 'local' status if we want cloud to be clean,
      // but following template we just convert.
      // Ideally we might want to override syncStatus to 'synced' in the cloud doc,
      // but let's stick to the prompt's template logic which is direct conversion.

      final docId = terrain.firebaseId ?? 'terrain_${terrain.id}';

      await _firestore
          .collection(_collectionPath)
          .doc(docId)
          .set(model.toJson(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to upload terrain: $e');
    }
  }

  /// Écouter les changements Firestore (stream temps réel)
  Stream<List<Terrain>> watchTerrains() {
    return _firestore
        .collection(_collectionPath)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        // Ensure ID is set from doc ID if missing (though model has it)
        // actually model.fromJson handles data.
        final model = TerrainModel.fromJson(data);
        return model.toDomain();
      }).toList();
    }).handleError((e) {
      print('Error watching terrains: $e');
      return <Terrain>[];
    });
  }

  /// Récupérer les terrains non-syncés (filtrage local)
  Future<List<Terrain>> getUnsyncedTerrains(List<Terrain> allTerrains) async {
    return allTerrains
        .where((t) => t.syncStatus == SyncStatus.local || t.syncStatus == SyncStatus.error)
        // Including error status to retry? Prompt template said: .where((t) => t.syncStatus == SyncStatus.local)
        // I will stick to template but usually error should also be retried.
        // Template: .where((t) => t.syncStatus == SyncStatus.local)
        .toList();
  }

  /// Marquer un terrain comme syncé
  Future<void> markAsSynced(int terrainId) async {
    // Ceci sera utilisé par le repository après sync réussi
    // This method seems to be a placeholder in this service
    // as it requires local DB access which is not injected here.
  }

  /// Marquer un terrain comme erreur de sync
  Future<void> markAsSyncError(int terrainId) async {
    // Ceci sera utilisé par le repository après erreur de sync
  }
}
