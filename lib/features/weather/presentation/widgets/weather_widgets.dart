import 'package:flutter/material.dart';
import 'package:tenniscourtcare/core/theme/app_theme.dart';
import 'package:tenniscourtcare/core/theme/dashboard_theme_extension.dart';
import 'package:intl/intl.dart';
import 'package:tenniscourtcare/domain/entities/daily_forecast.dart';
import 'package:tenniscourtcare/domain/entities/weather_snapshot.dart';
import 'package:tenniscourtcare/domain/services/weather_rules.dart';

class CurrentWeatherCard extends StatelessWidget {
  final WeatherSnapshot weather;
  final double precipitationLast24h;
  final bool unplayable;
  final bool frozen;
  final bool windyStrong;
  final String conditionLabel;
  final IconData conditionIcon;
  final Color conditionColor;

  const CurrentWeatherCard({
    super.key,
    required this.weather,
    required this.precipitationLast24h,
    required this.unplayable,
    required this.frozen,
    required this.windyStrong,
    required this.conditionLabel,
    required this.conditionIcon,
    required this.conditionColor,
  });

  @override
  Widget build(BuildContext context) {
    final String conditionStr = _getWeatherConditionString(weather.weatherCode);

    // Colored border if bad conditions
    final bool hasBadConditions = frozen || unplayable || windyStrong;
    final Color borderColor = hasBadConditions
        ? conditionColor
        : Theme.of(context).colorScheme.outlineVariant;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: hasBadConditions ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Image Section
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                SizedBox(
                  height: 190,
                  width: double.infinity,
                  child: Image.network(
                    'https://images.unsplash.com/photo-1595435934249-5df7ed86e1c0?q=80&w=2942&auto=format&fit=crop',
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryDark.withValues(alpha: 0.8),
                          Colors.transparent,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            _getWeatherIcon(weather.weatherCode),
                            color: Colors.yellow.shade400,
                            size: 36,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${weather.temperature.round()}°C',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$conditionStr • Los Angeles, CA',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Details Section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Conditions Actuelles',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: conditionColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(conditionIcon, color: conditionColor, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            conditionLabel.toUpperCase(),
                            style: TextStyle(
                              color: conditionColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _WeatherDetailItem(
                        icon: Icons.air,
                        label: 'VENT',
                        value: weather.windSpeed.round().toString(),
                        unit: 'km/h',
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    Expanded(
                      child: _WeatherDetailItem(
                        icon: Icons.water_drop_outlined,
                        label: 'HUM',
                        value: weather.humidity.toString(),
                        unit: '%',
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    Expanded(
                      child: _WeatherDetailItem(
                        icon: Icons.grain,
                        label: 'PLUIE',
                        value: precipitationLast24h.round().toString(),
                        unit: 'mm',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getWeatherConditionString(int code) {
    if (code == 0) return 'Ciel dégagé';
    if (code < 3) return 'Partiellement nuageux';
    if (code < 50) return 'Brouillard';
    if (code < 70) return 'Pluie';
    if (code < 80) return 'Neige';
    return 'Orage';
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

class RainHistoryChart extends StatelessWidget {
  final List<double> dailyPrecipitation;
  final double totalPrecipitation;

  const RainHistoryChart({
    super.key,
    required this.dailyPrecipitation,
    required this.totalPrecipitation,
  });

  @override
  Widget build(BuildContext context) {
    // Generate bars to match the design. If we have actual data, map it to bar heights.
    // The max height of the container is 96 (h-24 in tailwind).
    // Let's find the max precipitation to scale the bars.
    final double maxPrecip = dailyPrecipitation.isEmpty
        ? 1.0
        : dailyPrecipitation.reduce((a, b) => a > b ? a : b);
    final double effectiveMax = maxPrecip > 0 ? maxPrecip : 1.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'HISTORIQUE DES PLUIES (30 JOURS)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'Total: ${totalPrecipitation.round()}mm',
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 96,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(30, (index) {
                // If we don't have exactly 30 days of data, pad with 0s.
                // Assuming dailyPrecipitation is ordered chronologically (oldest to newest).
                final int dataIndex = dailyPrecipitation.length - 30 + index;
                final double precip =
                    dataIndex >= 0 && dataIndex < dailyPrecipitation.length
                    ? dailyPrecipitation[dataIndex]
                    : 0.0;

                // For a purely visual match to the mockup when data might be zero right now,
                // we can just draw what the API gives us. But let's actually map it properly.
                // Minimum bar height is 10% for tiny amounts, else scale it.
                // If it's exactly 0, give it a tiny height and lighter color.

                double pct = precip / effectiveMax;
                final bool isSignificant = precip > 0.5;

                // The design uses blue-500 for significant, slate-200 for none/low.
                final Color barColor = isSignificant
                    ? const Color(
                        0xFF00419A,
                      ) // navy-500 equivalent in the design
                    : Colors.blue.shade100.withValues(alpha: 0.5);

                if (!isSignificant && pct < 0.1) {
                  pct = 0.1; // tiny bump for visual
                }

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.0),
                    child: FractionallySizedBox(
                      heightFactor: pct,
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class ForecastSection extends StatelessWidget {
  final List<DailyForecast> forecasts;

  const ForecastSection({super.key, required this.forecasts});

  @override
  Widget build(BuildContext context) {
    if (forecasts.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text(
            'Prévisions sur 7 jours',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 12),
          ...forecasts.map((forecast) => _ForecastListItem(forecast: forecast)),
        ],
      ),
    );
  }
}

class _ForecastListItem extends StatelessWidget {
  final DailyForecast forecast;

  const _ForecastListItem({required this.forecast});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final date = forecast.date;

    String dayLabel = DateFormat('E d MMM', 'fr').format(date);
    dayLabel = dayLabel[0].toUpperCase() + dayLabel.substring(1);

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      dayLabel = 'Aujourd\'hui';
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day + 1) {
      dayLabel = 'Demain';
    }

    final forecastLabel = WeatherRules.forecastLabel(
      precipitationSum: forecast.precipitationSum,
      tempMax: forecast.tempMax,
      windSpeed: forecast.windSpeed,
    );

    Color labelColor;
    if (forecastLabel.startsWith('Éviter')) {
      labelColor = Theme.of(context).extension<DashboardColors>()!.dangerColor;
    } else if (forecastLabel.startsWith('Prudence') ||
        forecastLabel.startsWith('Conditions dégradées')) {
      labelColor = Theme.of(context).extension<DashboardColors>()!.warningColor;
    } else {
      labelColor = Theme.of(context).extension<DashboardColors>()!.successColor;
    }

    // Icon and background color based on weather
    final IconData weatherIcon = _getWeatherIcon(forecast.weatherCode);
    Color iconColor;
    Color iconBgColor;

    if (forecast.weatherCode == 0 || forecast.weatherCode == 1) {
      iconColor = Colors.orange.shade500;
      iconBgColor = Colors.orange.shade50;
    } else if (forecast.weatherCode < 50) {
      iconColor = Colors.blue.shade500;
      iconBgColor = Colors.blue.shade50;
    } else {
      iconColor = Theme.of(context).colorScheme.onSurfaceVariant;
      iconBgColor = Colors.grey.shade100;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(weatherIcon, color: iconColor),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dayLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '↑${forecast.tempMax.round()}° ↓${forecast.tempMin.round()}°',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (forecast.precipitationSum > 0)
                    Row(
                      children: [
                        const Text('💧 '),
                        Text(
                          '${forecast.precipitationSum.toStringAsFixed(1)} mm',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  if (forecast.windSpeed >= 25) ...[
                    if (forecast.precipitationSum > 0)
                      const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text('💨 '),
                        Text(
                          '${forecast.windSpeed.round()} km/h',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            forecastLabel,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getWeatherIcon(int code) {
    if (code == 0) return Icons.wb_sunny;
    if (code < 3) return Icons.cloud;
    if (code < 50) return Icons.cloud;
    if (code < 70) return Icons.water_drop;
    if (code < 80) return Icons.ac_unit;
    return Icons.thunderstorm;
  }
}

class _WeatherDetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;

  const _WeatherDetailItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              unit,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }
}
