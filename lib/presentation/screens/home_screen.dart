import 'package:flutter/material.dart' hide DateUtils;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/terrain_provider.dart';
import '../providers/stats_providers.dart';
import '../widgets/terrain_card.dart';
import 'maintenance_screen.dart';
import 'stats_screen.dart';
import 'weather_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

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
        actions: [
          // Dans AppBar actions:
          IconButton(
            icon: const Icon(Icons.wb_sunny_outlined),
            onPressed: () {
              // Exemple : prend le premier terrain avec coordonnées
              final terrains = ref
                  .read(terrainsProvider)
                  .maybeWhen(data: (list) => list, orElse: () => const []);
              final t = terrains.firstWhere(
                (e) => e.latitude != null && e.longitude != null,
                orElse: () => terrains.isNotEmpty ? terrains.first : null,
              );
              if (t == null || t.latitude == null || t.longitude == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Aucun terrain avec coordonnées'),
                  ),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WeatherScreen(
                    titre: 'Météo - ${t.nom}',
                    latitude: t.latitude!,
                    longitude: t.longitude!,
                    terrainType: t.type,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StatsScreen()),
              );
            },
          ),
        ],
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
                      // TODO: Ajouter un terrain
                    },
                    child: const Text('Ajouter un terrain'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Carte des totaux du mois
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
                              _TotalItem(
                                label: 'Sottomanto',
                                value: totals.sottomanto,
                              ),
                              _TotalItem(label: 'Silice', value: totals.silice),
                            ],
                          ),
                        ],
                      ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => Text('Erreur: $error'),
                    ),
                  ),
                ),
              ),
              // Liste des terrains
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
