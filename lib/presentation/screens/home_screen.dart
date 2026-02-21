import 'package:flutter/material.dart' hide DateUtils;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/terrain_provider.dart';
import '../providers/stats_providers.dart';
import '../widgets/terrain_card.dart';
import 'maintenance_screen.dart';
import 'stats_screen.dart';
import 'weather_screen.dart';
import '../../domain/entities/terrain.dart';
import 'settings_screen.dart';
import 'stock_screen.dart';
import '../screens/add_terrain_screen.dart';


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
    final terrainsAsync = ref.watch(terrainsProvider);
    final monthKey = DateTime(DateTime.now().year, DateTime.now().month);
    final monthlyTotalsAsync = ref.watch(
      monthlyTotalsAllTerrainsProvider(monthKey),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Court Care'),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.sports_tennis,
                      size: 48,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Court Care',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('Gestion du Stock'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StockScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.wb_sunny_outlined),
              title: const Text('Météo du club'),
              onTap: () {
                Navigator.pop(context);
                _openWeatherForFirstTerrainWithCoords(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Statistiques'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StatsScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Paramètres'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'v1.0.0',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
      body: terrainsAsync.when(
        data: (terrains) {
          if (terrains.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Aucun terrain enregistré'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AddTerrainScreen()),
                        );
                      },
                    child: const Text('Ajouter un terrain'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: monthlyTotalsAsync.when(
                      data: (totals) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Totaux du mois',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _TotalItem(label: 'Manto', value: totals.manto),
                              _TotalItem(label: 'Sottomanto', value: totals.sottomanto),
                              _TotalItem(label: 'Silice', value: totals.silice),
                            ],
                          ),
                        ],
                      ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => Text('Erreur: $error'),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: terrains.length,
                  itemBuilder: (context, index) {
                    final terrain = terrains[index];
                    return TerrainCard(terrain: terrain);
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Erreur: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MaintenanceScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _TotalItem extends StatelessWidget {
  final String label;
  final int value;

  const _TotalItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$value', style: Theme.of(context).textTheme.headlineSmall),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
