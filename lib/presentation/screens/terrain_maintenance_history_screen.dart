import 'package:flutter/material.dart' hide DateUtils;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/terrain.dart';
import '../../domain/entities/maintenance.dart';
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

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text(
              terrain.nom,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Ajouter une maintenance',
                onPressed: () => _showAddMaintenance(context, terrain),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tableau de bord',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: "Aujourd'hui",
                          icon: Icons.today,
                          color: colorScheme.primaryContainer,
                          onColor: colorScheme.onPrimaryContainer,
                          asyncValue: todayTotalsAsync,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: "Cette semaine",
                          icon: Icons.calendar_view_week,
                          color: colorScheme.secondaryContainer,
                          onColor: colorScheme.onSecondaryContainer,
                          asyncValue: weekTotalsAsync,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Historique',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(top: 12)),
          maintenancesAsync.when(
            data: (maintenances) {
              if (maintenances.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_toggle_off,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Aucune maintenance',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final maintenance = maintenances[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _MaintenanceCard(
                        maintenance: maintenance,
                        terrain: terrain,
                        ref: ref,
                      ),
                    );
                  },
                  childCount: maintenances.length,
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, s) => SliverFillRemaining(
              child: Center(child: Text('Erreur: $e')),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMaintenance(context, terrain),
        icon: const Icon(Icons.add),
        label: const Text('Maintenance'),
      ),
    );
  }

  void _showAddMaintenance(BuildContext context, Terrain terrain) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => AddMaintenanceSheet(terrain: terrain),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Color onColor;
  final AsyncValue<({int manto, int sottomanto, int silice})> asyncValue;

  const _StatCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onColor,
    required this.asyncValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: onColor.withOpacity(0.7)),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: onColor.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          asyncValue.when(
            data: (totals) {
              if (totals.manto == 0 &&
                  totals.sottomanto == 0 &&
                  totals.silice == 0) {
                return Text(
                  'Aucune activité',
                  style: TextStyle(
                    color: onColor.withOpacity(0.6),
                    fontStyle: FontStyle.italic,
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (totals.manto > 0)
                    _StatRow(
                        label: 'Manto', value: totals.manto, color: onColor),
                  if (totals.sottomanto > 0)
                    _StatRow(
                        label: 'Sotto',
                        value: totals.sottomanto,
                        color: onColor),
                  if (totals.silice > 0)
                    _StatRow(
                        label: 'Silice', value: totals.silice, color: onColor),
                ],
              );
            },
            loading: () => SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: onColor.withOpacity(0.5)),
            ),
            error: (_, __) => const Icon(Icons.error_outline, size: 20),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatRow(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: color.withOpacity(0.8), fontSize: 13),
          ),
          Text(
            '$value sacs',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _MaintenanceCard extends StatelessWidget {
  final Maintenance maintenance;
  final Terrain terrain;
  final WidgetRef ref;

  const _MaintenanceCard({
    required this.maintenance,
    required this.terrain,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateTime.fromMillisecondsSinceEpoch(maintenance.date);
    final theme = Theme.of(context);

    // Determine color based on type (simple heuristic)
    final typeLower = maintenance.type.toLowerCase();
    Color badgeColor = theme.colorScheme.surfaceVariant;
    Color badgeTextColor = theme.colorScheme.onSurfaceVariant;
    IconData typeIcon = Icons.build_circle_outlined;

    if (typeLower.contains('recharge')) {
      badgeColor = Colors.orange.shade100;
      badgeTextColor = Colors.orange.shade900;
      typeIcon = Icons.add_circle_outline;
    } else if (typeLower.contains('nettoyage') ||
        typeLower.contains('brossage')) {
      badgeColor = Colors.blue.shade100;
      badgeTextColor = Colors.blue.shade900;
      typeIcon = Icons.cleaning_services_outlined;
    } else if (typeLower.contains('arrosage')) {
      badgeColor = Colors.blue.shade50;
      badgeTextColor = Colors.blue.shade800;
      typeIcon = Icons.water_drop_outlined;
    }

    return Dismissible(
      key: Key('maintenance-${maintenance.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.delete_outline,
          color: theme.colorScheme.onError,
          size: 32,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Confirmer"),
              content: const Text(
                  "Voulez-vous vraiment supprimer cette maintenance ?\nLes matériaux seront restitués au stock."),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("Annuler"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    "Supprimer",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (_) {
        ref
            .read(maintenanceNotifierProvider.notifier)
            .deleteMaintenance(maintenance.id!, terrain.id);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Maintenance supprimée'),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              showDragHandle: true,
              builder: (_) => AddMaintenanceSheet(
                terrain: terrain,
                maintenance: maintenance,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(typeIcon, color: badgeTextColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            maintenance.type,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            DateFormat.yMMMd('fr_FR').format(date),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (maintenance.commentaire != null &&
                    maintenance.commentaire!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    maintenance.commentaire!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (maintenance.sacsMantoUtilises > 0)
                      _MaterialChip(
                          label: 'Manto: ${maintenance.sacsMantoUtilises}'),
                    if (maintenance.sacsSottomantoUtilises > 0)
                      _MaterialChip(
                          label: 'Sotto: ${maintenance.sacsSottomantoUtilises}'),
                    if (maintenance.sacsSiliceUtilises > 0)
                      _MaterialChip(
                          label: 'Silice: ${maintenance.sacsSiliceUtilises}'),
                    if (maintenance.sacsMantoUtilises == 0 &&
                        maintenance.sacsSottomantoUtilises == 0 &&
                        maintenance.sacsSiliceUtilises == 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Aucun matériel',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MaterialChip extends StatelessWidget {
  final String label;

  const _MaterialChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: theme.colorScheme.secondaryContainer, width: 0.5),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
