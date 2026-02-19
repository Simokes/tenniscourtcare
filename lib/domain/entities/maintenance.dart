// lib/domain/entities/maintenance.dart
import 'weather_snapshot.dart';

class Maintenance {
  final int? id;
  final int terrainId;
  final String type;
  final String? commentaire;
  final int date; // epoch ms

  final int sacsMantoUtilises;
  final int sacsSottomantoUtilises;
  final int sacsSiliceUtilises;

  /// Snapshot météo au moment de la maintenance (optionnel)
  final WeatherSnapshot? weather;

  /// Drapeaux métier (optionnels)
  final bool? terrainGele;          // true si T<=0°C au moment de l'opération
  final bool? terrainImpraticable;  // selon heuristique pluie/humidité/terrain

  const Maintenance({
    this.id,
    required this.terrainId,
    required this.type,
    this.commentaire,
    required this.date,
    required this.sacsMantoUtilises,
    required this.sacsSottomantoUtilises,
    required this.sacsSiliceUtilises,
    this.weather,
    this.terrainGele,
    this.terrainImpraticable,
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
    WeatherSnapshot? weather,
    bool? terrainGele,
    bool? terrainImpraticable,
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
      weather: weather ?? this.weather,
      terrainGele: terrainGele ?? this.terrainGele,
      terrainImpraticable: terrainImpraticable ?? this.terrainImpraticable,
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
          weather == other.weather &&
          terrainGele == other.terrainGele &&
          terrainImpraticable == other.terrainImpraticable;

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
      weather.hashCode ^
      terrainGele.hashCode ^
      terrainImpraticable.hashCode;

  @override
  String toString() =>
      'Maintenance(id: $id, terrainId: $terrainId, type: $type, date: $date, '
      'manto: $sacsMantoUtilises, sotto: $sacsSottomantoUtilises, silice: $sacsSiliceUtilises, '
      'weather: $weather, gele: $terrainGele, impraticable: $terrainImpraticable)';
}