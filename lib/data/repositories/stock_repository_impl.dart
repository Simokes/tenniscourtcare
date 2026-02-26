// filepath: lib/data/repositories/stock_repository_impl.dart

import 'package:collection/collection.dart';
import 'package:tenniscourtcare/data/database/app_database.dart';
import 'package:tenniscourtcare/domain/entities/stock_item.dart';
import 'package:tenniscourtcare/domain/entities/sync_status.dart';
import 'package:tenniscourtcare/domain/repositories/stock_repository.dart';

class StockRepositoryImpl implements StockRepository {
  final AppDatabase _db;

  StockRepositoryImpl(this._db);

  @override
  Future<int> addStockItem(StockItem item) async {
    final localItem = item.copyWith(
      syncStatus: SyncStatus.local,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return await _db.insertStockItem(localItem);
  }

  @override
  Future<bool> updateStockItem(StockItem item) async {
    final updatedItem = item.copyWith(
      syncStatus: SyncStatus.local,
      updatedAt: DateTime.now(),
    );

    return await _db.updateStockItem(updatedItem);
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
    return items.firstWhereOrNull((item) => item.id == id);
  }
}
