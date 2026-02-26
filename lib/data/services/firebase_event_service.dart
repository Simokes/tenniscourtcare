// filepath: lib/data/services/firebase_event_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tenniscourtcare/data/models/app_event_model.dart';
import 'package:tenniscourtcare/domain/entities/app_event.dart';
import 'package:tenniscourtcare/domain/entities/sync_status.dart';

class FirebaseEventService {
  final FirebaseFirestore _firestore;

  FirebaseEventService(this._firestore);

  static const String _collectionPath = 'events';

  /// Upload un event vers Firestore
  Future<void> uploadEventToFirestore(AppEvent event) async {
    try {
      final model = AppEventModel.fromDomain(event);
      String docId;
      if (event.firebaseId != null) {
        docId = event.firebaseId!;
      } else if (event.id != null) {
        docId = 'event_${event.id}';
      } else {
        throw Exception('Cannot upload event without ID or Firebase ID');
      }

      await _firestore
          .collection(_collectionPath)
          .doc(docId)
          .set(model.toJson(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to upload event: $e');
    }
  }

  /// Écouter les changements Firestore (stream temps réel)
  Stream<List<AppEvent>> watchEvents() {
    return _firestore
        .collection(_collectionPath)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final model = AppEventModel.fromJson(data);
        return model.toDomain();
      }).toList();
    }).handleError((e) {
      print('Error watching events: $e');
      return <AppEvent>[];
    });
  }

  /// Récupérer les events non-syncés
  Future<List<AppEvent>> getUnsyncedEvents(List<AppEvent> allEvents) async {
    return allEvents
        .where((e) => e.syncStatus == SyncStatus.local || e.syncStatus == SyncStatus.error)
        .toList();
  }

  /// Marquer un event comme syncé
  Future<void> markAsSynced(int eventId) async {
    // Ceci sera utilisé par le repository après sync réussi
  }

  /// Marquer un event comme erreur de sync
  Future<void> markAsSyncError(int eventId) async {
    // Ceci sera utilisé par le repository après erreur de sync
  }
}
