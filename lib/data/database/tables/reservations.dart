import 'package:drift/drift.dart';
import 'users_table.dart';
import 'terrain_table.dart';

@DataClassName('Reservation')
class Reservations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text().nullable().unique()();

  // Local references
  IntColumn get userId => integer().references(Users, #id)();
  IntColumn get terrainId => integer().references(Terrains, #id)();

  DateTimeColumn get date => dateTime()();
  TextColumn get startTime => text()(); // HH:mm
  TextColumn get endTime => text()(); // HH:mm
  TextColumn get status => text()(); // pending, confirmed, cancelled
  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  BoolColumn get isSyncPending => boolean().withDefault(const Constant(true))();
}
