import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:tenniscourtcare/domain/entities/terrain.dart';
import 'package:tenniscourtcare/presentation/providers/terrain_provider.dart';
import 'package:tenniscourtcare/presentation/providers/weather_for_club_provider.dart';

class WeatherCard extends ConsumerWidget {
  const WeatherCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final terrainsAsync = ref.watch(terrainsProvider);
    final terrains = terrainsAsync.valueOrNull ?? const <Terrain>[];
    final TerrainType? terrainType = terrains.isNotEmpty ? terrains.first.type : null;

    if (terrainType == null) {
      return _buildFallbackCard(context, ref);
    }

    final weatherAsync = ref.watch(weatherForClubProvider(terrainType));

    return weatherAsync.when(
      data: (weatherData) {
        if (weatherData == null) {
          return _buildCard(
            context: context,
            ref: ref,
            terrains: terrains,
            temp: '--°C',
            rain: '-- mm',
            wind: '-- km/h',
            conditionsTitle: "Configurez l'adresse du club",
            icon: Icons.location_off,
          );
        }

        final weather = weatherData.context.snapshot;
        final precipitationLast24h = weatherData.context.precipitationLast24h;
        final unplayable = weatherData.unplayable;

        final String conditionsTitle = unplayable ? 'À éviter' : 'Conditions optimales';
        final IconData weatherIcon = _getWeatherIcon(weather.weatherCode);

        return _buildCard(
          context: context,
          ref: ref,
          terrains: terrains,
          temp: '${weather.temperature.round()}°C',
          rain: '${precipitationLast24h.round()} mm',
          wind: '${weather.windSpeed.round()} km/h',
          conditionsTitle: conditionsTitle,
          icon: weatherIcon,
        );
      },
      loading: () => _buildCard(
        context: context,
        ref: ref,
        terrains: terrains,
        temp: '--°C',
        rain: '-- mm',
        wind: '-- km/h',
        conditionsTitle: 'Chargement...',
        icon: Icons.hourglass_empty,
      ),
      error: (_, _) => _buildCard(
        context: context,
        ref: ref,
        terrains: terrains,
        temp: '--°C',
        rain: '-- mm',
        wind: '-- km/h',
        conditionsTitle: 'Météo indisponible',
        icon: Icons.error_outline,
      ),
    );
  }

  Widget _buildFallbackCard(BuildContext context, WidgetRef ref) {
    return _buildCard(
      context: context,
      ref: ref,
      terrains: [],
      temp: '--°C',
      rain: '-- mm',
      wind: '-- km/h',
      conditionsTitle: 'Aucun terrain',
      icon: Icons.wb_sunny,
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required WidgetRef ref,
    required List<Terrain> terrains,
    required String temp,
    required String rain,
    required String wind,
    required String conditionsTitle,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: () {
        if (terrains.isNotEmpty) {
          final Terrain picked = terrains.first;
          context.push('/weather/${picked.type.name}');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucun terrain disponible pour la météo'),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF003580), // Primary
              Color(0xFF0EA5E9), // Secondary
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
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
                      'MÉTÉO EN DIRECT',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withValues(alpha: 0.8),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      conditionsTitle,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Icon(icon, color: Colors.amber, size: 48),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildWeatherDetail(temp, 'Température'),
                _buildWeatherDetail(rain, 'Pluie'),
                _buildWeatherDetail(wind, 'Vent'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetail(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
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
