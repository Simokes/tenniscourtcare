import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tenniscourtcare/domain/entities/terrain.dart';
import 'package:tenniscourtcare/presentation/providers/terrain_health_provider.dart';
import 'package:tenniscourtcare/presentation/widgets/terrain_health_gauge.dart';
import 'package:go_router/go_router.dart';

class DashboardTerrainItem extends StatelessWidget {
  final Terrain terrain;

  const DashboardTerrainItem({super.key, required this.terrain});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      // color handled by Theme (CardTheme)
      child: ListTile(
        onTap: () {
          context.push('/terrain/${terrain.id}');
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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(terrain.type.displayName),
            const SizedBox(height: 6),
            Consumer(
              builder: (context, ref, _) {
                final healthAsync = ref.watch(
                  terrainHealthProvider(terrain.id),
                );
                return healthAsync.when(
                  data: (state) => TerrainHealthGauge(
                    score: state.score,
                    warningMessage: state.warningMessage,
                  ),
                  loading: () => const SizedBox(
                    height: 6,
                    width: 100,
                    child: LinearProgressIndicator(color: Colors.grey),
                  ),
                  error: (error, stack) => const SizedBox.shrink(),
                );
              },
            ),
          ],
        ),
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
