// lib/domain/services/weather_rules.dart
import 'package:flutter/material.dart';

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

  /// Vent fort: windSpeed >= 40 km/h
  static bool isWindyStrong(double windSpeedKmh) => windSpeedKmh >= 40.0;

  /// Vent modéré: windSpeed >= 25 km/h
  static bool isWindyModerate(double windSpeedKmh) => windSpeedKmh >= 25.0;

  static String conditionLabel({
    required bool frozen,
    required bool unplayable,
    required bool windyStrong,
    required bool windyModerate,
    required double precipitation,
  }) {
    if (frozen) return 'Terrain gelé';
    if (unplayable && precipitation > 0) return 'Terrain impraticable';
    if (unplayable) return 'Terrain impraticable';
    if (windyStrong) return 'Conditions dégradées';
    if (windyModerate) return 'Vent modéré';
    return 'Conditions optimales';
  }

  static IconData conditionIcon({
    required bool frozen,
    required bool unplayable,
    required bool windyStrong,
    required bool windyModerate,
    required double precipitation,
  }) {
    if (frozen) return Icons.ac_unit;
    if (unplayable && precipitation > 0) return Icons.water_drop;
    if (unplayable) return Icons.warning_amber;
    if (windyStrong) return Icons.air;
    if (windyModerate) return Icons.air;
    return Icons.check_circle;
  }

  static Color conditionColor({
    required bool frozen,
    required bool unplayable,
    required bool windyStrong,
    required bool windyModerate,
  }) {
    if (frozen) return Colors.blue;
    if (unplayable) return Colors.red;
    if (windyStrong) return Colors.orange;
    if (windyModerate) return Colors.amber;
    return Colors.green;
  }

  static String forecastLabel({
    required double precipitationSum,
    required double tempMax,
    required double windSpeed,
  }) {
    if (tempMax <= 0) return 'Éviter — gel prévu';
    if (precipitationSum >= 5) {
      return 'Éviter — pluie prévue (${precipitationSum.toStringAsFixed(1)} mm)';
    }
    if (precipitationSum > 0) {
      return 'Prudence — pluie légère (${precipitationSum.toStringAsFixed(1)} mm)';
    }
    if (windSpeed >= 40) {
      return 'Conditions dégradées — vent fort (${windSpeed.toStringAsFixed(0)} km/h)';
    }
    if (windSpeed >= 25) {
      return 'Vent modéré (${windSpeed.toStringAsFixed(0)} km/h)';
    }
    return 'Conditions favorables';
  }
}
