// lib/presentation/providers/weather_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/terrain.dart';
import '../../domain/services/weather_rules.dart';
import '../../infrastructure/weather/weather_service.dart';

final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService();
});

class WeatherComputed {
  final WeatherContext context;
  final bool frozen;
  final bool unplayable;
  WeatherComputed({
    required this.context,
    required this.frozen,
    required this.unplayable,
  });
}

final weatherForTerrainProvider = FutureProvider.family<WeatherComputed, ({double lat, double lon, TerrainType type})>((ref, args) async {
  final svc = ref.read(weatherServiceProvider);
  final ctx = await svc.fetch(latitude: args.lat, longitude: args.lon);

  final frozen = WeatherRules.isFrozen(ctx.snapshot.temperature);
  final unplayable = WeatherRules.isUnplayable(
    type: args.type,
    precipitationLast24hMm: ctx.precipitationLast24h,
    humidityPct: ctx.snapshot.humidity,
  );

  return WeatherComputed(context: ctx, frozen: frozen, unplayable: unplayable);
});