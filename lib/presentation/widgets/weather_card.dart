import 'package:flutter/material.dart';
import '../../domain/entities/weather_snapshot.dart';
import '../widgets/weather_badge.dart';

class WeatherCard extends StatelessWidget {
  final WeatherSnapshot? weather;
  final double? precip24h;
  final bool? frozen;
  final bool? unplayable;
  final VoidCallback onRefresh;

  const WeatherCard({
    super.key,
    required this.weather,
    required this.precip24h,
    required this.frozen,
    required this.unplayable,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (weather == null) {
      return InkWell(
        onTap: onRefresh,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_sync, color: colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                'Récupérer la météo actuelle',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Conditions météo',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              IconButton(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Actualiser',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          WeatherBadge(
            frozen: frozen ?? false,
            unplayable: unplayable ?? false,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _WeatherItem(
                icon: Icons.thermostat,
                value: '${weather!.temperature.toStringAsFixed(1)}°C',
                label: 'Temp.',
              ),
              _WeatherItem(
                icon: Icons.water_drop,
                value: '${weather!.humidity}%',
                label: 'Humidité',
              ),
              _WeatherItem(
                icon: Icons.air,
                value: '${weather!.windSpeed.toStringAsFixed(1)} km/h',
                label: 'Vent',
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _WeatherDetail(
                label: 'Pluie (instant)',
                value: '${weather!.precipitation.toStringAsFixed(2)} mm',
              ),
              if (precip24h != null)
                _WeatherDetail(
                  label: 'Pluie 24h',
                  value: '${precip24h!.toStringAsFixed(2)} mm',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeatherItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _WeatherItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _WeatherDetail extends StatelessWidget {
  final String label;
  final String value;

  const _WeatherDetail({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
