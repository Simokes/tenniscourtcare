// filepath: lib/infrastructure/weather/weather_service.dart

import '../../domain/entities/weather_snapshot.dart';
import '../../domain/entities/daily_forecast.dart';

/// Weather context for terrain-specific weather data
class WeatherContext {
  final String terrainId;
  final String? weatherCondition;
  final double? temperature;
  final double? humidity;
  final int? windSpeed;

  WeatherContext({
    required this.terrainId,
    this.weatherCondition,
    this.temperature,
    this.humidity,
    this.windSpeed,
  });

  factory WeatherContext.empty(String terrainId) {
    return WeatherContext(
      terrainId: terrainId,
      weatherCondition: null,
      temperature: null,
      humidity: null,
      windSpeed: null,
    );
  }

  // Compatibility getters for existing code
  WeatherSnapshot get snapshot => WeatherSnapshot(
        temperature: temperature ?? 0.0,
        precipitation: 0.0,
        humidity: (humidity ?? 0).toInt(),
        windSpeed: (windSpeed ?? 0).toDouble(),
        weatherCode: 0,
      );

  double get precipitationLast24h => 0.0;

  List<DailyForecast> get dailyForecasts => [];
}

/// Service for fetching and managing weather data
abstract class WeatherService {
  /// Get weather for a specific terrain
  Future<WeatherContext> getWeatherForTerrain(String terrainId);

  /// Get current weather conditions
  Future<String?> getCurrentCondition(String terrainId);

  /// Check if weather is suitable for play
  Future<bool> isSuitableForPlay(String terrainId);

  /// Legacy fetch method for compatibility
  Future<WeatherContext> fetch({required double latitude, required double longitude});
}

/// Mock implementation of WeatherService
class MockWeatherService implements WeatherService {
  @override
  Future<WeatherContext> getWeatherForTerrain(String terrainId) async {
    return WeatherContext.empty(terrainId);
  }

  @override
  Future<String?> getCurrentCondition(String terrainId) async {
    return 'Sunny';
  }

  @override
  Future<bool> isSuitableForPlay(String terrainId) async {
    return true;
  }

  @override
  Future<WeatherContext> fetch({required double latitude, required double longitude}) async {
    return getWeatherForTerrain('club_location');
  }
}
