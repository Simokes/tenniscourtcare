import 'package:flutter/material.dart' hide DateUtils;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/terrain.dart';
import '../providers/maintenance_provider.dart';
import '../providers/stats_providers.dart';
import '../widgets/add_maintenance_sheet.dart';
import '../../utils/date_utils.dart';

class TerrainMaintenanceHistoryScreen extends ConsumerWidget {
  final Terrain terrain;

  const TerrainMaintenanceHistoryScreen({super.key, required this.terrain});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maintenancesAsync = ref.watch(
      maintenancesByTerrainProvider(terrain.id),
    );
    final now = DateTime.now();
    final todayTotalsAsync = ref.watch(
      sacsTotalsProvider((
        terrainId: terrain.id,
        start: DateUtils.startOfDay(now),
        end: DateUtils.endOfDay(now),
      )),
    );
    final weekTotalsAsync = ref.watch(
      sacsTotalsProvider((
        terrainId: terrain.id,
        start: DateUtils.startOfWeek(now),
        end: DateUtils.endOfWeek(now),
      )),
    );

    return Scaffold(
      appBar: AppBar(title: Text(terrain.nom)),
      body: Column(
        children: [
          // Cartes Aujourd'hui + Cette semaine
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: todayTotalsAsync.when(
                        data: (totals) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Aujourd\'hui',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text('Manto: ${totals.manto}'),
                            Text('Sotto: ${totals.sottomanto}'),
                            Text('Silice: ${totals.silice}'),
                          ],
                        ),
                        loading: () => const CircularProgressIndicator(),
                        error: (e, _) => Text('Erreur: $e'),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: weekTotalsAsync.when(
                        data: (totals) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cette semaine',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text('Manto: ${totals.manto}'),
                            Text('Sotto: ${totals.sottomanto}'),
                            Text('Silice: ${totals.silice}'),
                          ],
                        ),
                        loading: () => const CircularProgressIndicator(),
                        error: (e, _) => Text('Erreur: $e'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Liste des maintenances
          Expanded(
            child: maintenancesAsync.when(
              data: (maintenances) {
                if (maintenances.isEmpty) {
                  return const Center(
                    child: Text('Aucune maintenance enregistrée'),
                  );
                }

                return ListView.builder(
                  itemCount: maintenances.length,
                  itemBuilder: (context, index) {
                    final maintenance = maintenances[index];
                    final date = DateTime.fromMillisecondsSinceEpoch(
                      maintenance.date,
                    );

                    return ListTile(
                      title: Text(maintenance.type),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${date.day}/${date.month}/${date.year}'),
                          if (maintenance.commentaire != null)
                            Text(maintenance.commentaire!),
                          Text(
                            'Manto: ${maintenance.sacsMantoUtilises}, '
                            'Sotto: ${maintenance.sacsSottomantoUtilises}, '
                            'Silice: ${maintenance.sacsSiliceUtilises}',
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => AddMaintenanceSheet(
                              terrain: terrain,
                              maintenance: maintenance,
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Erreur: $error')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => AddMaintenanceSheet(terrain: terrain),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
