import 'package:cloud_firestore/cloud_firestore.dart';
// filepath: lib/data/mappers/maintenance_mapper.dart

import 'package:drift/drift.dart' as drift;
import 'package:tenniscourtcare/data/database/app_database.dart' as db;
import 'package:tenniscourtcare/data/database/app_database.dart';
import 'package:tenniscourtcare/data/mappers/maintenance_model.dart';
import 'package:tenniscourtcare/domain/entities/maintenance.dart';
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
      isPlanned: model.isPlanned,
      startHour: model.startHour,
      durationMinutes: model.durationMinutes,
      imagePath: model.imagePath,
      weather: model.weather != null
          ? WeatherSnapshot.fromJson(model.weather!)
          : null,
      terrainGele: model.terrainGele,
      terrainImpraticable: model.terrainImpraticable,
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
      isPlanned: domain.isPlanned,
      startHour: domain.startHour,
      durationMinutes: domain.durationMinutes,
      imagePath: domain.imagePath,
      weather: domain.weather?.toJson(),
      terrainGele: domain.terrainGele,
      terrainImpraticable: domain.terrainImpraticable,
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
      isPlanned: driftEntity.isPlanned,
      startHour: driftEntity.startHour,
      durationMinutes: driftEntity.durationMinutes,
      imagePath: driftEntity.imagePath,
      // Weather and flags are not stored in SQLite currently
      weather: null,
      terrainGele: null,
      terrainImpraticable: null,
      createdAt: driftEntity.createdAt,
      updatedAt: driftEntity.updatedAt,
      firebaseId: driftEntity.firebaseId,
      createdBy: driftEntity.createdBy,
      modifiedBy: driftEntity.modifiedBy,
    );
  }

  // Domain Entity → Firestore Map
  static Map<String, dynamic> toFirestore(Maintenance item) {
    return {
      'terrainId': item.terrainId,
      'type': item.type,
      'commentaire': item.commentaire,
      'date': item.date,
      'sacsMantoUtilises': item.sacsMantoUtilises,
      'sacsSottomantoUtilises': item.sacsSottomantoUtilises,
      'sacsSiliceUtilises': item.sacsSiliceUtilises,
      'isPlanned': item.isPlanned,
      'startHour': item.startHour,
      'durationMinutes': item.durationMinutes,
      'imagePath': item.imagePath,
      'weather': item.weather?.toJson(),
      'terrainGele': item.terrainGele,
      'terrainImpraticable': item.terrainImpraticable,
      'createdAt': item.createdAt.toIso8601String(),
      'updatedAt': item.updatedAt.toIso8601String(),
      'createdBy': item.createdBy,
      'modifiedBy': item.modifiedBy,
      'firebaseId': item.firebaseId,
    };
  }

  // Firestore Snapshot → Drift Companion
   static db.MaintenancesCompanion toCompanion(
    String docId,
    Map<String, dynamic> data,
  ) {
    DateTime parseTimestamp(dynamic ts) {
      if (ts is Timestamp) return ts.toDate();
      if (ts is String) return DateTime.tryParse(ts) ?? DateTime.now();
      return DateTime.now();
    }

    return db.MaintenancesCompanion(
      terrainId: drift.Value(data['terrainId'] as int? ?? 0),
      type: drift.Value(data['type'] as String? ?? 'entretien'),
      commentaire: data['commentaire'] != null
          ? drift.Value(data['commentaire'] as String)
          : const drift.Value.absent(),
      date: drift.Value(data['date'] as int? ?? DateTime.now().millisecondsSinceEpoch),
      sacsMantoUtilises: drift.Value(data['sacsMantoUtilises'] as int? ?? 0),
      sacsSottomantoUtilises: drift.Value(data['sacsSottomantoUtilises'] as int? ?? 0),
      sacsSiliceUtilises: drift.Value(data['sacsSiliceUtilises'] as int? ?? 0),
      isPlanned: drift.Value(data['isPlanned'] as bool? ?? false),
      startHour: drift.Value(data['startHour'] as int? ?? 8),
      durationMinutes: drift.Value(data['durationMinutes'] as int? ?? 60),
      imagePath: data['imagePath'] != null
          ? drift.Value(data['imagePath'] as String)
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
      isPlanned: drift.Value(isPlanned),
      startHour: drift.Value(startHour),
      durationMinutes: drift.Value(durationMinutes),
      imagePath: imagePath == null
          ? const drift.Value.absent()
          : drift.Value(imagePath),
      remoteId: firebaseId == null
          ? const drift.Value.absent()
          : drift.Value(firebaseId),
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
