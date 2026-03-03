import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/stock_repository_impl.dart';
import '../../domain/entities/stock_item.dart';
import '../../data/mappers/stock_item_mapper.dart';
import '../../domain/repositories/stock_repository.dart';
import '../../features/inventory/models/stock_filter.dart';
import 'database_provider.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

final stockRepositoryProvider = Provider<StockRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return StockRepositoryImpl(db: db, fs: FirebaseFirestore.instance);
});

// ✅ STOCK ITEMS - STREAM PROVIDER (From Drift)
final stockItemsProvider = StreamProvider<List<StockItem>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllStockItems();
});

// Also keep an alias to `stockProvider` in case it is used directly elsewhere in unmodified places to avoid massive refactoring,
// but based on instructions, we should rename or use it as is. We will alias it to `stockItemsProvider`.
final stockProvider = stockItemsProvider;

// ✅ ADD STOCK ITEM
final addStockItemProvider = Provider<Future<String> Function(StockItem)>((ref) {
  return (StockItem item) async {
    try {
      final repo = ref.read(stockRepositoryProvider);
      final firebaseId = await repo.addStockItem(item);

      debugPrint('✅ Item added');
      return firebaseId;
    } catch (e) {
      debugPrint('❌ Error adding stock: $e');
      rethrow;
    }
  };
});

// ✅ UPDATE STOCK ITEM
final updateStockItemProvider = Provider<Future<void> Function(StockItem)>((
  ref,
) {
  return (StockItem item) async {
    try {
      final repo = ref.read(stockRepositoryProvider);
      await repo.updateStockItem(item);

      debugPrint('✅ Item updated');
    } catch (e) {
      debugPrint('❌ Error updating stock: $e');
      rethrow;
    }
  };
});

// ✅ DELETE STOCK ITEM
final deleteStockItemProvider = Provider<Future<void> Function(String)>((ref) {
  return (String firebaseId) async {
    try {
      final repo = ref.read(stockRepositoryProvider);
      await repo.deleteStockItem(firebaseId);

      debugPrint('✅ Item deleted');
    } catch (e) {
      debugPrint('❌ Error deleting stock: $e');
      rethrow;
    }
  };
});

// --- Filters & Search ---

final stockFilterProvider = StateProvider<StockFilter>((ref) {
  return StockFilter.all;
});

final stockSearchQueryProvider = StateProvider<String>((ref) {
  return '';
});

// ✅ FILTERED STOCK ITEMS
final filteredStockItemsProvider = Provider<List<StockItem>>((ref) {
  final allItems = ref.watch(stockItemsProvider).value ?? [];
  final filter = ref.watch(stockFilterProvider);
  final searchQuery = ref.watch(stockSearchQueryProvider).toLowerCase();
  var filtered = allItems;

  // ✅ APPLY FILTER
  switch (filter) {
    case StockFilter.lowStock:
      filtered = filtered.where((item) {
        final threshold = item.minThreshold;
        if (threshold == null) return false;
        return item.quantity < threshold;
      }).toList();
      debugPrint('🔴 Filtered to ${filtered.length} low stock items');
      break;

    case StockFilter.fixed:
      filtered = filtered.where((item) => !item.isCustom).toList();
      debugPrint('📌 Filtered to ${filtered.length} fixed items');
      break;

    case StockFilter.custom:
      filtered = filtered.where((item) => item.isCustom).toList();
      debugPrint('✏️ Filtered to ${filtered.length} custom items');
      break;

    case StockFilter.all:
      debugPrint('📦 Showing all ${filtered.length} items');
      break;
  }

  // ✅ APPLY SEARCH
  if (searchQuery.isNotEmpty) {
    filtered = filtered
        .where((item) => item.name.toLowerCase().contains(searchQuery))
        .toList();
    debugPrint('🔍 Search found ${filtered.length} items');
  }

  // ✅ SORT BY ORDER
  filtered.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  return filtered;
});

// --- StockNotifier ---

class StockNotifier extends StateNotifier<AsyncValue<List<StockItem>>> {
  final Ref ref;

  StockNotifier(this.ref) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    ref.listen(stockItemsProvider, (previous, next) {
      state = next;
    });
  }

  Future<void> adjustQuantity(int itemId, int delta, {String? reason}) async {
    try {
      final items = await ref.read(stockItemsProvider.future);
      final item = items.firstWhere((i) => i.id == itemId);

      final newQuantity = item.quantity + delta;
      if (newQuantity < 0) {
        throw Exception('Stock cannot be negative');
      }

      final updated = item.copyWith(
        quantity: newQuantity,
        updatedAt: DateTime.now(),
      );

      await ref.read(updateStockItemProvider)(updated);
    } catch (e) {
      debugPrint('❌ Error adjusting quantity: $e');
      rethrow;
    }
  }

  Future<void> reorderItems(List<StockItem> items) async {
    try {
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        if (item.sortOrder != i) {
          final updated = item.copyWith(
            sortOrder: i,
            updatedAt: DateTime.now(),
          );
          await ref.read(updateStockItemProvider)(updated);
        }
      }
    } catch (e) {
      debugPrint('❌ Error reordering items: $e');
      rethrow;
    }
  }

  Future<void> addItem(StockItem item) async {
    try {
      state = const AsyncValue.loading();
      final firebaseId = await ref.read(addStockItemProvider)(item);
      final db = ref.read(databaseProvider);

      await db.upsertStockItem(
        item.copyWith(firebaseId: firebaseId).toCompanion(),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateItem(StockItem item) async {
    await ref.read(updateStockItemProvider)(item);
  }

  Future<void> deleteItem(String firebaseId) async {
    await ref.read(deleteStockItemProvider)(firebaseId);
  }
}

final stockNotifierProvider =
    StateNotifierProvider<StockNotifier, AsyncValue<List<StockItem>>>((ref) {
      return StockNotifier(ref);
    });

// --- Alert Providers ---

// ✅ LOW STOCK ITEMS
final lowStockItemsProvider = Provider<List<StockItem>>((ref) {
  final items = ref.watch(stockItemsProvider).value ?? [];

  final lowStock = items.where((item) {
    final threshold = item.minThreshold;
    if (threshold == null) return false;
    return item.quantity < threshold;
  }).toList()..sort((a, b) => a.quantity.compareTo(b.quantity));

  return lowStock;
});

// ✅ CRITICAL STOCK ITEMS
final criticalStockItemsProvider = Provider<List<StockItem>>((ref) {
  final lowStockItems = ref.watch(lowStockItemsProvider);
  return lowStockItems.where((item) => item.quantity <= 5).toList();
});

// ✅ LOW STOCK COUNT
final lowStockCountProvider = Provider<int>((ref) {
  return ref.watch(lowStockItemsProvider).length;
});
