import 'package:drift/drift.dart';

@DataClassName('TerrainRow') // 👈 évite la collision avec l’entity domaine `Terrain`
class Terrains extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nom => text().withLength(min: 1, max: 100)();
  IntColumn get type => integer()(); // 0=terreBattue, 1=synthetique, 2=dur
}