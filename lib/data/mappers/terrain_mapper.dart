import '../../domain/entities/terrain.dart' as dom;
import '../database/app_database.dart' as db;
import 'package:drift/drift.dart';

// DB -> Domaine
extension TerrainRowX on db.TerrainRow {
  dom.Terrain toDomain() => dom.Terrain(
    id: id,
    nom: nom,
    type: dom.TerrainType.values[type], // type stocké en int (index)
  );
}

// Domaine -> Companion (INSERT/UPDATE)
extension TerrainDomainX on dom.Terrain {
  db.TerrainsCompanion toCompanion({bool includeId = true}) =>
      db.TerrainsCompanion(
        id: includeId ? Value(id) : const Value.absent(),
        nom: Value(nom),
        type: Value(type.index),
      );
}
