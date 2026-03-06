import 'package:drift/drift.dart';

@DataClassName(
  'MaintenanceRow',
) // 👈 très important pour éviter le conflit avec ton entity domaine
class Maintenances extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get terrainId => integer()();
  TextColumn get type => text()(); // ou enum stocké en text
  TextColumn get commentaire => text().nullable()();
  IntColumn get date => integer()(); // epoch ms
  IntColumn get sacsMantoUtilises => integer().withDefault(const Constant(0))();
  IntColumn get sacsSottomantoUtilises =>
      integer().withDefault(const Constant(0))();
  IntColumn get sacsSiliceUtilises =>
      integer().withDefault(const Constant(0))();

  BoolColumn get isPlanned => boolean().withDefault(const Constant(false))();

  IntColumn get startHour => integer().withDefault(const Constant(8))();
  IntColumn get durationMinutes => integer().withDefault(const Constant(60))();

  TextColumn get imagePath => text().nullable()();

  // New fields for Firestore sync
  TextColumn get remoteId => text().nullable()();
  TextColumn get status => text().nullable()();
  DateTimeColumn get scheduledDate => dateTime().nullable()();
  DateTimeColumn get completedDate => dateTime().nullable()();

  // Sync fields
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get firebaseId => text().nullable()();
  TextColumn get createdBy => text().nullable()();
  TextColumn get modifiedBy => text().nullable()();

  DateTimeColumn get syncedAt => dateTime().nullable()();
}
