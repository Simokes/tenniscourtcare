import 'package:drift/drift.dart';

@DataClassName('StockItemRow')
class StockItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get quantity => integer().withDefault(const Constant(0))();
  TextColumn get unit => text().withLength(min: 1, max: 20)();
  TextColumn get comment => text().nullable()();
  BoolColumn get isCustom => boolean()();
  IntColumn get minThreshold => integer().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
}
