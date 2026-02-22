// lib/infrastructure/weather/weather_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../domain/entities/daily_forecast.dart';
import '../../domain/entities/weather_snapshot.dart';

class WeatherContext {
  final WeatherSnapshot snapshot;
  final double precipitationLast24h; // mm
  final List<DailyForecast> dailyForecasts;
  const WeatherContext(this.snapshot, this.precipitationLast24h, {this.dailyForecasts = const []});
}

class WeatherService {
  final http.Client _client;
  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  /// Récupère météo actuelle + historique horaire pour calculer la pluie 24h.
  Future<WeatherContext> fetch({
    required double latitude,
    required double longitude,
    DateTime? now,
    String timezone = 'auto',
  }) async {
    final dt = now ?? DateTime.now().toUtc();

    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$latitude'
      '&longitude=$longitude'
      '&timezone=$timezone'
      '&current=temperature_2m,precipitation,relative_humidity_2m,wind_speed_10m,weather_code'
      '&hourly=precipitation'
      '&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum'
      '&past_days=1'
      '&forecast_days=4',
    );

    final resp = await _client.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('Open-Meteo error ${resp.statusCode}');
    }

    final json = jsonDecode(resp.body) as Map<String, dynamic>;

    // --- current ---
    final current = json['current'] as Map<String, dynamic>;
    final temp = (current['temperature_2m'] as num).toDouble();
    final precipInstant = (current['precipitation'] as num).toDouble();
    final humidity = (current['relative_humidity_2m'] as num).toInt();
    final wind = (current['wind_speed_10m'] as num).toDouble();
    final code = (current['weather_code'] as num).toInt();

    final snapshot = WeatherSnapshot(
      temperature: temp,
      precipitation: precipInstant,
      humidity: humidity,
      windSpeed: wind,
      weatherCode: code,
    );

    // --- hourly precipitation → somme des 24 dernières heures ---
    final hourly = json['hourly'] as Map<String, dynamic>;
    final times = (hourly['time'] as List).cast<String>();
    final precips = (hourly['precipitation'] as List).cast<num>();

    final end = dt;
    final start = end.subtract(const Duration(hours: 24));
    double sum24 = 0.0;

    for (var i = 0; i < times.length; i++) {
      final t = DateTime.parse(times[i]).toUtc();
      if (!t.isBefore(start) && !t.isAfter(end)) {
        sum24 += precips[i].toDouble();
      }
    }

    // --- daily forecast ---
    final daily = json['daily'] as Map<String, dynamic>;
    final dailyTimes = (daily['time'] as List).cast<String>();
    final dailyCodes = (daily['weather_code'] as List).cast<num>();
    final dailyMax = (daily['temperature_2m_max'] as List).cast<num>();
    final dailyMin = (daily['temperature_2m_min'] as List).cast<num>();
    final dailyPrecip = (daily['precipitation_sum'] as List).cast<num>();

    final forecasts = <DailyForecast>[];
    // Start from index 1 (tomorrow) for 3 days, or include today if preferred.
    // Let's include today + 2 days, or tomorrow + 2 days.
    // Requirement says "sur 3 jours". Usually implies Forecast (Tomorrow, Day+2, Day+3).
    // Or Today, Tomorrow, Day+2. Let's do Today + 3 days to be safe and let UI filter.
    for (var i = 0; i < dailyTimes.length; i++) {
      forecasts.add(DailyForecast(
        date: DateTime.parse(dailyTimes[i]),
        weatherCode: dailyCodes[i].toInt(),
        tempMax: dailyMax[i].toDouble(),
        tempMin: dailyMin[i].toDouble(),
        precipitationSum: dailyPrecip[i].toDouble(),
      ));
    }

    return WeatherContext(snapshot, sum24, dailyForecasts: forecasts);
  }
}