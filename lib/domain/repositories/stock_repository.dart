import '../entities/stock_item.dart';

abstract class StockRepository {
  Future<String> addStockItem(StockItem item);
  Future<void> updateStockItem(StockItem item);
  Future<void> deleteStockItem(String firebaseId);
  Future<List<StockItem>> getAllStockItems();
  Future<StockItem?> getStockItemById(int id);
}
