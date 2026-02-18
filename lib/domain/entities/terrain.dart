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

  const Terrain({
    required this.id,
    required this.nom,
    required this.type,
  });

  Terrain copyWith({
    int? id,
    String? nom,
    TerrainType? type,
  }) {
    return Terrain(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      type: type ?? this.type,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Terrain &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          nom == other.nom &&
          type == other.type;

  @override
  int get hashCode => id.hashCode ^ nom.hashCode ^ type.hashCode;
}
