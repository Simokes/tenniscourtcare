// ignore_for_file: unused_import
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tenniscourtcare/data/database/app_database.dart';
import 'package:tenniscourtcare/data/database/stock_history_queries.dart';
import 'package:tenniscourtcare/data/database/stock_history_extension.dart'; // Import the extension
import 'package:tenniscourtcare/domain/entities/stock_item.dart' as doms;

void main() {
  late AppDatabase database;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('adjustStockWithHistory records a movement', () async {
    // 1. Init Stock
    final item = doms.StockItem(
      name: 'TestItem',
      quantity: 100,
      unit: 'pcs',
      isCustom: false,
      minThreshold: 10,
      updatedAt: DateTime.now(),
    );
    final itemId = await database.insertStockItem(item);

    // 2. Adjust Stock
    await database.adjustStockWithHistory(
      itemId: itemId,
      newQuantity: 90,
      reason: 'Correction',
      description: 'Lost 10 items',
    );

    // 3. Verify Stock Update
    final updatedItem = await (database.select(database.stockItems)..where((t) => t.id.equals(itemId))).getSingle();
    expect(updatedItem.quantity, 90);

    // 4. Verify History
    final history = await database.watchStockHistory().first;
    expect(history.length, 1);
    expect(history.first.movement.quantityChange, -10);
    expect(history.first.movement.reason, 'Correction');
    expect(history.first.movement.description, 'Lost 10 items');
    expect(history.first.itemName, 'TestItem');
  });
}
