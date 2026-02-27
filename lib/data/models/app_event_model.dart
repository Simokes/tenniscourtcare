// filepath: lib/data/models/app_event_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tenniscourtcare/domain/entities/app_event.dart';
import 'package:tenniscourtcare/domain/entities/sync_status.dart';

class AppEventModel {
  final int? id;
  final String title;
  final String? description;
  final String startTime; // ISO8601
  final String endTime; // ISO8601
  final int color;
  final List<int> terrainIds;

  // Sync fields
  final String syncStatus;
  final String createdAt; // ISO8601
  final String updatedAt; // ISO8601
  final String? firebaseId;
  final String? createdBy;
  final String? modifiedBy;

  const AppEventModel({
    this.id,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    required this.color,
    required this.terrainIds,
    required this.syncStatus,
    required this.createdAt,
    required this.updatedAt,
    this.firebaseId,
    this.createdBy,
    this.modifiedBy,
  });

  /// Firestore → Model
  factory AppEventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = 0; // Local ID
    data['firebaseId'] = doc.id;
    return AppEventModel.fromJson(data);
  }

  /// JSON → Model
  factory AppEventModel.fromJson(Map<String, dynamic> json) {
    return AppEventModel(
      id: json['id'] as int?,
      title: json['title'] as String,
      description: json['description'] as String?,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      color: json['color'] as int,
      terrainIds: (json['terrainIds'] as List<dynamic>)
          .map((e) => e as int)
          .toList(),
      syncStatus: json['syncStatus'] as String? ?? 'LOCAL',
      createdAt:
          json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt:
          json['updatedAt'] as String? ?? DateTime.now().toIso8601String(),
      firebaseId: json['firebaseId'] as String?,
      createdBy: json['createdBy'] as String?,
      modifiedBy: json['modifiedBy'] as String?,
    );
  }

  /// Model → JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startTime': startTime,
      'endTime': endTime,
      'color': color,
      'terrainIds': terrainIds,
      'syncStatus': syncStatus,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'firebaseId': firebaseId,
      'createdBy': createdBy,
      'modifiedBy': modifiedBy,
    };
  }

  /// Model → Domain Entity
  AppEvent toDomain() {
    return AppEvent(
      id: id,
      title: title,
      description: description,
      startTime: DateTime.parse(startTime),
      endTime: DateTime.parse(endTime),
      color: color,
      terrainIds: terrainIds,
      syncStatus: SyncStatus.fromString(syncStatus),
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
      firebaseId: firebaseId,
      createdBy: createdBy,
      modifiedBy: modifiedBy,
    );
  }

  /// Domain Entity → Model
  factory AppEventModel.fromDomain(AppEvent appEvent) {
    return AppEventModel(
      id: appEvent.id,
      title: appEvent.title,
      description: appEvent.description,
      startTime: appEvent.startTime.toIso8601String(),
      endTime: appEvent.endTime.toIso8601String(),
      color: appEvent.color,
      terrainIds: appEvent.terrainIds,
      syncStatus: appEvent.syncStatus.name,
      createdAt: appEvent.createdAt.toIso8601String(),
      updatedAt: appEvent.updatedAt.toIso8601String(),
      firebaseId: appEvent.firebaseId,
      createdBy: appEvent.createdBy,
      modifiedBy: appEvent.modifiedBy,
    );
  }
}
