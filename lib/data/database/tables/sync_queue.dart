import 'package:drift/drift.dart';

@DataClassName('SyncQueueItem')
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  TextColumn get collection => text()(); // 'users', 'terrains', 'reservations', 'stock'
  TextColumn get action => text()(); // 'create', 'update', 'delete'
  TextColumn get documentId => text()();
  TextColumn get data => text()(); // JSON string
  DateTimeColumn get timestamp => dateTime()(); // Renamed from createdAt
  DateTimeColumn get syncedAt => dateTime().nullable()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get nextRetryAt => dateTime().nullable()(); // Added
}
