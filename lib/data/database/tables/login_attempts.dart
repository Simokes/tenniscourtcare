import 'package:drift/drift.dart';

@DataClassName('LoginAttempt')
class LoginAttempts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get email => text()();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get success => boolean()();
  TextColumn get ipAddress => text().nullable()();
}
