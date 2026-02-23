import 'package:drift/drift.dart';
import 'app_database.dart';

// Extension pour ajouter les fonctionnalités de traçabilité à AppDatabase
extension StockHistoryExtension on AppDatabase {

  // --- Helper interne pour enregistrer un mouvement ---
  Future<void> _recordMovement({
    required int itemId,
    required int previousQuantity,
    required int newQuantity,
    required String reason,
    String? description,
    int? userId,
  }) async {
    final diff = newQuantity - previousQuantity;
    if (diff == 0) return;

    await into(stockMovements).insert(
      StockMovementsCompanion(
        stockItemId: Value(itemId),
        previousQuantity: Value(previousQuantity),
        newQuantity: Value(newQuantity),
        quantityChange: Value(diff),
        reason: Value(reason),
        description: Value(description),
        userId: Value(userId),
        occurredAt: Value(DateTime.now()),
      ),
    );
  }

  // --- Méthode publique pour ajustement manuel (Livraison, Inventaire) ---
  Future<void> adjustStockWithHistory({
    required int itemId,
    required int newQuantity,
    required String reason,
    String? description,
    int? userId,
  }) async {
    return transaction(() async {
      // 1. Get current item
      final itemRow = await (select(stockItems)..where((t) => t.id.equals(itemId))).getSingle();

      if (itemRow.quantity == newQuantity) return; // No op

      // 2. Update Stock
      await (update(stockItems)..where((t) => t.id.equals(itemId))).write(
        StockItemsCompanion(
          quantity: Value(newQuantity),
          updatedAt: Value(DateTime.now()),
        ),
      );

      // 3. Record History
      await _recordMovement(
        itemId: itemId,
        previousQuantity: itemRow.quantity,
        newQuantity: newQuantity,
        reason: reason,
        description: description,
        userId: userId,
      );
    });
  }
}
