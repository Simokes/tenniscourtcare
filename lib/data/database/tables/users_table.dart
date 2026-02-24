import 'package:drift/drift.dart';
import '../../../domain/enums/role.dart';

@DataClassName('UserRow')
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get email => text().unique()();
  TextColumn get firestoreUid => text().nullable().unique()(); // Firebase Auth UID
  TextColumn get name => text()();
  TextColumn get passwordHash => text()(); // SHA-256 hash
  TextColumn get role => textEnum<Role>()(); // Stored as string
  DateTimeColumn get lastLoginAt => dateTime().nullable()();
  TextColumn get avatarUrl => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
