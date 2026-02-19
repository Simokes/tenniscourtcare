// lib/presentation/screens/weather_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/terrain.dart';
import '../providers/weather_providers.dart';
import '../widgets/weather_badge.dart';

class WeatherScreen extends ConsumerWidget {
  final String titre;
  final double latitude;
  final double longitude;
  final TerrainType terrainType;

  const WeatherScreen({
    super.key,
    required this.titre,
    required this.latitude,
    required this.longitude,
    required this.terrainType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(
      weatherForTerrainProvider((lat: latitude, lon: longitude, type: terrainType)),
    );

    return Scaffold(
      appBar: AppBar(title: Text(titre)),
      body: async.when(
        data: (w) {
          final s = w.context.snapshot;
          final sum24 = w.context.precipitationLast24h;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              WeatherBadge(frozen: w.frozen, unplayable: w.unplayable),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: DefaultTextStyle.merge(
                    style: Theme.of(context).textTheme.bodyLarge!,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Météo actuelle', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 12),
                        _Row('Température', '${s.temperature.toStringAsFixed(1)} °C'),
                        _Row('Humidité', '${s.humidity}%'),
                        _Row('Vent', '${s.windSpeed.toStringAsFixed(1)} km/h'),
                        _Row('Pluie (instantanée)', '${s.precipitation.toStringAsFixed(2)} mm'),
                        _Row('Pluie 24h', '${sum24.toStringAsFixed(2)} mm'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Erreur météo: $e')),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String k;
  final String v;
  const _Row(this.k, this.v);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(k), Text(v, style: const TextStyle(fontWeight: FontWeight.w600))],
      ),
    );
  }
}