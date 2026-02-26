import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/stock_repository_impl.dart';
import '../../domain/entities/stock_item.dart';
import '../../domain/repositories/stock_repository.dart';
import '../../features/inventory/models/stock_filter.dart';
import 'database_provider.dart';
import 'terrain_provider.dart';

final stockRepositoryProvider = Provider<StockRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return StockRepositoryImpl(db);
});

final localStockProvider = FutureProvider<List<StockItem>>((ref) async {
  final repo = ref.watch(stockRepositoryProvider);
  return repo.getAllStockItems();
});

final firestoreStockProvider = StreamProvider<List<StockItem>>((ref) {
  final firebaseService = ref.watch(firebaseSyncServiceProvider);
  return firebaseService.stockService.watchStock();
});

final stockProvider = StreamProvider<List<StockItem>>((ref) async* {
  final localFuture = ref.watch(localStockProvider.future);

  final local = await localFuture;
  yield local;

  yield* ref.watch(firestoreStockProvider.stream).map((remote) {
    return _mergeStock(local, remote);
  });
});

final addStockItemProvider = Provider<Future<void> Function(StockItem)>((ref) {
  return (StockItem item) async {
    final repo = ref.read(stockRepositoryProvider);
    await repo.addStockItem(item);
    ref.invalidate(stockProvider);
  };
});

final updateStockItemProvider = Provider<Future<void> Function(StockItem)>((ref) {
  return (StockItem item) async {
    final repo = ref.read(stockRepositoryProvider);
    await repo.updateStockItem(item);
    ref.invalidate(stockProvider);
  };
});

List<StockItem> _mergeStock(List<StockItem> local, List<StockItem> remote) {
  final merged = <int, StockItem>{};

  for (final t in local) {
    if (t.id != null) merged[t.id!] = t;
  }

  for (final t in remote) {
    if (t.id != null && merged.containsKey(t.id)) {
      final existing = merged[t.id]!;
      merged[t.id!] = existing.updatedAt.isAfter(t.updatedAt) ? existing : t;
    } else if (t.id != null) {
      merged[t.id!] = t;
    }
  }

  return merged.values.toList();
}

// Helper alias for UI compatibility
final stockItemsProvider = stockProvider;

// --- Filters & Search ---

final stockFilterProvider = StateProvider<StockFilter>((ref) => StockFilter.all);
final stockSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredStockItemsProvider = Provider<AsyncValue<List<StockItem>>>((ref) {
  final itemsAsync = ref.watch(stockProvider);
  final filter = ref.watch(stockFilterProvider);
  final query = ref.watch(stockSearchQueryProvider).toLowerCase();

  return itemsAsync.whenData((items) {
    var filtered = items;

    // Search
    if (query.isNotEmpty) {
      filtered = filtered.where((i) => i.name.toLowerCase().contains(query)).toList();
    }

    // Filter
    switch (filter) {
      case StockFilter.all:
        break;
      case StockFilter.lowStock:
        filtered = filtered.where((i) => i.isLowOnStock).toList();
        break;
      case StockFilter.fixed:
        filtered = filtered.where((i) => !i.isCustom).toList();
        break;
      case StockFilter.custom:
        filtered = filtered.where((i) => i.isCustom).toList();
        break;
    }
    return filtered;
  });
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
  }

  Future<void> reorderItems(List<StockItem> items) async {
    // Update sortOrder for each item if changed
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      if (item.sortOrder != i) {
        final updated = item.copyWith(sortOrder: i, updatedAt: DateTime.now());
        await ref.read(updateStockItemProvider)(updated);
      }
    }
  }
}

final stockNotifierProvider = StateNotifierProvider<StockNotifier, AsyncValue<List<StockItem>>>((ref) {
  return StockNotifier(ref);
});
