import 'package:flutter/material.dart' hide DateUtils;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../domain/entities/terrain.dart';
import '../../providers/maintenance_provider.dart';
import '../widgets/add_maintenance_sheet.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../shared/widgets/common/image_viewer_dialog.dart';
import '../../../../shared/widgets/common/sync_status_indicator.dart';

class TerrainMaintenanceHistoryScreen extends ConsumerWidget {
  final Terrain terrain;

  const TerrainMaintenanceHistoryScreen({super.key, required this.terrain});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maintenancesAsync = ref.watch(
      maintenancesByTerrainProvider(terrain.id),
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(terrain.nom),
            pinned: true,
            actions: [
              const ConnectionStatusIndicator(),
              const SizedBox(width: 8),
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

          // Planned Section
          SliverToBoxAdapter(
            child: Consumer(
              builder: (context, ref, child) {
                final planned = ref.watch(
                  plannedMaintenancesByTerrainProvider(terrain.id),
                );
                if (planned.isEmpty) return const SizedBox.shrink();

                final nextPlanned = planned.first;
                final date = DateTime.fromMillisecondsSinceEpoch(
                  nextPlanned.date,
                );

                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Card(
                    color: Colors.orange.shade50,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.orange.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.schedule, color: Colors.orange),
                      title: const Text(
                        'Prochaine maintenance prévue',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      subtitle: Text(
                        '${nextPlanned.type} — le ${DateFormat('dd MMM yyyy', 'fr_FR').format(date)}',
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Stats Section (KPI Cards)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  child: maintenancesAsync.when(
                    data: (maintenances) {
                      final monthStart = DateTime.fromMillisecondsSinceEpoch(
                        DateUtils.startOfMonth(DateTime.now()),
                      );

                      final totalCount = maintenances.length;

                      final monthMaintenances = maintenances.where((m) {
                        final date = DateTime.fromMillisecondsSinceEpoch(
                          m.date,
                        );
                        return !date.isBefore(monthStart);
                      }).toList();

                      final monthCount = monthMaintenances.length;

                      final monthSacs = monthMaintenances.fold<int>(
                        0,
                        (sum, m) =>
                            sum +
                            m.sacsMantoUtilises +
                            m.sacsSottomantoUtilises +
                            m.sacsSiliceUtilises,
                      );

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildKPIChip(
                            icon: Icons.build,
                            color: Colors.blueGrey,
                            label: '$totalCount total',
                          ),
                          _buildKPIChip(
                            icon: Icons.check_circle,
                            color: Colors.green,
                            label: '$monthCount ce mois',
                          ),
                          _buildKPIChip(
                            icon: Icons.inventory_2,
                            color: Colors.brown,
                            label: '$monthSacs sacs ce mois',
                          ),
                        ],
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) =>
                        const Center(child: Text('Erreur de chargement')),
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
                delegate: SliverChildBuilderDelegate((context, index) {
                  final maintenance = maintenances[index];
                  final date = DateTime.fromMillisecondsSinceEpoch(
                    maintenance.date,
                  );
                  final formattedDate = DateFormat(
                    'dd MMM yyyy',
                    'fr_FR',
                  ).format(date);

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
                      return showDialog<bool>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Confirmer la suppression'),
                            content: const Text(
                              'Voulez-vous vraiment supprimer cette maintenance ?\nCette action est irréversible.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Annuler'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Supprimer'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    onDismissed: (direction) async {
                      try {
                        if (maintenance.firebaseId != null) {
                          await ref
                              .read(maintenanceNotifierProvider.notifier)
                              .deleteMaintenance(maintenance.firebaseId!);
                        }

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Maintenance supprimée'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                        }
                        // Refresh list to restore item if deletion failed
                        // ignore: unused_result
                        ref.refresh(maintenancesByTerrainProvider(terrain.id));
                      }
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      elevation: 0, // Flat look for list items
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: Colors.grey.withValues(alpha: 0.2),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        title: Row(
                          children: [
                            Text(
                              maintenance.type,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (maintenance.imagePath != null) ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => ImageViewerDialog(
                                      imagePath: maintenance.imagePath!,
                                    ),
                                  );
                                },
                                child: Icon(
                                  Icons.image_outlined,
                                  size: 18,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ],
                          ],
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
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                  ),
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
                                existingMaintenance: maintenance,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                }, childCount: maintenances.length),
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

  Widget _buildKPIChip({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
