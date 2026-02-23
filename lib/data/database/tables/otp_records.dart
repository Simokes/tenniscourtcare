import 'package:drift/drift.dart';

@DataClassName('OtpRecord')
class OtpRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get email => text()();
  TextColumn get hashedOtp => text()(); // Should be securely hashed
  DateTimeColumn get expiresAt => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  // Optional if we want to tie to user ID directly, but email is fine for pre-login reset
  IntColumn get userId => integer().nullable()();
}
