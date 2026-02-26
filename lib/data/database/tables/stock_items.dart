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
  TextColumn get category => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  // New fields for Firestore sync
  TextColumn get remoteId => text().nullable()();
  RealColumn get unitPrice => real().nullable()();
  TextColumn get lastModifiedBy => text().nullable()();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  BoolColumn get isSyncPending =>
      boolean().withDefault(const Constant(false))();

  // Sync fields
  TextColumn get syncStatus => text().withDefault(const Constant('LOCAL'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get firebaseId => text().nullable()();
  TextColumn get createdBy => text().nullable()();
  TextColumn get modifiedBy => text().nullable()();
}
