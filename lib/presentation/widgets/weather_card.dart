// filepath: lib/presentation/widgets/weather_card.dart

import 'package:flutter/material.dart';
import '../../infrastructure/weather/weather_service.dart';

/// Widget to display weather information for a terrain
class WeatherCard extends StatelessWidget {
  final WeatherContext weatherContext;
  final VoidCallback? onRefresh;

  const WeatherCard({
    Key? key,
    required this.weatherContext,
    this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Weather',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (onRefresh != null)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: onRefresh,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              weatherContext.weatherCondition ?? 'Unknown',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (weatherContext.temperature != null)
              Text(
                'Temperature: ${weatherContext.temperature}°C',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            if (weatherContext.humidity != null)
              Text(
                'Humidity: ${weatherContext.humidity}%',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            if (weatherContext.windSpeed != null)
              Text(
                'Wind: ${weatherContext.windSpeed} km/h',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
          ],
        ),
      ),
    );
  }
}
