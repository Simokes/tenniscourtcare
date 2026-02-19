import 'package:flutter/material.dart' hide DateUtils;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/terrain.dart';
import '../providers/stats_providers.dart';
import '../screens/terrain_maintenance_history_screen.dart';
import '../widgets/add_maintenance_sheet.dart';
import '../../utils/date_utils.dart';

class TerrainCard extends ConsumerWidget {
  final Terrain terrain;

  const TerrainCard({super.key, required this.terrain});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maintenancesDuJourAsync = ref.watch(
      sacsTotalsProvider((
        terrainId: terrain.id,
        start: DateUtils.startOfDay(DateTime.now()),
        end: DateUtils.endOfDay(DateTime.now()),
      )),
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TerrainMaintenanceHistoryScreen(terrain: terrain),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      terrain.nom,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(terrain.type.displayName),
                    const SizedBox(height: 8),
                    maintenancesDuJourAsync.when(
                      data: (totals) => Text(
                        'Aujourd\'hui: '
                        'Manto ${totals.manto}, '
                        'Sotto ${totals.sottomanto}, '
                        'Silice ${totals.silice}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      loading: () => const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => AddMaintenanceSheet(terrain: terrain),
                  );
                },
                tooltip: 'Ajouter une maintenance',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
