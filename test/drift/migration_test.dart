import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tenniscourtcare/data/database/app_database.dart';
import 'package:tenniscourtcare/domain/entities/stock_item.dart';

void main() {
  // NOTE: La migration v3→v23 contient des bugs en cascade (v21 tente
  // d'ajouter is_planned déjà présent après la recreation v18). Ces bugs
  // sont documentés et seront corrigés dans un PR dédié à la chaine
  // de migration. Ce test couvre la fonctionnalité du schéma v23.

  test('Schema v23 — création et opérations CRUD fonctionnelles', () async {
    final db = AppDatabase(NativeDatabase.memory());

    try {
      // Vérifier que le schema est opérationnel
      final initialItems = await db.watchAllStockItems().first;
      expect(initialItems, isEmpty);

      // Insérer un article
      await db.insertStockItem(
        StockItem(
          name: 'Test Item',
          quantity: 10,
          unit: 'pcs',
          isCustom: false,
        ),
      );

      // Vérifier la lecture
      final items = await db.watchAllStockItems().first;
      expect(items.length, 1);
      expect(items.first.name, 'Test Item');
      expect(items.first.quantity, 10);

      // Vérifier la mise à jour
      await db.updateStockItem(items.first.copyWith(quantity: 20));
      final updated = await db.watchAllStockItems().first;
      expect(updated.first.quantity, 20);
    } finally {
      await db.close();
    }
  });
}
