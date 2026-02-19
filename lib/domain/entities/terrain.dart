// lib/domain/entities/terrain.dart

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

class Terrain {
  final int id;
  final String nom;
  final TerrainType type;

  /// Coordonnées GPS facultatives (pour la météo)
  final double? latitude;
  final double? longitude;

  const Terrain({
    required this.id,
    required this.nom,
    required this.type,
    this.latitude,
    this.longitude,
  });

  Terrain copyWith({
    int? id,
    String? nom,
    TerrainType? type,
    double? latitude,
    double? longitude,
  }) {
    return Terrain(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      type: type ?? this.type,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
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
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode =>
      id.hashCode ^
      nom.hashCode ^
      type.hashCode ^
      latitude.hashCode ^
      longitude.hashCode;

  @override
  String toString() =>
      'Terrain(id: $id, nom: $nom, type: $type, lat: $latitude, lon: $longitude)';
}
