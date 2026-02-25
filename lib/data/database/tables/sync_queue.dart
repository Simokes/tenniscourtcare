import 'package:drift/drift.dart';

@DataClassName('SyncQueueItem')
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get collection => text()(); // 'users', 'terrains', 'reservations', 'stock'
  TextColumn get action => text()(); // 'create', 'update', 'delete'
  TextColumn get documentId => text()();
  TextColumn get data => text()(); // JSON string
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
}
