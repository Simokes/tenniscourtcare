// filepath: lib/data/services/firebase_stock_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tenniscourtcare/data/models/stock_item_model.dart';
import 'package:tenniscourtcare/domain/entities/stock_item.dart';
import 'package:tenniscourtcare/domain/entities/sync_status.dart';

class FirebaseStockService {
  final FirebaseFirestore _firestore;

  FirebaseStockService(this._firestore);

  static const String _collectionPath = 'stocks';

  /// Upload un stock item vers Firestore
  Future<void> uploadStockItemToFirestore(StockItem stockItem) async {
    try {
      final model = StockItemModel.fromDomain(stockItem);
      String docId;
      if (stockItem.firebaseId != null) {
        docId = stockItem.firebaseId!;
      } else if (stockItem.id != null) {
        docId = 'stock_${stockItem.id}';
      } else {
        throw Exception('Cannot upload stock item without ID or Firebase ID');
      }

      await _firestore
          .collection(_collectionPath)
          .doc(docId)
          .set(model.toJson(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to upload stock item: $e');
    }
  }

  /// Écouter les changements Firestore (stream temps réel)
  Stream<List<StockItem>> watchStock() {
    return _firestore
        .collection(_collectionPath)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final model = StockItemModel.fromJson(data);
        return model.toDomain();
      }).toList();
    }).handleError((e) {
      print('Error watching stock items: $e');
      return <StockItem>[];
    });
  }

  /// Récupérer les items de stock non-syncés
  Future<List<StockItem>> getUnsyncedStockItems(List<StockItem> allItems) async {
    return allItems
        .where((i) => i.syncStatus == SyncStatus.local || i.syncStatus == SyncStatus.error)
        .toList();
  }

  /// Marquer un stock item comme syncé
  Future<void> markAsSynced(int itemId) async {
    // Ceci sera utilisé par le repository après sync réussi
  }

  /// Marquer un stock item comme erreur de sync
  Future<void> markAsSyncError(int itemId) async {
    // Ceci sera utilisé par le repository après erreur de sync
  }
}
