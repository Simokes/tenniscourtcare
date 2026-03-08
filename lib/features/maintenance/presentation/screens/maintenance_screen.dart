import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
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

class _MaintenanceScreenState extends ConsumerState<MaintenanceScreen> {
  @override
  Widget build(BuildContext context) {
    final overdueCount = ref.watch(overdueCountProvider);
    final plannedAsync = ref.watch(plannedMaintenancesProvider);
    final allAsync = ref.watch(maintenancesProvider);
    final terrainsAsync = ref.watch(terrainsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final dc = Theme.of(context).extension<DashboardColors>();

    final now = DateTime.now();
    final firstOfMonth = DateTime(now.year, now.month, 1);
    final allMaintenances = allAsync.valueOrNull ?? const [];
    final doneThisMonth = allMaintenances
        .where((m) =>
            !m.isPlanned &&
            DateTime.fromMillisecondsSinceEpoch(m.date).isAfter(firstOfMonth))
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenances'),
        actions: const [
          ConnectionStatusIndicator(mode: SyncIndicatorMode.compact),
          SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // KPI Strip
          SliverToBoxAdapter(
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: _buildKpiChip(
                      icon: Icons.warning_amber_rounded,
                      text: '$overdueCount en retard',
                      color: overdueCount > 0
                          ? dc?.dangerColor ?? Colors.red
                          : colorScheme.onSurfaceVariant,
                      bgColor: overdueCount > 0
                          ? dc?.dangerBgColor ?? Colors.red.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderColor: colorScheme.outlineVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildKpiChip(
                      icon: Icons.schedule,
                      text: '${(plannedAsync.valueOrNull ?? []).length} à venir',
                      color: dc?.maintenanceColor ?? Colors.blue,
                      bgColor: Colors.transparent,
                      borderColor: colorScheme.outlineVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildKpiChip(
                      icon: Icons.check_circle_outline,
                      text: '$doneThisMonth ce mois',
                      color: dc?.successColor ?? Colors.green,
                      bgColor: Colors.transparent,
                      borderColor: colorScheme.outlineVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Temporal Sections
          SliverToBoxAdapter(
            child: Consumer(
              builder: (context, ref, child) {
                if (plannedAsync.isLoading || terrainsAsync.isLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (plannedAsync.hasError || terrainsAsync.hasError) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('Erreur de chargement'),
                    ),
                  );
                }

                final planned = plannedAsync.valueOrNull ?? [];
                final terrains = terrainsAsync.valueOrNull ?? [];

                final todayDate = DateTime(now.year, now.month, now.day);
                final tomorrowDate = todayDate.add(const Duration(days: 1));
                final weekFromTodayDate = todayDate.add(const Duration(days: 7));

                final overdueItems = <Maintenance>[];
                final todayItems = <Maintenance>[];
                final thisWeekItems = <Maintenance>[];
                final laterItems = <Maintenance>[];

                for (final m in planned) {
                  final mDate = DateTime.fromMillisecondsSinceEpoch(m.date);
                  final mDateOnly = DateTime(mDate.year, mDate.month, mDate.day);
                  final mStart = DateTime(
                      mDate.year, mDate.month, mDate.day, m.startHour);
                  final mEnd =
                      mStart.add(Duration(minutes: m.durationMinutes));

                  if (mEnd.isBefore(now)) {
                    overdueItems.add(m);
                  } else if (mDateOnly == todayDate && !mEnd.isBefore(now)) {
                    todayItems.add(m);
                  } else if (mDateOnly.compareTo(tomorrowDate) >= 0 &&
                      mDateOnly.isBefore(weekFromTodayDate)) {
                    thisWeekItems.add(m);
                  } else if (mDateOnly.compareTo(weekFromTodayDate) >= 0) {
                    laterItems.add(m);
                  }
                }

                overdueItems.sort((a, b) {
                  final aEnd = DateTime.fromMillisecondsSinceEpoch(a.date)
                      .add(Duration(minutes: a.durationMinutes));
                  final bEnd = DateTime.fromMillisecondsSinceEpoch(b.date)
                      .add(Duration(minutes: b.durationMinutes));
                  return aEnd.compareTo(bEnd);
                });
                todayItems.sort((a, b) => a.startHour.compareTo(b.startHour));
                thisWeekItems.sort((a, b) => a.date.compareTo(b.date));
                laterItems.sort((a, b) => a.date.compareTo(b.date));

                Terrain getTerrain(int id) =>
                    terrains.firstWhere((t) => t.id == id,
                        orElse: () => throw Exception('Terrain not found'));

                return Column(
                  children: [
                    if (overdueItems.isNotEmpty) ...[
                      _MaintenanceSectionHeader(
                        label: 'En retard',
                        count: overdueItems.length,
                        color: dc?.dangerColor,
                      ),
                      ...overdueItems.map((m) => _MaintenanceActionCard(
                            maintenance: m,
                            terrain: getTerrain(m.terrainId),
                            isOverdue: true,
                          )),
                    ],
                    if (todayItems.isNotEmpty) ...[
                      _MaintenanceSectionHeader(
                        label: 'Aujourd\'hui',
                        count: todayItems.length,
                      ),
                      ...todayItems.map((m) => _MaintenanceActionCard(
                            maintenance: m,
                            terrain: getTerrain(m.terrainId),
                            isOverdue: false,
                          )),
                    ],
                    if (thisWeekItems.isNotEmpty) ...[
                      _MaintenanceSectionHeader(
                        label: 'Cette semaine',
                        count: thisWeekItems.length,
                      ),
                      ...thisWeekItems.map((m) => _MaintenancePlannedCard(
                            maintenance: m,
                            terrain: getTerrain(m.terrainId),
                          )),
                    ],
                    if (laterItems.isNotEmpty) ...[
                      _MaintenanceSectionHeader(
                        label: 'Plus tard',
                        count: laterItems.length,
                      ),
                      ...laterItems.map((m) => _MaintenancePlannedCard(
                            maintenance: m,
                            terrain: getTerrain(m.terrainId),
                          )),
                    ],
                    if (planned.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.check_circle_outline,
                                  size: 48,
                                  color: dc?.successColor ?? Colors.green),
                              const SizedBox(height: 12),
                              Text('Aucune maintenance planifiée',
                                  style: Theme.of(context).textTheme.titleMedium),
                            ],
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 16),
                      child: TextButton.icon(
                        icon: const Icon(Icons.history),
                        label: const Text("Voir l'historique"),
                        onPressed: () {
                          // Essayer GoRouter en premier, fallback sur Navigator
                          try {
                            context.go('/maintenance/history');
                          } catch (_) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MaintenanceHistoryScreen(),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                );
              },
            ),
          ),
        ],
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

  Widget _buildKpiChip({
    required IconData icon,
    required String text,
    required Color color,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _MaintenanceSectionHeader extends StatelessWidget {
  final String label;
  final int count;
  final Color? color;

  const _MaintenanceSectionHeader({
    required this.label,
    required this.count,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            color: color ?? colorScheme.primary,
            margin: const EdgeInsets.only(right: 8),
          ),
          Text(
            '$label ($count)',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: color ?? colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

class _MaintenanceActionCard extends ConsumerWidget {
  final Maintenance maintenance;
  final Terrain terrain;
  final bool isOverdue;

  const _MaintenanceActionCard({
    required this.maintenance,
    required this.terrain,
    required this.isOverdue,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final dc = Theme.of(context).extension<DashboardColors>();

    final date = DateTime.fromMillisecondsSinceEpoch(maintenance.date);
    final start =
        DateTime(date.year, date.month, date.day, maintenance.startHour);
    final end = start.add(Duration(minutes: maintenance.durationMinutes));
    final timeLabel = isOverdue
        ? 'Prévu ${DateFormat('dd/MM yyyy').format(date)} à ${maintenance.startHour}h'
        : '${maintenance.startHour.toString().padLeft(2, '0')}h${start.minute.toString().padLeft(2, '0')} - ${end.hour.toString().padLeft(2, '0')}h${end.minute.toString().padLeft(2, '0')}';

    final dangerColor = dc?.dangerColor ?? Colors.red;
    final dangerBgColor = dc?.dangerBgColor ?? Colors.red.withValues(alpha: 0.1);
    final successColor = dc?.successColor ?? Colors.green;

    return Dismissible(
      key: ValueKey(maintenance.id ?? maintenance.date),
      direction: DismissDirection.endToStart,
      background: Container(
        color: dangerColor,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) => showDialog<bool>(
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
              style: FilledButton.styleFrom(backgroundColor: dangerColor),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Supprimer'),
            ),
          ],
        ),
      ),
      onDismissed: (direction) async {
        if (maintenance.firebaseId != null) {
          await ref
              .read(maintenanceNotifierProvider.notifier)
              .deleteMaintenance(maintenance.firebaseId!);
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isOverdue
                ? dangerColor.withValues(alpha: 0.4)
                : colorScheme.outlineVariant,
          ),
        ),
        color: isOverdue ? dangerBgColor : colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          terrain.nom,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${maintenance.type} • $timeLabel',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (isOverdue)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: dangerColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'EN RETARD',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.edit_calendar, size: 16),
                    label: const Text('Reporter'),
                    style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact),
                    onPressed: () => showModalBottomSheet(
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
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Compléter'),
                    style: FilledButton.styleFrom(
                      backgroundColor: successColor,
                      visualDensity: VisualDensity.compact,
                    ),
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MaintenancePlannedCard extends ConsumerWidget {
  final Maintenance maintenance;
  final Terrain terrain;

  const _MaintenancePlannedCard({
    required this.maintenance,
    required this.terrain,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final dc = Theme.of(context).extension<DashboardColors>();

    final date = DateTime.fromMillisecondsSinceEpoch(maintenance.date);
    final dayLabel = DateFormat('EEE dd/MM', 'fr_FR').format(date);
    final maintenanceColor = dc?.maintenanceColor ?? Colors.blue;
    final dangerColor = dc?.dangerColor ?? Colors.red;

    return Dismissible(
      key: ValueKey(maintenance.id ?? maintenance.date),
      direction: DismissDirection.endToStart,
      background: Container(
        color: dangerColor,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) => showDialog<bool>(
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
              style: FilledButton.styleFrom(backgroundColor: dangerColor),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Supprimer'),
            ),
          ],
        ),
      ),
      onDismissed: (direction) async {
        if (maintenance.firebaseId != null) {
          await ref
              .read(maintenanceNotifierProvider.notifier)
              .deleteMaintenance(maintenance.firebaseId!);
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        color: colorScheme.surface,
        child: ListTile(
          dense: true,
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: maintenanceColor.withValues(alpha: 0.15),
            child: Icon(Icons.build_circle_outlined,
                size: 18, color: maintenanceColor),
          ),
          title: Text('${terrain.nom} • ${maintenance.type}',
              style: Theme.of(context).textTheme.bodyMedium),
          subtitle: Text(
              '${maintenance.startHour.toString().padLeft(2, '0')}h • $dayLabel',
              style: Theme.of(context).textTheme.bodySmall),
          trailing: const Icon(Icons.chevron_right, size: 18),
          onTap: () => showModalBottomSheet(
            context: context,
            useSafeArea: true,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (_) => AddMaintenanceSheet(
              terrain: terrain,
              existingMaintenance: maintenance,
            ),
          ),
        ),
      ),
    );
  }
}
