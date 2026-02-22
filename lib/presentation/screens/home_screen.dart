import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/terrain.dart';
import '../providers/dashboard_providers.dart';
import '../providers/terrain_provider.dart';
import 'maintenance_screen.dart';
import 'stats_screen.dart';
import 'weather_screen.dart';
import 'settings_screen.dart';
import 'stock_screen.dart';
import 'terrain_maintenance_history_screen.dart';
import 'add_terrain_screen.dart';

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

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WeatherScreen(
          titre: 'Météo du club',
          terrainType: picked.type,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayCountAsync = ref.watch(todayMaintenanceCountProvider);
    final lowStockAsync = ref.watch(lowStockCountProvider);
    final terrainsAsync = ref.watch(terrainsProvider); // Use the main one which is cached properly

    final now = DateTime.now();
    final dateFormat = DateFormat('EEEE d MMMM', 'fr_FR');

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: CustomScrollView(
        slivers: [
          // 1. Premium Sliver App Bar
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
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
                _StatCard(
                  title: 'Maintenances\nAujourd\'hui',
                  valueAsync: todayCountAsync,
                  icon: Icons.assignment_turned_in,
                  color: Colors.blue.shade700,
                  onTap: () {
                     // Navigate to maintenance list?
                     Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MaintenanceScreen()),
                    );
                  },
                ),
                _StatCard(
                  title: 'Alertes\nStock',
                  valueAsync: lowStockAsync,
                  icon: Icons.inventory_2,
                  color: Colors.orange.shade800,
                  isAlert: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StockScreen()),
                    );
                  },
                ),
                _ActionCard(
                  title: 'Météo\nClub',
                  icon: Icons.wb_sunny,
                  color: Colors.teal.shade600,
                  onTap: () => _openWeatherForFirstTerrainWithCoords(context, ref),
                ),
                _ActionCard(
                  title: 'Stats\nGlobales',
                  icon: Icons.bar_chart,
                  color: Colors.purple.shade600,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StatsScreen()),
                    );
                  },
                ),
              ],
            ),
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
                          color: Colors.grey.shade800,
                        ),
                  ),
                  TextButton(
                    onPressed: () {
                       Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AddTerrainScreen()),
                        );
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
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final terrain = terrains[index];
                    return _DashboardTerrainItem(terrain: terrain);
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
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MaintenanceScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Intervention'),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final AsyncValue<int> valueAsync;
  final IconData icon;
  final Color color;
  final bool isAlert;
  final VoidCallback onTap;

  const _StatCard({
    required this.title,
    required this.valueAsync,
    required this.icon,
    required this.color,
    this.isAlert = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: color.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, color.withValues(alpha: 0.05)],
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 28),
                  valueAsync.when(
                    data: (val) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isAlert && val > 0 ? Colors.red.shade100 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$val',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isAlert && val > 0 ? Colors.red.shade700 : Colors.black87,
                        ),
                      ),
                    ),
                    loading: () => const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                    error: (_, __) => const Icon(Icons.error_outline, size: 16),
                  ),
                ],
              ),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardTerrainItem extends StatelessWidget {
  final Terrain terrain;

  const _DashboardTerrainItem({required this.terrain});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      color: Colors.white,
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TerrainMaintenanceHistoryScreen(terrain: terrain),
            ),
          );
        },
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getIconForTerrain(terrain.type),
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          terrain.nom,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(terrain.type.displayName),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }

  IconData _getIconForTerrain(TerrainType type) {
    switch (type) {
      case TerrainType.terreBattue:
        return Icons.landscape;
      case TerrainType.synthetique:
        return Icons.layers;
      case TerrainType.dur:
        return Icons.sports_tennis;
    }
  }
}

extension StringExtension on String {
    String capitalize() {
      return "${this[0].toUpperCase()}${substring(1)}";
    }
}
