import 'package:cloud_firestore/cloud_firestore.dart';
// filepath: lib/data/mappers/event_mapper.dart

import 'package:drift/drift.dart' as drift;
import 'package:tenniscourtcare/data/database/app_database.dart' as db;

import 'package:tenniscourtcare/data/mappers/app_event_model.dart';
import 'package:tenniscourtcare/domain/entities/app_event.dart';

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
      id: driftEntity.id,
      title: driftEntity.title,
      description: driftEntity.description,
      startTime: driftEntity.startTime,
      endTime: driftEntity.endTime,
      color: driftEntity.color,
      terrainIds: driftEntity.terrainIds,
      createdAt: driftEntity.createdAt,
      updatedAt: driftEntity.updatedAt,
      firebaseId: driftEntity.firebaseId,
      createdBy: driftEntity.createdBy,
      modifiedBy: driftEntity.modifiedBy,
    );
  }

  // Domain Entity → Firestore Map
  static Map<String, dynamic> toFirestore(AppEvent item) {
    return {
      'title': item.title,
      if (item.description != null) 'description': item.description,
      'startTime': Timestamp.fromDate(item.startTime),
      'endTime': Timestamp.fromDate(item.endTime),
      'color': item.color,
      'terrainIds': item.terrainIds,
      'createdAt': Timestamp.fromDate(item.createdAt),
      'updatedAt': Timestamp.fromDate(item.updatedAt),
      if (item.createdBy != null) 'createdBy': item.createdBy,
      if (item.modifiedBy != null) 'modifiedBy': item.modifiedBy,
    };
  }

  // Firestore Snapshot → Drift Companion
  static db.EventsCompanion toCompanion(
    String docId,
    Map<String, dynamic> data,
  ) {
    DateTime parseTimestamp(dynamic ts) {
      if (ts is Timestamp) return ts.toDate();
      if (ts is String) return DateTime.tryParse(ts) ?? DateTime.now();
      return DateTime.now();
    }

    return db.EventsCompanion(
      title: drift.Value(data['title'] as String? ?? ''),
      description: data['description'] != null
          ? drift.Value(data['description'] as String)
          : const drift.Value.absent(),
      startTime: drift.Value(parseTimestamp(data['startTime'])),
      endTime: drift.Value(parseTimestamp(data['endTime'])),
      color: drift.Value(data['color'] as int? ?? 0xFFFFFFFF),
      terrainIds: drift.Value(
        (data['terrainIds'] as List<dynamic>?)
                ?.map((e) => int.tryParse(e.toString()) ?? 0)
                .where((id) => id != 0)
                .toList() ??
            [],
      ),
      firebaseId: drift.Value(docId),
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
extension AppEventModelX on AppEventModel {
  AppEvent toDomain() => EventMapper.toDomain(this);
}

// Domain → Companion (Keeping for DB inserts)
extension AppEventMapperX on AppEvent {
  db.EventsCompanion toCompanion({bool includeId = true}) {
    return db.EventsCompanion(
      id: includeId && id != null
          ? drift.Value(id!)
          : const drift.Value.absent(),
      title: drift.Value(title),
      description: description == null
          ? const drift.Value.absent()
          : drift.Value(description),
      startTime: drift.Value(startTime),
      endTime: drift.Value(endTime),
      color: drift.Value(color),
      terrainIds: drift.Value(terrainIds),
      // Sync mappings
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
