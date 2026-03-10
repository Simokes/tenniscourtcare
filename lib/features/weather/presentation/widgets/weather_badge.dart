// lib/presentation/widgets/weather_badge.dart
import 'package:flutter/material.dart';
import 'package:tenniscourtcare/core/theme/app_theme.dart';
import 'package:tenniscourtcare/core/theme/dashboard_theme_extension.dart';

class WeatherBadge extends StatelessWidget {
  final bool frozen;
  final bool unplayable;

  const WeatherBadge({
    super.key,
    required this.frozen,
    required this.unplayable,
  });

  @override
  Widget build(BuildContext context) {
    late final String text;
    late final Color color;

    if (frozen) {
      text = 'Terrain gelé';
      color = Theme.of(context).extension<DashboardColors>()?.maintenanceColor ?? AppColors.info;
    } else if (unplayable) {
      text = 'Terrain impraticable';
      color = Theme.of(context).extension<DashboardColors>()?.warningColor ?? AppColors.warning;
    } else {
      text = 'Terrain praticable';
      color = Theme.of(context).extension<DashboardColors>()?.successColor ?? AppColors.success;
    }

    return Chip(
      label: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color,
      side: BorderSide(color: color),
    );
  }
}
