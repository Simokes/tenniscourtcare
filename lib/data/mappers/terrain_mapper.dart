import '../../domain/entities/terrain.dart' as dom;
import '../database/app_database.dart' as db;
import 'package:drift/drift.dart';

// DB -> Domaine
extension TerrainRowX on db.TerrainRow {
  dom.Terrain toDomain() {
    dom.TerrainStatus domainStatus;
    try {
      domainStatus = dom.TerrainStatus.values.byName(status);
    } catch (_) {
      // Fallback if the status string in DB doesn't match any enum value
      domainStatus = dom.TerrainStatus.playable;
    }

    return dom.Terrain(
      id: id,
      nom: nom,
      type: dom.TerrainType.values[type], // type stocké en int (index)
      status: domainStatus,
      latitude: null, // Mapped fields from DB if they exist in DB entity but not in current drift definition for this extension
      longitude: null,
      photoUrl: imageUrl,
    );
  }
}

// Domaine -> Companion (INSERT/UPDATE)
extension TerrainDomainX on dom.Terrain {
  db.TerrainsCompanion toCompanion({bool includeId = true}) =>
      db.TerrainsCompanion(
        id: includeId ? Value(id) : const Value.absent(),
        nom: Value(nom),
        type: Value(type.index),
        status: Value(status.name),
        imageUrl: photoUrl != null ? Value(photoUrl) : const Value.absent(),
      );
}
