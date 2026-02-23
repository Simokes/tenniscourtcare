import 'package:drift/drift.dart';

@DataClassName('AuditLog')
class AuditLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  // userId can be nullable because some actions (like failed login) might not have a valid userId yet,
  // or user might be deleted. We store email separately for that reason.
  IntColumn get userId => integer().nullable()();
  TextColumn get action => text()(); // LOGIN_SUCCESS, LOGIN_FAILED, etc.
  TextColumn get email => text().nullable()(); // Snapshot of email at the time
  TextColumn get ipAddress => text().nullable()();
  TextColumn get deviceInfo => text().nullable()();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  TextColumn get details => text().nullable()(); // JSON string for extra info
}
