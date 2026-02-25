// filepath: lib/data/mappers/event_mapper.dart

import 'package:drift/drift.dart';
import 'package:tenniscourtcare/data/database/app_database.dart' as db;
import 'package:tenniscourtcare/data/models/app_event_model.dart';
import 'package:tenniscourtcare/domain/entities/app_event.dart';
import 'package:tenniscourtcare/domain/entities/sync_status.dart';

class EventMapper {
  // Model → Domain Entity
  static AppEvent toDomain(AppEventModel model) {
    return AppEvent(
      id: model.id,
      title: model.title,
      description: model.description,
      startTime: DateTime.parse(model.startTime),
      endTime: DateTime.parse(model.endTime),
      color: model.color,
      terrainIds: model.terrainIds,
      syncStatus: SyncStatus.fromString(model.syncStatus),
      createdAt: DateTime.parse(model.createdAt),
      updatedAt: DateTime.parse(model.updatedAt),
      firebaseId: model.firebaseId,
      createdBy: model.createdBy,
      modifiedBy: model.modifiedBy,
    );
  }

  // Domain Entity → Model
  static AppEventModel toModel(AppEvent domain) {
    return AppEventModel(
      id: domain.id,
      title: domain.title,
      description: domain.description,
      startTime: domain.startTime.toIso8601String(),
      endTime: domain.endTime.toIso8601String(),
      color: domain.color,
      terrainIds: domain.terrainIds,
      syncStatus: domain.syncStatus.name,
      createdAt: domain.createdAt.toIso8601String(),
      updatedAt: domain.updatedAt.toIso8601String(),
      firebaseId: domain.firebaseId,
      createdBy: domain.createdBy,
      modifiedBy: domain.modifiedBy,
    );
  }

  // Drift Entity → Domain Entity
  static AppEvent fromDriftEntity(db.EventRow driftEntity) {
    return AppEvent(
      id: driftEntity.id ?? 0,
      title: driftEntity.title,
      description: driftEntity.description,
      startTime: driftEntity.startTime,
      endTime: driftEntity.endTime,
      color: driftEntity.color,
      terrainIds: driftEntity.terrainIds,
      syncStatus: SyncStatus.fromString(driftEntity.syncStatus),
      createdAt: driftEntity.createdAt ?? DateTime.now(),
      updatedAt: driftEntity.updatedAt ?? DateTime.now(),
      firebaseId: driftEntity.firebaseId,
      createdBy: driftEntity.createdBy,
      modifiedBy: driftEntity.modifiedBy,
    );
  }
}

// Extensions for compatibility
extension AppEventModelX on AppEventModel {
  AppEvent toDomain() => EventMapper.toDomain(this);
}

extension EventDriftX on db.EventRow {
  AppEvent toDomain() => EventMapper.fromDriftEntity(this);
}

// Domain → Companion (Keeping for DB inserts)
extension AppEventDomainX on AppEvent {
  db.EventsCompanion toCompanion({bool includeId = true}) =>
      db.EventsCompanion(
        id: includeId ? Value(id) : const Value.absent(),
        title: Value(title),
        description: Value(description),
        startTime: Value(startTime),
        endTime: Value(endTime),
        color: Value(color),
        terrainIds: Value(terrainIds),
        // Sync mappings
        syncStatus: Value(syncStatus.name),
        createdAt: Value(createdAt),
        updatedAt: Value(updatedAt),
        firebaseId: Value(firebaseId),
        createdBy: Value(createdBy),
        modifiedBy: Value(modifiedBy),
      );
}
