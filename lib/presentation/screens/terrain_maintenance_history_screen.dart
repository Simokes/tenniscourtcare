import 'package:flutter/material.dart' hide DateUtils;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/terrain.dart';
import '../providers/maintenance_provider.dart';
import '../providers/stats_providers.dart';
import '../widgets/add_maintenance_sheet.dart';
import '../widgets/maintenance_stats_chart.dart';
import '../../utils/date_utils.dart';

class TerrainMaintenanceHistoryScreen extends ConsumerWidget {
  final Terrain terrain;

  const TerrainMaintenanceHistoryScreen({super.key, required this.terrain});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maintenancesAsync = ref.watch(
      maintenancesByTerrainProvider(terrain.id),
    );

    // Calculate stats periods
    final now = DateTime.now();
    final todayStart = DateUtils.startOfDay(now);
    final todayEnd = DateUtils.endOfDay(now);
    final weekStart = DateUtils.startOfWeek(now);
    final weekEnd = DateUtils.endOfWeek(now);

    final todayTotalsAsync = ref.watch(
      sacsTotalsProvider((
        terrainId: terrain.id,
        start: todayStart,
        end: todayEnd,
      )),
    );
    final weekTotalsAsync = ref.watch(
      sacsTotalsProvider((
        terrainId: terrain.id,
        start: weekStart,
        end: weekEnd,
      )),
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(terrain.nom),
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (_) => AddMaintenanceSheet(terrain: terrain),
                  );
                },
              ),
            ],
          ),

          // Stats Section (Charts)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 1, // Minimalist elevation
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Today Chart
                      Expanded(
                        child: todayTotalsAsync.when(
                          data: (totals) => MaintenanceStatsChart(
                            title: "Aujourd'hui",
                            manto: totals.manto,
                            sottomanto: totals.sottomanto,
                            silice: totals.silice,
                          ),
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (_, _) => const Center(child: Text('Erreur')),
                        ),
                      ),
                      // Divider
                      Container(
                        height: 100,
                        width: 1,
                        color: Colors.grey.withValues(alpha: 0.2),
                      ),
                      // Week Chart
                      Expanded(
                        child: weekTotalsAsync.when(
                          data: (totals) => MaintenanceStatsChart(
                            title: "Cette semaine",
                            manto: totals.manto,
                            sottomanto: totals.sottomanto,
                            silice: totals.silice,
                          ),
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (_, _) => const Center(child: Text('Erreur')),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Maintenance List
          maintenancesAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => SliverFillRemaining(
              child: Center(child: Text('Erreur: $error')),
            ),
            data: (maintenances) {
              if (maintenances.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text('Aucune maintenance enregistrée')),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final maintenance = maintenances[index];
                    final date = DateTime.fromMillisecondsSinceEpoch(maintenance.date);
                    final formattedDate = DateFormat('dd MMM yyyy', 'fr_FR').format(date);

                    return Dismissible(
                      key: Key('maintenance_${maintenance.id}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.redAccent,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20.0),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog<bool>(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Confirmer la suppression'),
                              content: const Text(
                                'Voulez-vous vraiment supprimer cette maintenance ?\nCette action est irréversible.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Annuler'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                                  child: const Text('Supprimer'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      onDismissed: (direction) async {
                        try {
                          await ref
                              .read(maintenanceNotifierProvider.notifier)
                              .deleteMaintenance(maintenance.id!, terrain.id);

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Maintenance supprimée')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erreur: $e')),
                            );
                          }
                          // Refresh list to restore item if deletion failed
                          // ignore: unused_result
                          ref.refresh(maintenancesByTerrainProvider(terrain.id));
                        }
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        elevation: 0, // Flat look for list items
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          title: Text(
                            maintenance.type,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(formattedDate),
                              if (maintenance.commentaire != null &&
                                  maintenance.commentaire!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    maintenance.commentaire!,
                                    style: const TextStyle(fontStyle: FontStyle.italic),
                                  ),
                                ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit_outlined),
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
                        ),
                      ),
                    );
                  },
                  childCount: maintenances.length,
                ),
              );
            },
          ),

          // Extra padding at bottom for FAB or just visual breathing room
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
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
