// lib/domain/entities/terrain.dart

import 'package:flutter/material.dart';
import 'sync_status.dart';

enum TerrainType {
  terreBattue,
  synthetique,
  dur;

  String get displayName {
    switch (this) {
      case TerrainType.terreBattue:
        return 'Terre battue';
      case TerrainType.synthetique:
        return 'Synthétique';
      case TerrainType.dur:
        return 'Dur';
    }
  }
}

enum TerrainStatus {
  playable,      // 🟢 Jouable - prêt à jouer
  maintenance,   // 🔵 Maintenance - en entretien
  unavailable,   // ❌ Non jouable - fermé/endommagé
  frozen;        // 🥶 Gelé - gelé/pluie/neige

  String get displayName {
    switch (this) {
      case TerrainStatus.playable:
        return 'Jouable';
      case TerrainStatus.maintenance:
        return 'Maintenance';
      case TerrainStatus.unavailable:
        return 'Non jouable';
      case TerrainStatus.frozen:
        return 'Gelé';
    }
  }

  Color get color {
    switch (this) {
      case TerrainStatus.playable:
        return const Color(0xFF10B981);  // Vert
      case TerrainStatus.maintenance:
        return const Color(0xFF0EA5E9);  // Bleu ciel
      case TerrainStatus.unavailable:
        return const Color(0xFF6B7280);  // Gris
      case TerrainStatus.frozen:
        return const Color(0xFF3B82F6);  // Bleu
    }
  }

  IconData get icon {
    switch (this) {
      case TerrainStatus.playable:
        return Icons.check_circle;
      case TerrainStatus.maintenance:
        return Icons.build;
      case TerrainStatus.unavailable:
        return Icons.cancel;
      case TerrainStatus.frozen:
        return Icons.ac_unit;
    }
  }
}

class Terrain {
  final int id;
  final String nom;
  final TerrainType type;
  final TerrainStatus status;

  /// Coordonnées GPS facultatives (pour la météo)
  final double? latitude;
  final double? longitude;
  final String? photoUrl;

  // Sync fields
  final SyncStatus syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? firebaseId;
  final String? createdBy;
  final String? modifiedBy;

  const Terrain({
    required this.id,
    required this.nom,
    required this.type,
    required this.status,
    this.latitude,
    this.longitude,
    this.photoUrl,
    this.syncStatus = SyncStatus.local,
    required this.createdAt,
    required this.updatedAt,
    this.firebaseId,
    this.createdBy,
    this.modifiedBy,
  });

  // Computed property for backwards compatibility / utility
  bool get isUnderMaintenance => status == TerrainStatus.maintenance;

  Terrain copyWith({
    int? id,
    String? nom,
    TerrainType? type,
    TerrainStatus? status,
    double? latitude,
    double? longitude,
    String? photoUrl,
    SyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? firebaseId,
    String? createdBy,
    String? modifiedBy,
  }) {
    return Terrain(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      type: type ?? this.type,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      photoUrl: photoUrl ?? this.photoUrl,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      firebaseId: firebaseId ?? this.firebaseId,
      createdBy: createdBy ?? this.createdBy,
      modifiedBy: modifiedBy ?? this.modifiedBy,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Terrain &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          nom == other.nom &&
          type == other.type &&
          status == other.status &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          photoUrl == other.photoUrl &&
          syncStatus == other.syncStatus &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          firebaseId == other.firebaseId &&
          createdBy == other.createdBy &&
          modifiedBy == other.modifiedBy;

  @override
  int get hashCode =>
      id.hashCode ^
      nom.hashCode ^
      type.hashCode ^
      status.hashCode ^
      latitude.hashCode ^
      longitude.hashCode ^
      photoUrl.hashCode ^
      syncStatus.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      firebaseId.hashCode ^
      createdBy.hashCode ^
      modifiedBy.hashCode;

  @override
  String toString() =>
      'Terrain(id: $id, nom: $nom, type: $type, status: $status, lat: $latitude, lon: $longitude, photoUrl: $photoUrl, syncStatus: $syncStatus, createdAt: $createdAt, updatedAt: $updatedAt)';
}
