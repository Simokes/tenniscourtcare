import 'package:drift/drift.dart';

class Maintenances extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get terrainId =>
      integer().customConstraint('REFERENCES terrains(id)')();
  TextColumn get type => text().withLength(min: 1, max: 100)();
  TextColumn get commentaire => text().nullable()();
  IntColumn get date => integer()(); // epoch ms
  IntColumn get sacsMantoUtilises => integer().withDefault(const Constant(0))();
  IntColumn get sacsSottomantoUtilises =>
      integer().withDefault(const Constant(0))();
  IntColumn get sacsSiliceUtilises =>
      integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
