import '../entities/stock_item.dart';

abstract class StockRepository {
  Future<int> addStockItem(StockItem item);
  Future<bool> updateStockItem(StockItem item);
  Future<bool> deleteStockItem(int id);
  Future<List<StockItem>> getAllStockItems();
  Future<StockItem?> getStockItemById(int id);
}
