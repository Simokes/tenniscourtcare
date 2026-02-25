import 'package:drift/drift.dart';

@DataClassName(
  'TerrainRow',
) // 👈 évite la collision avec l’entity domaine `Terrain`
class Terrains extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nom => text().withLength(min: 1, max: 100)();
  IntColumn get type => integer()(); // 0=terreBattue, 1=synthetique, 2=dur
  TextColumn get status => text().withDefault(const Constant('playable'))(); // playable, maintenance, unavailable, frozen

  // New fields for Firestore sync
  TextColumn get remoteId => text().nullable()();
  TextColumn get location => text().nullable()();
  IntColumn get capacity => integer().nullable()();
  RealColumn get pricePerHour => real().nullable()();
  BoolColumn get available => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  TextColumn get imageUrl => text().nullable()();
}
