// filepath: lib/data/models/maintenance_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tenniscourtcare/domain/entities/maintenance.dart';
import 'package:tenniscourtcare/domain/entities/sync_status.dart';
import 'package:tenniscourtcare/domain/entities/weather_snapshot.dart';

class MaintenanceModel {
  final int? id;
  final int terrainId;
  final String type;
  final String? commentaire;
  final String date; // ISO8601 String (from int epoch)

  final int sacsMantoUtilises;
  final int sacsSottomantoUtilises;
  final int sacsSiliceUtilises;

  final String? imagePath;
  final Map<String, dynamic>? weather; // JSON ready

  final bool? terrainGele;
  final bool? terrainImpraticable;

  // Sync fields
  final String syncStatus;
  final String createdAt;
  final String updatedAt;
  final String? firebaseId;
  final String? createdBy;
  final String? modifiedBy;

  const MaintenanceModel({
    this.id,
    required this.terrainId,
    required this.type,
    this.commentaire,
    required this.date,
    required this.sacsMantoUtilises,
    required this.sacsSottomantoUtilises,
    required this.sacsSiliceUtilises,
    this.imagePath,
    this.weather,
    this.terrainGele,
    this.terrainImpraticable,
    required this.syncStatus,
    required this.createdAt,
    required this.updatedAt,
    this.firebaseId,
    this.createdBy,
    this.modifiedBy,
  });

  /// Firestore → Model
  factory MaintenanceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = 0; // Local ID (placeholder)
    data['firebaseId'] = doc.id;
    return MaintenanceModel.fromJson(data);
  }

  /// JSON → Model
  factory MaintenanceModel.fromJson(Map<String, dynamic> json) {
    return MaintenanceModel(
      id: json['id'] as int?,
      terrainId: json['terrainId'] as int,
      type: json['type'] as String,
      commentaire: json['commentaire'] as String?,
      date: json['date'] as String,
      sacsMantoUtilises: json['sacsMantoUtilises'] as int,
      sacsSottomantoUtilises: json['sacsSottomantoUtilises'] as int,
      sacsSiliceUtilises: json['sacsSiliceUtilises'] as int,
      imagePath: json['imagePath'] as String?,
      weather: json['weather'] as Map<String, dynamic>?,
      terrainGele: json['terrainGele'] as bool?,
      terrainImpraticable: json['terrainImpraticable'] as bool?,
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
      'terrainId': terrainId,
      'type': type,
      'commentaire': commentaire,
      'date': date,
      'sacsMantoUtilises': sacsMantoUtilises,
      'sacsSottomantoUtilises': sacsSottomantoUtilises,
      'sacsSiliceUtilises': sacsSiliceUtilises,
      'imagePath': imagePath,
      'weather': weather,
      'terrainGele': terrainGele,
      'terrainImpraticable': terrainImpraticable,
      'syncStatus': syncStatus,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'firebaseId': firebaseId,
      'createdBy': createdBy,
      'modifiedBy': modifiedBy,
    };
  }

  /// Model → Domain Entity
  Maintenance toDomain() {
    return Maintenance(
      id: id,
      terrainId: terrainId,
      type: type,
      commentaire: commentaire,
      date: DateTime.parse(date).millisecondsSinceEpoch,
      sacsMantoUtilises: sacsMantoUtilises,
      sacsSottomantoUtilises: sacsSottomantoUtilises,
      sacsSiliceUtilises: sacsSiliceUtilises,
      imagePath: imagePath,
      weather: weather != null ? WeatherSnapshot.fromJson(weather!) : null,
      terrainGele: terrainGele,
      terrainImpraticable: terrainImpraticable,
      syncStatus: SyncStatus.fromString(syncStatus),
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
      firebaseId: firebaseId,
      createdBy: createdBy,
      modifiedBy: modifiedBy,
    );
  }

  /// Domain Entity → Model
  factory MaintenanceModel.fromDomain(Maintenance maintenance) {
    return MaintenanceModel(
      id: maintenance.id,
      terrainId: maintenance.terrainId,
      type: maintenance.type,
      commentaire: maintenance.commentaire,
      date: DateTime.fromMillisecondsSinceEpoch(
        maintenance.date,
      ).toIso8601String(),
      sacsMantoUtilises: maintenance.sacsMantoUtilises,
      sacsSottomantoUtilises: maintenance.sacsSottomantoUtilises,
      sacsSiliceUtilises: maintenance.sacsSiliceUtilises,
      imagePath: maintenance.imagePath,
      weather: maintenance.weather?.toJson(),
      terrainGele: maintenance.terrainGele,
      terrainImpraticable: maintenance.terrainImpraticable,
      syncStatus: maintenance.syncStatus.name,
      createdAt: maintenance.createdAt.toIso8601String(),
      updatedAt: maintenance.updatedAt.toIso8601String(),
      firebaseId: maintenance.firebaseId,
      createdBy: maintenance.createdBy,
      modifiedBy: maintenance.modifiedBy,
    );
  }
}
