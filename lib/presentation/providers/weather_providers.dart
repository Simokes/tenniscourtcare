// lib/presentation/providers/weather_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/terrain.dart';
import '../../domain/services/weather_rules.dart';
import '../../infrastructure/weather/weather_service.dart';

final weatherServiceProvider = Provider<WeatherService>((ref) {
  return MockWeatherService();
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
  final ctx = await svc.getWeatherForTerrain('local');

  final temp = ctx.temperature ?? 20.0;
  final precip = 0.0; // Stub
  final hum = (ctx.humidity ?? 50.0).toInt();

  final frozen = WeatherRules.isFrozen(temp);
  final unplayable = WeatherRules.isUnplayable(
    type: args.type,
    precipitationLast24hMm: precip,
    humidityPct: hum,
  );

  return WeatherComputed(context: ctx, frozen: frozen, unplayable: unplayable);
});