import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/terrain.dart';
import '../../domain/services/weather_rules.dart';
import '../../infrastructure/weather/weather_service.dart';
import 'app_settings_provider.dart';

// Tu dois déjà avoir ce provider quelque part :
final weatherServiceProvider = Provider<WeatherService>((ref) => WeatherService());

class WeatherComputed {
  final WeatherContext context;
  final bool frozen;
  final bool unplayable;
  WeatherComputed({required this.context, required this.frozen, required this.unplayable});
}

/// Météo pour le club (coordonnée globale), en fonction d’un type de terrain
final weatherForClubProvider =
FutureProvider.family<WeatherComputed, TerrainType>((ref, type) async {
  final locAsync = ref.watch(appSettingsProvider);
  final loc = locAsync.value;
  if (loc == null) {
    throw Exception('Aucune coordonnée du club définie');
  }

  final svc = ref.read(weatherServiceProvider);
  final ctx = await svc.fetch(latitude: loc.latitude, longitude: loc.longitude);

  final frozen = WeatherRules.isFrozen(ctx.snapshot.temperature);
  final unplayable = WeatherRules.isUnplayable(
    type: type,
    precipitationLast24hMm: ctx.precipitationLast24h,
    humidityPct: ctx.snapshot.humidity,
  );

  return WeatherComputed(context: ctx, frozen: frozen, unplayable: unplayable);
});