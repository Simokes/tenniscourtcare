// lib/domain/services/weather_rules.dart
import '../entities/terrain.dart';

class WeatherRules {
  /// Gel : T ≤ 0°C
  static bool isFrozen(double temperatureC) => temperatureC <= 0.0;

  /// Impraticable (heuristique simple) :
  /// - Terre battue : pluie 24h ≥ 5 mm OU humidité ≥ 85%
  /// - Synthétique : pluie 24h ≥ 15 mm
  /// - Dur : jamais (gestion manuelle au besoin)
  static bool isUnplayable({
    required TerrainType type,
    required double precipitationLast24hMm,
    required int humidityPct,
  }) {
    switch (type) {
      case TerrainType.terreBattue:
        return precipitationLast24hMm >= 5.0 || humidityPct >= 85;
      case TerrainType.synthetique:
        return precipitationLast24hMm >= 15.0;
      case TerrainType.dur:
        return false;
    }
  }
}
