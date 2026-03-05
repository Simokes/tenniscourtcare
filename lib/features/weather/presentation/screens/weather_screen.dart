import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tenniscourtcare/domain/entities/terrain.dart';
import 'package:tenniscourtcare/presentation/providers/weather_for_club_provider.dart';
import '../widgets/weather_widgets.dart';

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
    final Color backgroundColorLight = const Color(0xFFF5F7F8);
    final Color navy800 = const Color(0xFF001A3D);

    return Scaffold(
      backgroundColor: backgroundColorLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade100, height: 1.0),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: navy800),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          titre,
          style: TextStyle(
            color: navy800,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: navy800),
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
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "Configurez l'adresse du club",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16),
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
              style: TextStyle(color: Colors.red.shade400),
            ),
          ),
        ),
      ),
    );
  }
}
