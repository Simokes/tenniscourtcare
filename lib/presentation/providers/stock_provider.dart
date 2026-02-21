import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/stock_item.dart';
import 'database_provider.dart';

enum StockFilter { all, fixed, custom, lowStock }

final stockFilterProvider = StateProvider<StockFilter>((ref) => StockFilter.all);
final stockSearchQueryProvider = StateProvider<String>((ref) => '');

final stockItemsProvider = StreamProvider<List<StockItem>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllStockItems();
});

final filteredStockItemsProvider = Provider<AsyncValue<List<StockItem>>>((ref) {
  final itemsAsync = ref.watch(stockItemsProvider);
  final filter = ref.watch(stockFilterProvider);
  final query = ref.watch(stockSearchQueryProvider).toLowerCase();

  return itemsAsync.whenData((items) {
    return items.where((item) {
      final matchesQuery = item.name.toLowerCase().contains(query);
      final matchesFilter = switch (filter) {
        StockFilter.all => true,
        StockFilter.fixed => !item.isCustom,
        StockFilter.custom => item.isCustom,
        StockFilter.lowStock => item.isLowOnStock,
      };
      return matchesQuery && matchesFilter;
    }).toList();
  });
});

class StockNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  StockNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> adjustQuantity(StockItem item, int delta) async {
    final newQuantity = (item.quantity + delta).clamp(0, 9999);
    final updated = item.copyWith(
      quantity: newQuantity,
      updatedAt: DateTime.now(),
    );
    await _ref.read(databaseProvider).updateStockItem(updated);
  }

  Future<void> addItem(StockItem item) async {
    await _ref.read(databaseProvider).insertStockItem(item);
  }

  Future<void> updateItem(StockItem item) async {
    await _ref.read(databaseProvider).updateStockItem(item.copyWith(updatedAt: DateTime.now()));
  }

  Future<void> deleteItem(int id) async {
    await _ref.read(databaseProvider).deleteStockItem(id);
  }
}

final stockNotifierProvider = StateNotifierProvider<StockNotifier, AsyncValue<void>>((ref) {
  return StockNotifier(ref);
});
