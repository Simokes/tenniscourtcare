// filepath: lib/data/mappers/maintenance_mapper.dart

import 'package:drift/drift.dart' as drift;
import 'package:drift/drift.dart';
import 'package:tenniscourtcare/data/database/app_database.dart' as db;
import 'package:tenniscourtcare/data/database/app_database.dart';
import 'package:tenniscourtcare/data/models/maintenance_model.dart';
import 'package:tenniscourtcare/domain/entities/maintenance.dart';
import 'package:tenniscourtcare/domain/entities/sync_status.dart';
import 'package:tenniscourtcare/domain/entities/weather_snapshot.dart';

class MaintenanceMapper {
  // Model → Domain Entity
  static Maintenance toDomain(MaintenanceModel model) {
    return Maintenance(
      id: model.id,
      terrainId: model.terrainId,
      type: model.type,
      commentaire: model.commentaire,
      date: DateTime.parse(model.date).millisecondsSinceEpoch,
      sacsMantoUtilises: model.sacsMantoUtilises,
      sacsSottomantoUtilises: model.sacsSottomantoUtilises,
      sacsSiliceUtilises: model.sacsSiliceUtilises,
      imagePath: model.imagePath,
      weather: model.weather != null
          ? WeatherSnapshot.fromJson(model.weather!)
          : null,
      terrainGele: model.terrainGele,
      terrainImpraticable: model.terrainImpraticable,
      syncStatus: SyncStatus.fromString(model.syncStatus),
      createdAt: DateTime.parse(model.createdAt),
      updatedAt: DateTime.parse(model.updatedAt),
      firebaseId: model.firebaseId,
      createdBy: model.createdBy,
      modifiedBy: model.modifiedBy,
    );
  }

  // Domain Entity → Model
  static MaintenanceModel toModel(Maintenance domain) {
    return MaintenanceModel(
      id: domain.id,
      terrainId: domain.terrainId,
      type: domain.type,
      commentaire: domain.commentaire,
      date: DateTime.fromMillisecondsSinceEpoch(domain.date).toIso8601String(),
      sacsMantoUtilises: domain.sacsMantoUtilises,
      sacsSottomantoUtilises: domain.sacsSottomantoUtilises,
      sacsSiliceUtilises: domain.sacsSiliceUtilises,
      imagePath: domain.imagePath,
      weather: domain.weather?.toJson(),
      terrainGele: domain.terrainGele,
      terrainImpraticable: domain.terrainImpraticable,
      syncStatus: domain.syncStatus.name,
      createdAt: domain.createdAt.toIso8601String(),
      updatedAt: domain.updatedAt.toIso8601String(),
      firebaseId: domain.firebaseId,
      createdBy: domain.createdBy,
      modifiedBy: domain.modifiedBy,
    );
  }

  // Drift Entity → Domain Entity
  static Maintenance fromDriftEntity(db.MaintenanceRow driftEntity) {
    return Maintenance(
      id: driftEntity.id,
      terrainId: driftEntity.terrainId,
      type: driftEntity.type,
      commentaire: driftEntity.commentaire,
      date: driftEntity.date,
      sacsMantoUtilises: driftEntity.sacsMantoUtilises,
      sacsSottomantoUtilises: driftEntity.sacsSottomantoUtilises,
      sacsSiliceUtilises: driftEntity.sacsSiliceUtilises,
      imagePath: driftEntity.imagePath,
      // Weather and flags are not stored in SQLite currently
      weather: null,
      terrainGele: null,
      terrainImpraticable: null,
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
extension MaintenanceModelX on MaintenanceModel {
  Maintenance toDomain() => MaintenanceMapper.toDomain(this);
}

extension MaintenanceDriftX on db.MaintenanceRow {
  Maintenance toDomain() => MaintenanceMapper.fromDriftEntity(this);
}

// Domain → Companion (Keeping for DB inserts)
extension MaintenanceMapperX on Maintenance {
  MaintenancesCompanion toCompanion() {
    return MaintenancesCompanion(
      id: id == null ? const drift.Value.absent() : drift.Value(id!),
      terrainId: drift.Value(terrainId),
      type: drift.Value(type),
      commentaire: commentaire == null
          ? const drift.Value.absent()
          : drift.Value(commentaire),
      date: drift.Value(date),
      sacsMantoUtilises: drift.Value(sacsMantoUtilises),
      sacsSottomantoUtilises: drift.Value(sacsSottomantoUtilises),
      sacsSiliceUtilises: drift.Value(sacsSiliceUtilises),
      imagePath: imagePath == null
          ? const drift.Value.absent()
          : drift.Value(imagePath),
      remoteId: firebaseId == null
          ? const drift.Value.absent()
          : drift.Value(firebaseId),
      syncStatus: drift.Value(syncStatus.name),
      createdAt: drift.Value(createdAt),
      updatedAt: drift.Value(updatedAt),
      firebaseId: firebaseId == null
          ? const drift.Value.absent()
          : drift.Value(firebaseId),
      createdBy: createdBy == null
          ? const drift.Value.absent()
          : drift.Value(createdBy),
      modifiedBy: modifiedBy == null
          ? const drift.Value.absent()
          : drift.Value(modifiedBy),
    );
  }
}
