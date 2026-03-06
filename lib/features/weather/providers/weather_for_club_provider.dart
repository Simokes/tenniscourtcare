import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/terrain.dart';
import '../../../domain/services/weather_rules.dart';
import '../infrastructure/weather_service.dart';
import '../../settings/providers/app_settings_provider.dart';
import './weather_providers.dart' show weatherServiceProvider;
import '../../admin/providers/club_info_provider.dart';

import 'package:flutter/material.dart';

class WeatherComputed {
  final WeatherContext context;
  final bool frozen;
  final bool unplayable;
  final String? reason;
  final bool windyStrong;
  final bool windyModerate;
  final String conditionLabel;
  final IconData conditionIcon;
  final Color conditionColor;

  WeatherComputed({
    required this.context,
    required this.frozen,
    required this.unplayable,
    this.reason,
    required this.windyStrong,
    required this.windyModerate,
    required this.conditionLabel,
    required this.conditionIcon,
    required this.conditionColor,
  });
}

/// Météo pour le club (coordonnée globale), en fonction d’un type de terrain
final weatherForClubProvider =
    FutureProvider.family<WeatherComputed?, TerrainType>((ref, type) async {
      final clubLoc = ref.watch(clubLocationFromInfoProvider);
      final settingsLoc = ref.watch(appSettingsProvider).valueOrNull?.location;
      final loc = clubLoc ?? settingsLoc;

      if (loc == null) {
        return null;
      }

      final svc = ref.read(weatherServiceProvider);
      final ctx = await svc.fetch(
        latitude: loc.latitude,
        longitude: loc.longitude,
      );

      final frozen = WeatherRules.isFrozen(ctx.snapshot.temperature);
      final unplayable = WeatherRules.isUnplayable(
        type: type,
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
