import 'package:drift/drift.dart';

@DataClassName(
  'TerrainRow',
) // 👈 évite la collision avec l’entity domaine `Terrain`
class Terrains extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nom => text().withLength(min: 1, max: 100)();
  IntColumn get type => integer()(); // 0=terreBattue, 1=synthetique, 2=dur
  TextColumn get status => text().withDefault(
    const Constant('playable'),
  )(); // playable, maintenance, unavailable, frozen

  // New fields for Firestore sync
  TextColumn get remoteId => text().nullable()();
  TextColumn get location => text().nullable()();
  IntColumn get capacity => integer().nullable()();
  RealColumn get pricePerHour => real().nullable()();
  BoolColumn get available => boolean().withDefault(const Constant(true))();

  // Sync fields
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get firebaseId => text().nullable()();
  TextColumn get createdBy => text().nullable()();
  TextColumn get modifiedBy => text().nullable()();

  DateTimeColumn get syncedAt => dateTime().nullable()();
  TextColumn get imageUrl => text().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => []; // Removed indices on createdAt/syncStatus as per fix request
}
