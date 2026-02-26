import 'package:drift/drift.dart';
import 'stock_items.dart';
import 'users_table.dart';

@DataClassName('StockMovement')
class StockMovements extends Table {
  IntColumn get id => integer().autoIncrement()();

  // Foreign key to StockItems
  IntColumn get stockItemId => integer().references(StockItems, #id)();

  // Foreign key to Users (nullable because some system actions might not be directly attributable or user might be deleted)
  // Ideally we should track who did it. For now, we make it nullable to be safe.
  IntColumn get userId => integer().nullable().references(Users, #id)();

  // Snapshot of quantity state
  IntColumn get previousQuantity => integer()();
  IntColumn get newQuantity => integer()();
  IntColumn get quantityChange =>
      integer()(); // Calculated for convenience query side

  // Metadata
  TextColumn get reason =>
      text()(); // 'Maintenance', 'Livraison', 'Correction', 'Inventaire'
  TextColumn get description => text().nullable()(); // e.g. "Commande #12345"

  DateTimeColumn get occurredAt => dateTime().withDefault(currentDateAndTime)();
}
