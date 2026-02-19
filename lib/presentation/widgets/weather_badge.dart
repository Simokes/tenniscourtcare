// lib/presentation/widgets/weather_badge.dart
import 'package:flutter/material.dart';

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
      color = Colors.blue;
    } else if (unplayable) {
      text = 'Terrain impraticable';
      color = Colors.orange;
    } else {
      text = 'Terrain praticable';
      color = Colors.green;
    }

    return Chip(
      label: Text(
        text,
        style: const TextStyle(
          color: Colors.white, // ✔️ corrigé (pas de shade700)
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color,
      side: BorderSide(color: color),
    );
  }
}