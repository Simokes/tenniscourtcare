import 'package:flutter/material.dart';
import 'package:tenniscourtcare/core/theme/app_theme.dart';
import 'package:tenniscourtcare/core/theme/dashboard_theme_extension.dart';
import 'package:intl/intl.dart';
import 'package:tenniscourtcare/domain/entities/daily_forecast.dart';
import 'package:tenniscourtcare/domain/entities/weather_snapshot.dart';
import 'package:tenniscourtcare/domain/services/weather_rules.dart';

// Source unique pour les icônes météo — évite la duplication entre widgets
IconData _weatherIcon(int code) {
  if (code == 0) return Icons.wb_sunny;
  if (code < 3) return Icons.wb_cloudy;
  if (code < 50) return Icons.foggy;
  if (code < 70) return Icons.water_drop;
  if (code < 80) return Icons.ac_unit;
  return Icons.thunderstorm;
}

// Source unique pour les labels météo
String _weatherConditionLabel(int code) {
  if (code == 0) return 'Ciel dégagé';
  if (code < 3) return 'Partiellement nuageux';
  if (code < 50) return 'Brouillard';
  if (code < 70) return 'Pluie';
  if (code < 80) return 'Neige';
  return 'Orage';
}

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
    final hasBadConditions = frozen || unplayable || windyStrong;
    final borderColor = hasBadConditions
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
          // Header gradient dynamique — pas de dépendance réseau, pas de ville hardcodée
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryDark,
                    conditionColor.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        _weatherIcon(weather.weatherCode),
                        color: Colors.yellow.shade300,
                        size: 36,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${weather.temperature.round()}°C',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _weatherConditionLabel(weather.weatherCode),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
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
                    Text(
                      'Conditions Actuelles',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
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
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: conditionColor,
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
              Text(
                'HISTORIQUE DES PLUIES (30 JOURS)',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'Total: ${totalPrecipitation.round()}mm',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
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
                final int dataIndex = dailyPrecipitation.length - 30 + index;
                final double precip =
                    dataIndex >= 0 && dataIndex < dailyPrecipitation.length
                        ? dailyPrecipitation[dataIndex]
                        : 0.0;

                double pct = precip / effectiveMax;
                final bool isSignificant = precip > 0.5;

                final Color barColor = isSignificant
                    ? AppColors.primary
                    : AppColors.infoBg;

                if (!isSignificant && pct < 0.1) {
                  pct = 0.1;
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
          Text(
            'Prévisions sur 7 jours',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
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
      dayLabel = "Aujourd'hui";
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
      labelColor = Theme.of(context).extension<DashboardColors>()?.dangerColor ?? AppColors.danger;
    } else if (forecastLabel.startsWith('Prudence') ||
        forecastLabel.startsWith('Conditions dégradées')) {
      labelColor = Theme.of(context).extension<DashboardColors>()?.warningColor ?? AppColors.warning;
    } else {
      labelColor = Theme.of(context).extension<DashboardColors>()?.successColor ?? AppColors.success;
    }

    final Color iconColor;
    final Color iconBgColor;

    if (forecast.weatherCode == 0 || forecast.weatherCode == 1) {
      iconColor = AppColors.warning;
      iconBgColor = AppColors.warningBg;
    } else if (forecast.weatherCode < 50) {
      iconColor = AppColors.info;
      iconBgColor = AppColors.infoBg;
    } else {
      iconColor = Theme.of(context).colorScheme.onSurfaceVariant;
      iconBgColor = Theme.of(context).colorScheme.surfaceContainerHighest;
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
                    child: Icon(_weatherIcon(forecast.weatherCode), color: iconColor),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dayLabel,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '↑${forecast.tempMax.round()}° ↓${forecast.tempMin.round()}°',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                        const Icon(Icons.water_drop, size: 14, color: AppColors.info),
                        const SizedBox(width: 4),
                        Text(
                          '${forecast.precipitationSum.toStringAsFixed(1)} mm',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  if (forecast.windSpeed >= 25) ...[
                    if (forecast.precipitationSum > 0) const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.air,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${forecast.windSpeed.round()} km/h',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
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
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              unit,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}