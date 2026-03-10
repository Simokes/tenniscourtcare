import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tenniscourtcare/core/theme/app_theme.dart';
import 'package:tenniscourtcare/core/theme/dashboard_theme_extension.dart';
import 'package:tenniscourtcare/domain/entities/terrain.dart';
import 'package:tenniscourtcare/features/weather/providers/weather_for_club_provider.dart';
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
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Theme.of(context).colorScheme.outlineVariant,
            height: 1.0,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          titre,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.onSurface),
            tooltip: 'Actualiser',
            onPressed: () => ref.invalidate(weatherForClubProvider(terrainType)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: weatherAsync.when(
        data: (data) {
          if (data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Configurez l'adresse du club",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 40),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
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
                    RainHistoryChart(
                      dailyPrecipitation: data.context.past30DaysPrecipitation,
                      totalPrecipitation: data.context.precipitationLast30Days,
                    ),
                    if (data.context.dailyForecasts.isNotEmpty)
                      ForecastSection(forecasts: data.context.dailyForecasts),
                  ]),
                ),
              ),
            ],
          );
        },
        loading: () => const _WeatherScreenSkeleton(),
        error: (e, s) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_off,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'Impossible de charger la météo.\nVérifiez votre connexion ou les coordonnées du club.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).extension<DashboardColors>()?.dangerColor ?? AppColors.danger,
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () => ref.invalidate(weatherForClubProvider(terrainType)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WeatherScreenSkeleton extends StatelessWidget {
  const _WeatherScreenSkeleton();

  @override
  Widget build(BuildContext context) {
    final skeletonColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            height: 280,
            decoration: BoxDecoration(
              color: skeletonColor,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: skeletonColor,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(
            3,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: skeletonColor,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}