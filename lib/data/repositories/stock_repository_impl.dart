// filepath: lib/data/repositories/stock_repository_impl.dart

import 'package:tenniscourtcare/data/database/app_database.dart';
import 'package:tenniscourtcare/data/services/firebase_sync_service.dart';
import 'package:tenniscourtcare/domain/entities/stock_item.dart';
import 'package:tenniscourtcare/domain/entities/sync_status.dart';
import 'package:tenniscourtcare/domain/repositories/stock_repository.dart';

class StockRepositoryImpl implements StockRepository {
  final AppDatabase _db;
  final FirebaseSyncService _firebaseService;

  StockRepositoryImpl(this._db, this._firebaseService);

  @override
  Future<int> addStockItem(StockItem item) async {
    final localItem = item.copyWith(
      syncStatus: SyncStatus.local,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final id = await _db.insertStockItem(localItem);
    _syncStockToFirebase(localItem.copyWith(id: id));

    return id;
  }

  @override
  Future<bool> updateStockItem(StockItem item) async {
    final updatedItem = item.copyWith(
      syncStatus: SyncStatus.local,
      updatedAt: DateTime.now(),
    );

    final result = await _db.updateStockItem(updatedItem);
    _syncStockToFirebase(updatedItem);

    return result;  // updateStockItem() retourne déjà bool
  }

  @override
  Future<bool> deleteStockItem(int id) async {
    final result = await _db.deleteStockItem(id);
    return result > 0;
  }

  @override
  Future<List<StockItem>> getAllStockItems() async {
    return await _db.watchAllStockItems().first;
  }

  @override
  Future<StockItem?> getStockItemById(int id) async {
    final items = await _db.watchAllStockItems().first;
    try {
      return items.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> _syncStockToFirebase(StockItem item) async {
    try {
      await _firebaseService.stockService.uploadStockToFirestore(item);
    } catch (e) {
      print('Failed to sync stock: $e');
    }
  }
}
