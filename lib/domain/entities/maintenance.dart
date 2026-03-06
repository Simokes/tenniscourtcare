// lib/domain/entities/maintenance.dart
import './weather_snapshot.dart';

class Maintenance {
  final int? id;
  final int terrainId;
  final String type;
  final String? commentaire;
  final int date; // epoch ms

  final int sacsMantoUtilises;
  final int sacsSottomantoUtilises;
  final int sacsSiliceUtilises;

  /// Indique si la maintenance est planifiée dans le futur (true) ou déjà réalisée (false)
  final bool isPlanned;

  /// Chemin vers la photo de preuve (optionnel)
  final String? imagePath;

  /// Snapshot météo au moment de la maintenance (optionnel)
  final WeatherSnapshot? weather;

  /// Drapeaux métier (optionnels)
  final bool? terrainGele; // true si T<=0°C au moment de l'opération
  final bool? terrainImpraticable; // selon heuristique pluie/humidité/terrain

  // Sync fields
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? firebaseId;
  final String? createdBy;
  final String? modifiedBy;

  Maintenance({
    this.id,
    required this.terrainId,
    required this.type,
    this.commentaire,
    required this.date,
    required this.sacsMantoUtilises,
    required this.sacsSottomantoUtilises,
    required this.sacsSiliceUtilises,
    this.isPlanned = false,
    this.imagePath,
    this.weather,
    this.terrainGele,
    this.terrainImpraticable,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.firebaseId,
    this.createdBy,
    this.modifiedBy,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Maintenance copyWith({
    int? id,
    int? terrainId,
    String? type,
    String? commentaire,
    int? date,
    int? sacsMantoUtilises,
    int? sacsSottomantoUtilises,
    int? sacsSiliceUtilises,
    bool? isPlanned,
    String? imagePath,
    WeatherSnapshot? weather,
    bool? terrainGele,
    bool? terrainImpraticable,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? firebaseId,
    String? createdBy,
    String? modifiedBy,
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
      isPlanned: isPlanned ?? this.isPlanned,
      imagePath: imagePath ?? this.imagePath,
      weather: weather ?? this.weather,
      terrainGele: terrainGele ?? this.terrainGele,
      terrainImpraticable: terrainImpraticable ?? this.terrainImpraticable,
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
      other is Maintenance &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          terrainId == other.terrainId &&
          type == other.type &&
          commentaire == other.commentaire &&
          date == other.date &&
          sacsMantoUtilises == other.sacsMantoUtilises &&
          sacsSottomantoUtilises == other.sacsSottomantoUtilises &&
          sacsSiliceUtilises == other.sacsSiliceUtilises &&
          isPlanned == other.isPlanned &&
          imagePath == other.imagePath &&
          weather == other.weather &&
          terrainGele == other.terrainGele &&
          terrainImpraticable == other.terrainImpraticable &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          firebaseId == other.firebaseId &&
          createdBy == other.createdBy &&
          modifiedBy == other.modifiedBy;

  @override
  int get hashCode =>
      id.hashCode ^
      terrainId.hashCode ^
      type.hashCode ^
      commentaire.hashCode ^
      date.hashCode ^
      sacsMantoUtilises.hashCode ^
      sacsSottomantoUtilises.hashCode ^
      sacsSiliceUtilises.hashCode ^
      isPlanned.hashCode ^
      imagePath.hashCode ^
      weather.hashCode ^
      terrainGele.hashCode ^
      terrainImpraticable.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      firebaseId.hashCode ^
      createdBy.hashCode ^
      modifiedBy.hashCode;

  @override
  String toString() =>
      'Maintenance(id: $id, terrainId: $terrainId, type: $type, date: $date, '
      'manto: $sacsMantoUtilises, sotto: $sacsSottomantoUtilises, silice: $sacsSiliceUtilises, '
      'isPlanned: $isPlanned, imagePath: $imagePath, '
      'weather: $weather, gele: $terrainGele, impraticable: $terrainImpraticable, '
      'createdAt: $createdAt, updatedAt: $updatedAt)';
}
