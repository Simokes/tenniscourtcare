import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:tenniscourtcare/domain/entities/terrain.dart';
import 'package:tenniscourtcare/presentation/providers/dashboard_providers.dart';
import 'package:tenniscourtcare/presentation/providers/terrain_provider.dart';
import 'package:tenniscourtcare/presentation/providers/global_stock_alert_provider.dart';
import '../../../../core/theme/dashboard_theme_extension.dart';
import '../widgets/home_stats_cards.dart';
import '../widgets/dashboard_terrain_item.dart';
import '../../../../presentation/widgets/dashboard/upcoming_events_list.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  /// Ouvre l'écran météo en utilisant la coordonnée "club" (globale).
  void _openWeatherForFirstTerrainWithCoords(BuildContext context, WidgetRef ref) {
    final terrains = ref.read(terrainsProvider).maybeWhen(
      data: (list) => list,
      orElse: () => const <Terrain>[],
    );

    if (terrains.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun terrain disponible pour la météo')),
      );
      return;
    }

    final Terrain picked = terrains.first;

    // Use GoRouter
    context.push('/weather/${picked.type.name}');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayCountAsync = ref.watch(todayMaintenanceCountProvider);
    final stockAlertCountAsync = ref.watch(globalStockAlertCountProvider);
    final terrainsAsync = ref.watch(terrainsProvider);

    final now = DateTime.now();
    final dateFormat = DateFormat('EEEE d MMMM', 'fr_FR');

    // Theme Colors
    final dashboardColors = Theme.of(context).extension<DashboardColors>()!;

    return Scaffold(
      // backgroundColor: handled by Theme
      body: CustomScrollView(
        slivers: [
          // 1. Premium Sliver App Bar
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            // Ajout de l'icône de notification (cloche) avec badge
            leading: IconButton(
              icon: Consumer(
                builder: (context, ref, child) {
                  final alertCount = ref.watch(globalStockAlertCountProvider).valueOrNull ?? 0;
                  return Badge(
                    isLabelVisible: alertCount > 0,
                    label: Text('$alertCount'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                    child: const Icon(Icons.notifications, color: Colors.white),
                  );
                },
              ),
              onPressed: () {
                 context.push('/stock');
              },
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Text(
                'Court Care',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: const Offset(0, 1),
                      blurRadius: 3.0,
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.tertiary,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative patterns
                    Positioned(
                      right: -50,
                      top: -50,
                      child: Icon(
                        Icons.sports_tennis,
                        size: 200,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    Positioned(
                      left: 24,
                      top: 60, // Safe area roughly
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bonjour, Agent',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            dateFormat.format(now).capitalize(),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () {
                  context.push('/settings');
                },
              ),
            ],
          ),

          // 2. Key Stats Grid
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                HomeStatCard(
                  title: 'Maintenances\nAujourd\'hui',
                  valueAsync: todayCountAsync,
                  icon: Icons.assignment_turned_in,
                  color: dashboardColors.maintenanceColor,
                  onTap: () {
                     context.push('/maintenance');
                  },
                ),
                HomeStatCard(
                  title: 'Alertes\nStock',
                  valueAsync: stockAlertCountAsync,
                  icon: Icons.inventory_2,
                  color: dashboardColors.stockColor,
                  isAlert: true,
                  onTap: () {
                    context.push('/stock');
                  },
                ),
                HomeActionCard(
                  title: 'Météo\nClub',
                  icon: Icons.wb_sunny,
                  color: dashboardColors.weatherColor,
                  onTap: () => _openWeatherForFirstTerrainWithCoords(context, ref),
                ),
                HomeActionCard(
                  title: 'Stats\nGlobales',
                  icon: Icons.bar_chart,
                  color: dashboardColors.statsColor,
                  onTap: () {
                    context.push('/stats');
                  },
                ),
              ],
            ),
          ),

          // New Section: Upcoming Events
          const SliverToBoxAdapter(
            child: UpcomingEventsList(),
          ),

          // 3. Section Title: Terrains
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mes Terrains',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton(
                    onPressed: () {
                       context.push('/add-terrain');
                    },
                    child: const Text('Ajouter'),
                  ),
                ],
              ),
            ),
          ),

          // 4. Terrain List (Simplified for Dashboard)
          terrainsAsync.when(
            data: (terrains) {
              if (terrains.isEmpty) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        'Aucun terrain configuré.',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final terrain = terrains[index];
                    return DashboardTerrainItem(terrain: terrain);
                  },
                  childCount: terrains.length,
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, s) => SliverToBoxAdapter(
              child: Center(child: Text('Erreur: $e')),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/maintenance');
        },
        icon: const Icon(Icons.add),
        label: const Text('Intervention'),
      ),
    );
  }
}

extension StringExtension on String {
    String capitalize() {
      return '${this[0].toUpperCase()}${substring(1)}';
    }
}
