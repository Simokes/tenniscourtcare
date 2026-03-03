import 'package:cloud_firestore/cloud_firestore.dart';
// filepath: lib/data/mappers/terrain_mapper.dart

import 'package:drift/drift.dart' as drift;
import 'package:tenniscourtcare/data/database/app_database.dart' as db;

import 'package:tenniscourtcare/data/models/terrain_model.dart';
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
      createdAt: driftEntity.createdAt,
      updatedAt: driftEntity.updatedAt,
      firebaseId: driftEntity.firebaseId,
      createdBy: driftEntity.createdBy,
      modifiedBy: driftEntity.modifiedBy,
    );
  }

  // Domain Entity → Firestore Map
  static Map<String, dynamic> toFirestore(Terrain item) {
    return {
      'nom': item.nom,
      'type': item.type.index,
      'status': item.status.name,
      'latitude': item.latitude,
      'longitude': item.longitude,
      'photoUrl': item.photoUrl,
      'createdAt': item.createdAt.toIso8601String(),
      'updatedAt': item.updatedAt.toIso8601String(),
      'createdBy': item.createdBy,
      'modifiedBy': item.modifiedBy,
      'firebaseId': item.firebaseId,
    };
  }

  // Firestore Snapshot → Drift Companion
  static db.TerrainsCompanion toCompanion(
    String docId,
    Map<String, dynamic> data,
  ) {
    DateTime parseTimestamp(dynamic ts) {
      if (ts is Timestamp) return ts.toDate();
      if (ts is String) return DateTime.tryParse(ts) ?? DateTime.now();
      return DateTime.now();
    }

    return db.TerrainsCompanion(
      nom: drift.Value(data['nom'] as String? ?? ''),
      type: drift.Value(data['type'] as int? ?? 0),
      status: drift.Value(data['status'] as String? ?? 'playable'),
      imageUrl: data['photoUrl'] != null
          ? drift.Value(data['photoUrl'] as String)
          : const drift.Value.absent(),
      firebaseId: drift.Value(docId),
      remoteId: drift.Value(docId),
      createdAt: drift.Value(parseTimestamp(data['createdAt'])),
      updatedAt: drift.Value(parseTimestamp(data['updatedAt'])),
      createdBy: data['createdBy'] != null
          ? drift.Value(data['createdBy'] as String)
          : const drift.Value.absent(),
      modifiedBy: data['modifiedBy'] != null
          ? drift.Value(data['modifiedBy'] as String)
          : const drift.Value.absent(),
      location: data['location'] != null
          ? drift.Value(data['location'] as String)
          : const drift.Value.absent(),
      capacity: data['capacity'] != null
          ? drift.Value(data['capacity'] as int)
          : const drift.Value.absent(),
      pricePerHour: data['pricePerHour'] != null
          ? drift.Value((data['pricePerHour'] as num).toDouble())
          : const drift.Value.absent(),
      available: drift.Value(data['available'] as bool? ?? true),
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
extension TerrainMapperX on Terrain {
  db.TerrainsCompanion toCompanion({bool includeId = false}) {
    return db.TerrainsCompanion(
      id: includeId && id != 0 ? drift.Value(id) : const drift.Value.absent(),
      nom: drift.Value(nom),
      type: drift.Value(type.index), // Assuming index for enum in DB
      status: drift.Value(status.name),
      imageUrl: photoUrl == null
          ? const drift.Value.absent()
          : drift.Value(photoUrl),
      firebaseId: firebaseId == null
          ? const drift.Value.absent()
          : drift.Value(firebaseId),
      createdAt: drift.Value(createdAt),
      updatedAt: drift.Value(updatedAt),
      createdBy: createdBy == null
          ? const drift.Value.absent()
          : drift.Value(createdBy),
      modifiedBy: modifiedBy == null
          ? const drift.Value.absent()
          : drift.Value(modifiedBy),
      // Mapped remoteId fallback if needed
      remoteId: firebaseId == null
          ? const drift.Value.absent()
          : drift.Value(firebaseId),
    );
  }
}
