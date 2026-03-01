// filepath: lib/data/models/terrain_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tenniscourtcare/domain/entities/terrain.dart';
import 'package:tenniscourtcare/domain/entities/sync_status.dart';

class TerrainModel {
  final int id;
  final String nom;
  final String type; // TerrainType.name
  final String status; // TerrainStatus.name
  final double? latitude;
  final double? longitude;
  final String? photoUrl;

  // Sync fields
  final String syncStatus;
  final String createdAt; // ISO8601
  final String updatedAt; // ISO8601
  final String? firebaseId;
  final String? createdBy;
  final String? modifiedBy;

  const TerrainModel({
    required this.id,
    required this.nom,
    required this.type,
    required this.status,
    this.latitude,
    this.longitude,
    this.photoUrl,
    required this.syncStatus,
    required this.createdAt,
    required this.updatedAt,
    this.firebaseId,
    this.createdBy,
    this.modifiedBy,
  });

  /// Firestore → Model
  factory TerrainModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    // Inject local ID as 0 (will be auto-incremented or ignored on update)
    // Inject firebaseId from doc.id
    data['id'] = 0;
    data['firebaseId'] = doc.id;
    return TerrainModel.fromJson(data);
  }

  /// JSON → Model
  factory TerrainModel.fromJson(Map<String, dynamic> json) {
    return TerrainModel(
      id: json['id'] as int,
      nom: json['nom'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      photoUrl: json['photoUrl'] as String?,
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
      'nom': nom,
      'type': type,
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'photoUrl': photoUrl,
      'syncStatus': syncStatus,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'firebaseId': firebaseId,
      'createdBy': createdBy,
      'modifiedBy': modifiedBy,
    };
  }

  /// Model → Domain Entity
  Terrain toDomain() {
    return Terrain(
      id: id,
      nom: nom,
      type: TerrainType.values.byName(type),
      status: TerrainStatus.values.byName(status),
      latitude: latitude,
      longitude: longitude,
      photoUrl: photoUrl,
      syncStatus: SyncStatus.fromString(syncStatus),
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
      firebaseId: firebaseId,
      createdBy: createdBy,
      modifiedBy: modifiedBy,
    );
  }

  /// Domain Entity → Model
  factory TerrainModel.fromDomain(Terrain terrain) {
    return TerrainModel(
      id: terrain.id,
      nom: terrain.nom,
      type: terrain.type.name,
      status: terrain.status.name,
      latitude: terrain.latitude,
      longitude: terrain.longitude,
      photoUrl: terrain.photoUrl,
      syncStatus: terrain.syncStatus.name,
      createdAt: terrain.createdAt.toIso8601String(),
      updatedAt: terrain.updatedAt.toIso8601String(),
      firebaseId: terrain.firebaseId,
      createdBy: terrain.createdBy,
      modifiedBy: terrain.modifiedBy,
    );
  }
}
