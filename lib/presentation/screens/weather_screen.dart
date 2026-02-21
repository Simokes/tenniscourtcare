import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/terrain.dart';
import '../providers/weather_for_club_provider.dart';
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

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 250,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                titre,
                style: const TextStyle(
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://images.unsplash.com/photo-1595435934249-5df7ed86e1c0?q=80&w=2942&auto=format&fit=crop',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.6),
                          Colors.transparent,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: () => ref.refresh(weatherForClubProvider(terrainType)),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: weatherAsync.when(
                data: (data) {
                  return Column(
                    children: [
                      // Current Weather
                      CurrentWeatherCard(
                        weather: data.context.snapshot,
                        precipitationLast24h: data.context.precipitationLast24h,
                      ),

                      const SizedBox(height: 24),

                      // 3-Day Forecast
                      if (data.context.dailyForecasts.isNotEmpty)
                        ForecastList(forecasts: data.context.dailyForecasts),

                      const SizedBox(height: 40),

                      // Detailed Advice Card
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: data.unplayable ? Colors.red.shade200 : Colors.green.shade200,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              data.unplayable ? Icons.cancel : Icons.check_circle,
                              color: data.unplayable ? Colors.red : Colors.green,
                              size: 32,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data.unplayable ? 'Terrain Impraticable' : 'Terrain Jouable',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: data.unplayable ? Colors.red.shade900 : Colors.green.shade900,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    data.reason ?? 'Conditions optimales pour le jeu.',
                                    style: TextStyle(
                                      color: Colors.grey.shade800,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  );
                },
                loading: () => const SizedBox(
                  height: 300,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, s) => SizedBox(
                  height: 300,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Impossible de charger la météo.\nVérifiez votre connexion ou les coordonnées du club.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red.shade300),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
