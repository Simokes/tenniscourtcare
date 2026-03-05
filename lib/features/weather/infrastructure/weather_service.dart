// lib/infrastructure/weather/weather_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:tenniscourtcare/domain/entities/daily_forecast.dart';
import 'package:tenniscourtcare/domain/entities/weather_snapshot.dart';
import 'package:tenniscourtcare/core/config/app_config.dart';

class WeatherContext {
  final WeatherSnapshot snapshot;
  final double precipitationLast24h; // mm
  final List<DailyForecast> dailyForecasts;
  final List<double> past30DaysPrecipitation; // mm per day
  final double precipitationLast30Days; // total mm

  const WeatherContext(
    this.snapshot,
    this.precipitationLast24h, {
    this.dailyForecasts = const [],
    this.past30DaysPrecipitation = const [],
    this.precipitationLast30Days = 0.0,
  });
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
      '${AppConfig.weatherApiBaseUrl}'
      '?latitude=$latitude'
      '&longitude=$longitude'
      '&timezone=$timezone'
      '&current=temperature_2m,precipitation,relative_humidity_2m,wind_speed_10m,weather_code'
      '&hourly=precipitation'
      '&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,windspeed_10m_max'
      '&past_days=30'
      '&forecast_days=7',
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

    // --- daily past history and forecast ---
    final daily = json['daily'] as Map<String, dynamic>;
    final dailyTimes = (daily['time'] as List).cast<String>();
    final dailyCodes = (daily['weather_code'] as List).cast<num>();
    final dailyMax = (daily['temperature_2m_max'] as List).cast<num>();
    final dailyMin = (daily['temperature_2m_min'] as List).cast<num>();
    final dailyPrecip = (daily['precipitation_sum'] as List).cast<num>();
    final dailyWindSpeed = (daily['windspeed_10m_max'] as List).cast<num>();

    final forecasts = <DailyForecast>[];
    final past30DaysPrecip = <double>[];
    double sum30 = 0.0;

    // Open-Meteo returns 'past_days' + 'today' + 'forecast_days - 1'
    // If we request past_days=30 and forecast_days=7, we get 37 days total.
    // The first 30 days are past history. The rest is today + 6 forecast days.

    final int todayIndex = dailyTimes.indexWhere((timeStr) {
      final d = DateTime.parse(timeStr);
      return d.year == dt.year && d.month == dt.month && d.day == dt.day;
    });

    // fallback if not found
    final int actualTodayIndex = todayIndex >= 0 ? todayIndex : 30;

    for (var i = 0; i < dailyTimes.length; i++) {
      final dailyPrecipitationValue = dailyPrecip[i].toDouble();

      // Collect past 30 days history
      if (i < actualTodayIndex && i >= actualTodayIndex - 30) {
        past30DaysPrecip.add(dailyPrecipitationValue);
        sum30 += dailyPrecipitationValue;
      }

      // Collect forecast (from tomorrow onwards)
      // If we want today + forecast, use >= actualTodayIndex
      // Design shows "Monday, Tuesday...", which usually starts from tomorrow or today.
      // Let's include from today to today + 6 days.
      if (i >= actualTodayIndex) {
        forecasts.add(
          DailyForecast(
            date: DateTime.parse(dailyTimes[i]),
            weatherCode: dailyCodes[i].toInt(),
            tempMax: dailyMax[i].toDouble(),
            tempMin: dailyMin[i].toDouble(),
            precipitationSum: dailyPrecipitationValue,
            windSpeed: dailyWindSpeed[i].toDouble(),
          ),
        );
      }
    }

    return WeatherContext(
      snapshot,
      sum24,
      dailyForecasts: forecasts,
      past30DaysPrecipitation: past30DaysPrecip,
      precipitationLast30Days: sum30,
    );
  }
}
