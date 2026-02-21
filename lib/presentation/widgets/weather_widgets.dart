import 'package:flutter/material.dart';
import '../../domain/entities/daily_forecast.dart';
import '../../domain/entities/weather_snapshot.dart';
import '../widgets/weather_badge.dart';

class CurrentWeatherCard extends StatelessWidget {
  final WeatherSnapshot weather;
  final double precipitationLast24h;

  const CurrentWeatherCard({
    super.key,
    required this.weather,
    required this.precipitationLast24h,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Maintenant',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${weather.temperature.toStringAsFixed(1)}°',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const WeatherBadge(
                    frozen: false, // Calculated in parent logic usually
                    unplayable: false,
                  ),
                ],
              ),
              Icon(
                _getWeatherIcon(weather.weatherCode),
                size: 64,
                color: Colors.orange.shade400,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _WeatherDetailItem(
                icon: Icons.water_drop,
                label: 'Humidité',
                value: '${weather.humidity}%',
              ),
              _WeatherDetailItem(
                icon: Icons.air,
                label: 'Vent',
                value: '${weather.windSpeed.toStringAsFixed(1)} km/h',
              ),
              _WeatherDetailItem(
                icon: Icons.grain,
                label: 'Pluie (24h)',
                value: '${precipitationLast24h.toStringAsFixed(1)} mm',
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getWeatherIcon(int code) {
    // Basic mapping, can be improved
    if (code == 0) return Icons.wb_sunny;
    if (code < 3) return Icons.wb_cloudy;
    if (code < 50) return Icons.foggy;
    if (code < 70) return Icons.grain; // Rain
    if (code < 80) return Icons.ac_unit; // Snow
    return Icons.thunderstorm;
  }
}

class ForecastList extends StatelessWidget {
  final List<DailyForecast> forecasts;

  const ForecastList({super.key, required this.forecasts});

  @override
  Widget build(BuildContext context) {
    if (forecasts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Prévisions 3 jours',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        SizedBox(
          height: 160,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: forecasts.take(3).length, // Limit to 3
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final forecast = forecasts[index];
              return _ForecastCard(forecast: forecast);
            },
          ),
        ),
      ],
    );
  }
}

class _ForecastCard extends StatelessWidget {
  final DailyForecast forecast;

  const _ForecastCard({required this.forecast});

  @override
  Widget build(BuildContext context) {
    // Determine day name
    final now = DateTime.now();
    final date = forecast.date;
    String dayLabel;

    if (date.day == now.day) {
      dayLabel = 'Aujourd\'hui';
    } else if (date.day == now.add(const Duration(days: 1)).day) {
      dayLabel = 'Demain';
    } else {
      // Just generic day/month
      dayLabel = '${date.day}/${date.month}';
    }

    return Container(
      width: 110,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            dayLabel,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Icon(
            _getWeatherIcon(forecast.weatherCode),
            size: 32,
            color: Colors.blue.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            '${forecast.tempMax.round()}°',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(
            '${forecast.tempMin.round()}°',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 13,
            ),
          ),
          if (forecast.precipitationSum > 0.5) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.water_drop, size: 10, color: Colors.blue.shade300),
                Text(
                  '${forecast.precipitationSum.round()}mm',
                  style: TextStyle(fontSize: 10, color: Colors.blue.shade300),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  IconData _getWeatherIcon(int code) {
    if (code == 0) return Icons.wb_sunny;
    if (code < 3) return Icons.wb_cloudy;
    if (code < 50) return Icons.foggy;
    if (code < 70) return Icons.grain;
    if (code < 80) return Icons.ac_unit;
    return Icons.thunderstorm;
  }
}

class _WeatherDetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _WeatherDetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.grey.shade600, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
        ),
      ],
    );
  }
}
