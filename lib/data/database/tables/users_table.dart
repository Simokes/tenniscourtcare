import 'package:drift/drift.dart';
import '../../../domain/enums/role.dart';

@DataClassName('UserRow')
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get email => text().unique()();
  TextColumn get firestoreUid => text().nullable()(); // Firebase Auth UID
  TextColumn get name => text()();
  TextColumn get passwordHash => text()(); // SHA-256 hash
  TextColumn get role => textEnum<Role>()(); // Stored as string
  DateTimeColumn get lastLoginAt => dateTime().nullable()();
  TextColumn get avatarUrl => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  // Approval fields
  TextColumn get status => text().withDefault(const Constant('inactive'))();
  DateTimeColumn get approvedAt => dateTime().nullable()();
  TextColumn get approvedBy => text().nullable()();

  // New fields for Firestore sync
  TextColumn get remoteId => text().nullable()();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}
