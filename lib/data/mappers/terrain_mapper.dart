// filepath: lib/data/mappers/terrain_mapper.dart

import 'package:drift/drift.dart';
import 'package:tenniscourtcare/data/database/app_database.dart' as db;
import 'package:tenniscourtcare/data/models/terrain_model.dart';
import 'package:tenniscourtcare/domain/entities/sync_status.dart';
import 'package:tenniscourtcare/domain/entities/terrain.dart';

class TerrainMapper {
  // Model → Domain Entity
  static Terrain toDomain(TerrainModel model) {
    return Terrain(
      id: model.id,
      nom: model.nom,
      type: TerrainType.values.byName(model.type),
      status: TerrainStatus.values.byName(model.status),
      latitude: model.latitude,
      longitude: model.longitude,
      photoUrl: model.photoUrl,
      syncStatus: SyncStatus.fromString(model.syncStatus),
      createdAt: DateTime.parse(model.createdAt),
      updatedAt: DateTime.parse(model.updatedAt),
      firebaseId: model.firebaseId,
      createdBy: model.createdBy,
      modifiedBy: model.modifiedBy,
    );
  }

  // Domain Entity → Model
  static TerrainModel toModel(Terrain domain) {
    return TerrainModel(
      id: domain.id,
      nom: domain.nom,
      type: domain.type.name,
      status: domain.status.name,
      latitude: domain.latitude,
      longitude: domain.longitude,
      photoUrl: domain.photoUrl,
      syncStatus: domain.syncStatus.name,
      createdAt: domain.createdAt.toIso8601String(),
      updatedAt: domain.updatedAt.toIso8601String(),
      firebaseId: domain.firebaseId,
      createdBy: domain.createdBy,
      modifiedBy: domain.modifiedBy,
    );
  }

  // Drift Entity → Domain Entity
  static Terrain fromDriftEntity(db.TerrainRow driftEntity) {
    TerrainStatus domainStatus;
    try {
      domainStatus = TerrainStatus.values.byName(driftEntity.status);
    } catch (_) {
      domainStatus = TerrainStatus.playable;
    }

    // Assuming driftEntity.type is int (index)
    return Terrain(
      id: driftEntity.id,
      nom: driftEntity.nom,
      type: TerrainType.values[driftEntity.type],
      status: domainStatus,
      latitude: null, // Drift entity does not store latitude
      longitude: null, // Drift entity does not store longitude
      photoUrl: driftEntity.imageUrl,
      syncStatus: SyncStatus.fromString(driftEntity.syncStatus),
      createdAt: driftEntity.createdAt,
      updatedAt: driftEntity.updatedAt,
      firebaseId: driftEntity.firebaseId,
      createdBy: driftEntity.createdBy,
      modifiedBy: driftEntity.modifiedBy,
    );
  }
}

// Extensions for compatibility
extension TerrainModelX on TerrainModel {
  Terrain toDomain() => TerrainMapper.toDomain(this);
}

extension TerrainDriftX on db.TerrainRow {
  Terrain toDomain() => TerrainMapper.fromDriftEntity(this);
}

// Domain → Companion (Keeping for DB inserts)
extension TerrainDomainX on Terrain {
  db.TerrainsCompanion toCompanion({bool includeId = true}) =>
      db.TerrainsCompanion(
        id: includeId ? Value(id) : const Value.absent(),
        nom: Value(nom),
        type: Value(type.index),
        status: Value(status.name),
        imageUrl: photoUrl != null ? Value(photoUrl) : const Value.absent(),
        // Sync mappings
        syncStatus: Value(syncStatus.name),
        createdAt: Value(createdAt),
        updatedAt: Value(updatedAt),
        firebaseId: Value(firebaseId),
        remoteId: Value(firebaseId), // Fallback
        createdBy: Value(createdBy),
        modifiedBy: Value(modifiedBy),
      );
}
