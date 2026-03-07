import 'package:flutter/material.dart';
import 'package:tenniscourtcare/core/theme/dashboard_theme_extension.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tenniscourtcare/domain/entities/terrain.dart';
import 'package:tenniscourtcare/features/weather/providers/weather_for_club_provider.dart';
import '../widgets/weather_widgets.dart';
import 'package:tenniscourtcare/core/theme/app_theme.dart';
import 'package:tenniscourtcare/core/theme/dashboard_theme_extension.dart';

class WeatherScreen extends ConsumerWidget {
  final String titre;
  final TerrainType terrainType;

  const WeatherScreen({
    super.key,
    required this.titre,
    required this.terrainType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(weatherForClubProvider(terrainType));

    // We get colors matching the design's tailwind config



    return Scaffold(

      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Theme.of(context).colorScheme.outlineVariant, height: 1.0),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryDark),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          titre,
          style: const TextStyle(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.primaryDark),
            onPressed: () {
              // Action pour rafraîchir ou paramètres
              ref.invalidate(weatherForClubProvider(terrainType));
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: weatherAsync.when(
        data: (data) {
          if (data == null) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "Configurez l'adresse du club",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16),
                ),
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Current Weather
                CurrentWeatherCard(
                  weather: data.context.snapshot,
                  precipitationLast24h: data.context.precipitationLast24h,
                  unplayable: data.unplayable,
                  frozen: data.frozen,
                  windyStrong: data.windyStrong,
                  conditionLabel: data.conditionLabel,
                  conditionIcon: data.conditionIcon,
                  conditionColor: data.conditionColor,
                ),

                // Rain History
                RainHistoryChart(
                  dailyPrecipitation: data.context.past30DaysPrecipitation,
                  totalPrecipitation: data.context.precipitationLast30Days,
                ),

                // 7-Day Forecast
                if (data.context.dailyForecasts.isNotEmpty)
                  ForecastSection(forecasts: data.context.dailyForecasts),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Impossible de charger la météo.\nVérifiez votre connexion ou les coordonnées du club.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).extension<DashboardColors>()!.dangerColor),
            ),
          ),
        ),
      ),
    );
  }
}
