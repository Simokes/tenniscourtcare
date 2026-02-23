import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/stock_item.dart';
import '../../data/mappers/stock_item_mapper.dart';
import '../../data/database/stock_history_extension.dart';
import 'auth_providers.dart';
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
    final user = _ref.read(currentUserProvider);

    // Utilisation de la nouvelle méthode avec historique
    await _ref.read(databaseProvider).adjustStockWithHistory(
      itemId: item.id!,
      newQuantity: newQuantity,
      reason: 'Correction',
      description: 'Ajustement rapide (delta: ${delta > 0 ? "+$delta" : delta})',
      userId: user?.id,
    );
  }

  Future<void> addItem(StockItem item) async {
    // L'ajout d'un item initialise le stock à sa quantité de base.
    // On pourrait historiser la création, mais ce n'est pas un "mouvement" stricto sensu.
    // Cependant, si la quantité initiale > 0, c'est un apport.

    await _ref.read(databaseProvider).insertStockItem(item);

    // Si la quantité initiale > 0, on pourrait historiser, mais pour l'instant on reste simple.
  }

  Future<void> updateItem(StockItem item) async {
    // Si la quantité change via l'écran d'édition, on doit tracer
    // Mais updateItem remplace tout l'objet.
    // Il faudrait comparer l'ancien et le nouveau.

    final db = _ref.read(databaseProvider);
    // On ne peut pas facilement comparer ici sans refaire un fetch.
    // Pour simplifier, on suppose que l'édition complète est une "Correction d'inventaire"
    // Mais `updateStockItem` dans AppDatabase fait un `replace`.

    // Pour bien faire les choses :
    // On utilise une transaction spécifique si la quantité change.
    // Sinon on fait un update simple.

    // Note: StockItem est une entité du domaine, pas la row Drift.

    // Approche pragmatique : On fait l'update standard.
    // Si l'utilisateur veut changer le stock, il devrait utiliser adjustQuantity ou un bouton "Inventaire".
    // L'écran d'édition permet de changer le nom, seuil, etc.
    // Si la quantité est modifiée dans l'édit, on perd la traçabilité précise "pourquoi".
    // Pour l'instant, on garde le comportement legacy pour l'update global.
    await db.updateStockItem(item.copyWith(updatedAt: DateTime.now()));
  }

  Future<void> deleteItem(int id) async {
    await _ref.read(databaseProvider).deleteStockItem(id);
  }

  Future<void> reorderItems(List<StockItem> items) async {
    // Re-index sortOrder
    final updatedItems = items.asMap().entries.map((e) {
      return e.value.copyWith(sortOrder: e.key).toCompanion();
    }).toList();

    await _ref.read(databaseProvider).updateStockItemOrder(updatedItems);
  }
}

final stockNotifierProvider = StateNotifierProvider<StockNotifier, AsyncValue<void>>((ref) {
  return StockNotifier(ref);
});
