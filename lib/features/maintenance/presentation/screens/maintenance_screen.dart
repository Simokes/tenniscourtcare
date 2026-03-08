import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../domain/entities/maintenance.dart';
import '../../../../domain/entities/terrain.dart';
import '../../../terrain/providers/terrain_provider.dart';
import '../../providers/maintenance_provider.dart';
import '../widgets/add_maintenance_sheet.dart';
import '../../../../shared/widgets/common/sync_status_indicator.dart';
import './maintenance_history_screen.dart';
import '../../../../core/theme/dashboard_theme_extension.dart';

class MaintenanceScreen extends ConsumerStatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  ConsumerState<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends ConsumerState<MaintenanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              title: const Text('Maintenances'),
              floating: true,
              pinned: true,
              expandedHeight: 120,
              actions: const [
                ConnectionStatusIndicator(mode: SyncIndicatorMode.compact),
                SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                        Theme.of(context).scaffoldBackgroundColor,
                      ],
                    ),
                  ),
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'À venir'),
                  Tab(text: 'Historique'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [_UpcomingMaintenancesTab(), _HistoryTab()],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle maintenance'),
        onPressed: () => showModalBottomSheet(
          context: context,
          useSafeArea: true,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => const AddMaintenanceSheet(),
        ),
      ),
    );
  }
}

class _UpcomingMaintenancesTab extends ConsumerWidget {
  void _openRescheduleSheet(
    BuildContext context,
    WidgetRef ref,
    Maintenance maintenance,
    Terrain terrain,
  ) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AddMaintenanceSheet(
        terrain: terrain,
        existingMaintenance: maintenance,
        forceCompleteMode: false,
        rescheduleMode: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dc = Theme.of(context).extension<DashboardColors>();
    final plannedMaintenancesAsync = ref.watch(plannedMaintenancesProvider);
    final terrainsAsync = ref.watch(terrainsProvider);

    if (plannedMaintenancesAsync.isLoading || terrainsAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (plannedMaintenancesAsync.hasError) {
      return Center(child: Text('Erreur: ${plannedMaintenancesAsync.error}'));
    }

    final maintenances = plannedMaintenancesAsync.value ?? [];
    final terrains = terrainsAsync.value ?? [];

    if (maintenances.isEmpty) {
      return const Center(child: Text('Aucune maintenance planifiée à venir.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: maintenances.length,
      itemBuilder: (context, index) {
        final maintenance = maintenances[index];
        final terrain = terrains.firstWhere(
          (t) => t.id == maintenance.terrainId,
          orElse: () => throw Exception('Terrain not found'),
        );
        final date = DateTime.fromMillisecondsSinceEpoch(maintenance.date);
        final maintenanceStart = DateTime(
          date.year,
          date.month,
          date.day,
          maintenance.startHour,
        );
        final maintenanceEnd = maintenanceStart.add(
          Duration(minutes: maintenance.durationMinutes),
        );

        final now = DateTime.now();
        final isOverdue = maintenanceEnd.isBefore(now);

        final color = isOverdue ? (dc?.dangerBgColor ?? Colors.red.shade50) : Theme.of(context).colorScheme.surface;
        final iconColor = isOverdue ? (dc?.dangerColor ?? Colors.red) : (dc?.warningColor ?? Colors.orange);
        final icon = isOverdue ? Icons.warning_amber : Icons.schedule;

        return Dismissible(
          key: ValueKey(maintenance.id ?? maintenance.date),
          direction: DismissDirection.horizontal,
          secondaryBackground: Container(
            color: dc?.dangerColor ?? Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          background: Container(
            color: dc?.maintenanceColor ?? Colors.brown,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            child: const Icon(Icons.edit_calendar, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.endToStart) {
              return showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Supprimer la maintenance'),
                  content: Text(
                    'Supprimer la maintenance prévue pour ${terrain.nom} '
                    'le ${DateFormat('dd/MM/yyyy').format(date)} ?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Annuler'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: dc?.dangerColor ?? Colors.red,
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Supprimer'),
                    ),
                  ],
                ),
              );
            }
            if (direction == DismissDirection.startToEnd) {
              _openRescheduleSheet(context, ref, maintenance, terrain);
              return false;
            }
            return false;
          },
          onDismissed: (direction) async {
            if (direction == DismissDirection.endToStart) {
              if (maintenance.firebaseId != null) {
                await ref
                    .read(maintenanceNotifierProvider.notifier)
                    .deleteMaintenance(maintenance.firebaseId!);
              }
            }
          },
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 0,
            color: color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isOverdue ? (dc?.dangerColor ?? Colors.red).withValues(alpha: 0.4) : Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: iconColor,
                child: Icon(icon, color: Colors.white),
              ),
              title: Row(
                children: [
                  Expanded(child: Text('${terrain.nom} — ${maintenance.type}')),
                  if (isOverdue)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: dc?.dangerColor ?? Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'En retard',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              subtitle: Text(
                'Prévu le ${DateFormat('dd/MM/yyyy').format(date)}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.check_circle_outline),
                color: dc?.successColor ?? Colors.green,
                iconSize: 32,
                tooltip: 'Marquer comme effectuée',
                onPressed: () => showModalBottomSheet(
                  context: context,
                  useSafeArea: true,
                  isScrollControlled: true,
                  showDragHandle: true,
                  builder: (_) => AddMaintenanceSheet(
                    terrain: terrain,
                    existingMaintenance: maintenance,
                    forceCompleteMode: true,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HistoryTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MaintenanceHistoryScreen();
  }
}
