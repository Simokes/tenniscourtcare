class Maintenance {
  final int? id;
  final int terrainId;
  final String type;
  final String? commentaire;
  final int date; // epoch ms
  final int sacsMantoUtilises;
  final int sacsSottomantoUtilises;
  final int sacsSiliceUtilises;

  const Maintenance({
    this.id,
    required this.terrainId,
    required this.type,
    this.commentaire,
    required this.date,
    required this.sacsMantoUtilises,
    required this.sacsSottomantoUtilises,
    required this.sacsSiliceUtilises,
  });

  Maintenance copyWith({
    int? id,
    int? terrainId,
    String? type,
    String? commentaire,
    int? date,
    int? sacsMantoUtilises,
    int? sacsSottomantoUtilises,
    int? sacsSiliceUtilises,
  }) {
    return Maintenance(
      id: id ?? this.id,
      terrainId: terrainId ?? this.terrainId,
      type: type ?? this.type,
      commentaire: commentaire ?? this.commentaire,
      date: date ?? this.date,
      sacsMantoUtilises: sacsMantoUtilises ?? this.sacsMantoUtilises,
      sacsSottomantoUtilises:
          sacsSottomantoUtilises ?? this.sacsSottomantoUtilises,
      sacsSiliceUtilises: sacsSiliceUtilises ?? this.sacsSiliceUtilises,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Maintenance &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          terrainId == other.terrainId &&
          type == other.type &&
          commentaire == other.commentaire &&
          date == other.date &&
          sacsMantoUtilises == other.sacsMantoUtilises &&
          sacsSottomantoUtilises == other.sacsSottomantoUtilises &&
          sacsSiliceUtilises == other.sacsSiliceUtilises;

  @override
  int get hashCode =>
      id.hashCode ^
      terrainId.hashCode ^
      type.hashCode ^
      commentaire.hashCode ^
      date.hashCode ^
      sacsMantoUtilises.hashCode ^
      sacsSottomantoUtilises.hashCode ^
      sacsSiliceUtilises.hashCode;
}
