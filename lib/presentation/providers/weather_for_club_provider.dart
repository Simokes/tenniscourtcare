import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/terrain.dart';
import '../../domain/services/weather_rules.dart';
import '../../infrastructure/weather/weather_service.dart';
import 'app_settings_provider.dart';
import 'weather_providers.dart' show weatherServiceProvider;

class WeatherComputed {
  final WeatherContext context;
  final bool frozen;
  final bool unplayable;
  final String? reason;
  WeatherComputed({required this.context, required this.frozen, required this.unplayable, this.reason});
}

/// Météo pour le club (coordonnée globale), en fonction d’un type de terrain
final weatherForClubProvider =
FutureProvider.family<WeatherComputed, TerrainType>((ref, type) async {
  final settingsAsync = ref.watch(appSettingsProvider);
  final loc = settingsAsync.value?.location;
  if (loc == null) {
    throw Exception('Aucune coordonnée du club définie');
  }

  final svc = ref.read(weatherServiceProvider);
  final ctx = await svc.getWeatherForTerrain('club');

  final temp = ctx.temperature ?? 20.0;
  final precip = 0.0; // Stub
  final hum = (ctx.humidity ?? 50.0).toInt();

  final frozen = WeatherRules.isFrozen(temp);
  final unplayable = WeatherRules.isUnplayable(
    type: type,
    precipitationLast24hMm: precip,
    humidityPct: hum,
  );

  return WeatherComputed(context: ctx, frozen: frozen, unplayable: unplayable);
});