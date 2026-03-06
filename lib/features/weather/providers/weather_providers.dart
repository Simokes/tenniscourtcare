// lib/presentation/providers/weather_providers.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/terrain.dart';
import '../../../domain/services/weather_rules.dart';
import '../infrastructure/weather_service.dart';

final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService();
});

class WeatherComputed {
  final WeatherContext context;
  final bool frozen;
  final bool unplayable;
  final bool windyStrong;
  final bool windyModerate;
  final String conditionLabel;
  final IconData conditionIcon;
  final Color conditionColor;

  WeatherComputed({
    required this.context,
    required this.frozen,
    required this.unplayable,
    required this.windyStrong,
    required this.windyModerate,
    required this.conditionLabel,
    required this.conditionIcon,
    required this.conditionColor,
  });
}

final weatherForTerrainProvider =
    FutureProvider.family<
      WeatherComputed,
      ({double lat, double lon, TerrainType type})
    >((ref, args) async {
      final svc = ref.read(weatherServiceProvider);
      final ctx = await svc.fetch(latitude: args.lat, longitude: args.lon);

      final frozen = WeatherRules.isFrozen(ctx.snapshot.temperature);
      final unplayable = WeatherRules.isUnplayable(
        type: args.type,
        precipitationLast24hMm: ctx.precipitationLast24h,
        humidityPct: ctx.snapshot.humidity,
      );

      final windyStrong = WeatherRules.isWindyStrong(ctx.snapshot.windSpeed);
      final windyModerate = WeatherRules.isWindyModerate(
        ctx.snapshot.windSpeed,
      );

      final label = WeatherRules.conditionLabel(
        frozen: frozen,
        unplayable: unplayable,
        windyStrong: windyStrong,
        windyModerate: windyModerate,
        precipitation: ctx.snapshot.precipitation,
      );

      final icon = WeatherRules.conditionIcon(
        frozen: frozen,
        unplayable: unplayable,
        windyStrong: windyStrong,
        windyModerate: windyModerate,
        precipitation: ctx.snapshot.precipitation,
      );

      final color = WeatherRules.conditionColor(
        frozen: frozen,
        unplayable: unplayable,
        windyStrong: windyStrong,
        windyModerate: windyModerate,
      );

      return WeatherComputed(
        context: ctx,
        frozen: frozen,
        unplayable: unplayable,
        windyStrong: windyStrong,
        windyModerate: windyModerate,
        conditionLabel: label,
        conditionIcon: icon,
        conditionColor: color,
      );
    });
