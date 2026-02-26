import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/stock_repository_impl.dart';
import '../../data/services/firebase_sync_service.dart';
import '../../domain/entities/stock_item.dart';
import '../../domain/repositories/stock_repository.dart';
import '../../features/inventory/models/stock_filter.dart';
import 'database_provider.dart';

// ✅ FIREBASE SYNC SERVICE PROVIDER
final firebaseSyncServiceProvider = Provider<FirebaseSyncService>((ref) {
  final db = ref.watch(databaseProvider);
  return FirebaseSyncService(FirebaseFirestore.instance, db);
});

final stockRepositoryProvider = Provider<StockRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return StockRepositoryImpl(db);
});

// ✅ STOCK ITEMS - SIMPLE FUTURE PROVIDER
final stockProvider = FutureProvider<List<StockItem>>((ref) async {
  final repo = ref.watch(stockRepositoryProvider);
  final items = await repo.getAllStockItems();

  debugPrint('📦 Loaded ${items.length} stock items');
  return items;
});

// ✅ ADD STOCK ITEM WITH SYNC
final addStockItemProvider = Provider<Future<void> Function(StockItem)>((ref) {
  return (StockItem item) async {
    try {
      final repo = ref.read(stockRepositoryProvider);
      await repo.addStockItem(item);

      final syncService = ref.read(firebaseSyncServiceProvider);
      await syncService.syncStock();

      // ✅ INVALIDATE to refresh UI
      ref.invalidate(stockProvider);
      ref.invalidate(filteredStockItemsProvider);

      debugPrint('✅ Item added and synced');
    } catch (e) {
      debugPrint('❌ Error adding stock: $e');
      rethrow;
    }
  };
});

// ✅ UPDATE STOCK ITEM WITH SYNC
final updateStockItemProvider = Provider<Future<void> Function(StockItem)>((
  ref,
) {
  return (StockItem item) async {
    try {
      final repo = ref.read(stockRepositoryProvider);
      await repo.updateStockItem(item);

      final syncService = ref.read(firebaseSyncServiceProvider);
      await syncService.syncStock();

      // ✅ INVALIDATE to refresh UI
      ref.invalidate(stockProvider);
      ref.invalidate(filteredStockItemsProvider);

      debugPrint('✅ Item updated and synced');
    } catch (e) {
      debugPrint('❌ Error updating stock: $e');
      rethrow;
    }
  };
});

// ✅ DELETE STOCK ITEM WITH SYNC
final deleteStockItemProvider = Provider<Future<void> Function(int)>((ref) {
  return (int itemId) async {
    try {
      final repo = ref.read(stockRepositoryProvider);
      await repo.deleteStockItem(itemId);

      final syncService = ref.read(firebaseSyncServiceProvider);
      await syncService.syncStock();

      // ✅ INVALIDATE to refresh UI
      ref.invalidate(stockProvider);
      ref.invalidate(filteredStockItemsProvider);

      debugPrint('✅ Item deleted and synced');
    } catch (e) {
      debugPrint('❌ Error deleting stock: $e');
      rethrow;
    }
  };
});

// ✅ SYNC TRIGGER PROVIDER
final syncStockProvider = FutureProvider<void>((ref) async {
  final syncService = ref.watch(firebaseSyncServiceProvider);
  await syncService.syncStock();
});

// --- Filters & Search ---

final stockFilterProvider = StateProvider<StockFilter>((ref) {
  return StockFilter.all;
});

final stockSearchQueryProvider = StateProvider<String>((ref) {
  return '';
});

// ✅ FILTERED STOCK ITEMS
final filteredStockItemsProvider = FutureProvider<List<StockItem>>((ref) async {
  final allItems = await ref.watch(stockProvider.future);
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
    ref.listen(stockProvider, (previous, next) {
      state = next;
    });
  }

  Future<void> adjustQuantity(int itemId, int delta, {String? reason}) async {
    try {
      final items = await ref.read(stockProvider.future);
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
    await ref.read(addStockItemProvider)(item);
  }

  Future<void> updateItem(StockItem item) async {
    await ref.read(updateStockItemProvider)(item);
  }

  Future<void> deleteItem(int id) async {
    await ref.read(deleteStockItemProvider)(id);
  }
}

final stockNotifierProvider =
    StateNotifierProvider<StockNotifier, AsyncValue<List<StockItem>>>((ref) {
      return StockNotifier(ref);
    });

// --- Alert Providers ---

// ✅ LOW STOCK ITEMS
final lowStockItemsProvider = FutureProvider.autoDispose<List<StockItem>>((
  ref,
) async {
  final items = await ref.watch(stockProvider.future);

  final lowStock = items.where((item) {
    final threshold = item.minThreshold;
    if (threshold == null) return false;
    return item.quantity < threshold;
  }).toList()..sort((a, b) => a.quantity.compareTo(b.quantity));

  return lowStock;
});

// ✅ CRITICAL STOCK ITEMS
final criticalStockItemsProvider = FutureProvider.autoDispose<List<StockItem>>((
  ref,
) async {
  final lowStockItems = await ref.watch(lowStockItemsProvider.future);

  return lowStockItems.where((item) => item.quantity <= 5).toList();
});

// ✅ LOW STOCK COUNT
final lowStockCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final lowStockItems = await ref.watch(lowStockItemsProvider.future);
  return lowStockItems.length;
});
