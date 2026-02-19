// lib/domain/entities/weather_snapshot.dart

class WeatherSnapshot {
  final double temperature;     // °C
  final double precipitation;   // mm instantanée (au pas horaire)
  final int humidity;           // %
  final double windSpeed;       // km/h
  final int weatherCode;        // code Open‑Meteo

  const WeatherSnapshot({
    required this.temperature,
    required this.precipitation,
    required this.humidity,
    required this.windSpeed,
    required this.weatherCode,
  });

  WeatherSnapshot copyWith({
    double? temperature,
    double? precipitation,
    int? humidity,
    double? windSpeed,
    int? weatherCode,
  }) {
    return WeatherSnapshot(
      temperature: temperature ?? this.temperature,
      precipitation: precipitation ?? this.precipitation,
      humidity: humidity ?? this.humidity,
      windSpeed: windSpeed ?? this.windSpeed,
      weatherCode: weatherCode ?? this.weatherCode,
    );
  }

  Map<String, dynamic> toJson() => {
        'temperature': temperature,
        'precipitation': precipitation,
        'humidity': humidity,
        'windSpeed': windSpeed,
        'weatherCode': weatherCode,
      };

  factory WeatherSnapshot.fromJson(Map<String, dynamic> json) {
    return WeatherSnapshot(
      temperature: (json['temperature'] as num).toDouble(),
      precipitation: (json['precipitation'] as num).toDouble(),
      humidity: (json['humidity'] as num).toInt(),
      windSpeed: (json['windSpeed'] as num).toDouble(),
      weatherCode: (json['weatherCode'] as num).toInt(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeatherSnapshot &&
          runtimeType == other.runtimeType &&
          temperature == other.temperature &&
          precipitation == other.precipitation &&
          humidity == other.humidity &&
          windSpeed == other.windSpeed &&
          weatherCode == other.weatherCode;

  @override
  int get hashCode =>
      temperature.hashCode ^
      precipitation.hashCode ^
      humidity.hashCode ^
      windSpeed.hashCode ^
      weatherCode.hashCode;

  @override
  String toString() =>
      'WeatherSnapshot(T=${temperature.toStringAsFixed(1)}°C, P=${precipitation.toStringAsFixed(2)}mm, H=$humidity%, V=${windSpeed.toStringAsFixed(1)}km/h, code=$weatherCode)';
}
