import 'package:cloud_firestore/cloud_firestore.dart';
import '../../firestore/models/stock_firestore_model.dart';

class FirestoreStockRepository {
  final FirebaseFirestore _firestore;

  FirestoreStockRepository(this._firestore);

  CollectionReference get _stock => _firestore.collection('stock');

  Future<void> saveStockItem(StockFirestoreModel item) async {
    await _stock.doc(item.id).set(item.toFirestore());
  }

  Future<StockFirestoreModel?> getStockItem(String id) async {
    final doc = await _stock.doc(id).get();
    if (doc.exists) {
      return StockFirestoreModel.fromFirestore(doc);
    }
    return null;
  }

  Stream<List<StockFirestoreModel>> watchStockItems() {
    return _stock.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => StockFirestoreModel.fromFirestore(doc)).toList();
    });
  }

  Future<void> deleteStockItem(String id) async {
    await _stock.doc(id).delete();
  }
}
