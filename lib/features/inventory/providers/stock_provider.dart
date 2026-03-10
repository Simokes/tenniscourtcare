import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/stock_repository_impl.dart';
import '../../../domain/entities/stock_item.dart';
import '../../../data/mappers/stock_item_mapper.dart';
import '../../../domain/repositories/stock_repository.dart';
import '../models/stock_filter.dart';
import '../../../core/providers/core_providers.dart';

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

class StockNotifier extends AsyncNotifier<void> {
  late StockRepository _repo;
  late AppDatabase _db;

  @override
  FutureOr<void> build() {
    _repo = ref.watch(stockRepositoryProvider);
    _db = ref.watch(databaseProvider);
  }

  Future<void> addItem(StockItem item) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final firebaseId = await _repo.addStockItem(item);
      await _db.upsertStockItem(
        item.copyWith(firebaseId: firebaseId).toCompanion(),
      );
    });
  }

  Future<void> updateItem(StockItem item) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repo.updateStockItem(item);
    });
  }

  Future<void> deleteItem(StockItem item) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      if (!item.isCustom) {
        throw StateError('Cet article système ne peut pas être supprimé.');
      }
      final firebaseId = item.firebaseId;
      if (firebaseId == null) {
        throw StateError('firebaseId manquant — synchronisation en cours.');
      }
      await _repo.deleteStockItem(firebaseId);
    });
  }

  Future<void> adjustQuantity(int itemId, int delta, {String? reason}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final items = await ref.read(stockItemsProvider.future);
      final item = items.firstWhere((i) => i.id == itemId);
      final newQuantity = item.quantity + delta;
      if (newQuantity < 0) {
        throw Exception('Stock cannot be negative');
      }
      await _repo.updateStockItem(
        item.copyWith(quantity: newQuantity, updatedAt: DateTime.now()),
      );
    });
  }

  Future<void> reorderItems(List<StockItem> items) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        if (item.sortOrder != i) {
          await _repo.updateStockItem(
            item.copyWith(sortOrder: i, updatedAt: DateTime.now()),
          );
        }
      }
    });
  }
}

final stockNotifierProvider = AsyncNotifierProvider<StockNotifier, void>(
  StockNotifier.new,
);

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
