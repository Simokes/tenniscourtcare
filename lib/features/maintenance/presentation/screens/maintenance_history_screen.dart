import 'package:flutter/material.dart' hide DateUtils;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/date_utils.dart';
import '../../../../domain/entities/maintenance.dart';
import '../../../../domain/entities/terrain.dart';
import '../../../terrain/providers/terrain_provider.dart';
import '../../providers/maintenance_provider.dart';
import '../widgets/add_maintenance_sheet.dart';
import '../../../../core/theme/dashboard_theme_extension.dart';

class MaintenanceHistoryScreen extends ConsumerStatefulWidget {
  const MaintenanceHistoryScreen({super.key});

  @override
  ConsumerState<MaintenanceHistoryScreen> createState() =>
      _MaintenanceHistoryScreenState();
}

class _MaintenanceHistoryScreenState
    extends ConsumerState<MaintenanceHistoryScreen> {
  String? _selectedType;
  String _selectedPeriod = 'all'; // 'all', 'week', 'month', 'year'
  String _selectedStatus = 'all'; // 'all', 'done', 'planned'
  final Set<int> _expandedTerrains = {};

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dc = Theme.of(context).extension<DashboardColors>();
    final terrainsAsync = ref.watch(terrainsProvider);
    final maintenancesAsync = ref.watch(maintenancesProvider);
    final plannedMaintenancesAsync = ref.watch(plannedMaintenancesProvider);
    final maintenanceTypes = ref.watch(maintenanceTypesProvider);

    final now = DateTime.now();
    DateTime? startDate;
    if (_selectedPeriod == 'week') {
      startDate = DateTime.fromMillisecondsSinceEpoch(DateUtils.startOfWeek(now));
    } else if (_selectedPeriod == 'month') {
      startDate = DateTime.fromMillisecondsSinceEpoch(DateUtils.startOfMonth(now));
    } else if (_selectedPeriod == 'year') {
      startDate = DateTime(now.year, 1, 1);
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            title: Text('Historique'),
            floating: true,
            snap: true,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
          ),
          // KPI Row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildKPIRow(
                maintenancesAsync.valueOrNull ?? [],
                plannedMaintenancesAsync.valueOrNull ?? [],
                cs,
                dc,
                startDate,
              ),
            ),
          ),

          // Filter Bar
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  // Period Filter
                  _buildChoiceChip(
                    'Tout',
                    'all',
                    _selectedPeriod,
                    (val) => setState(() => _selectedPeriod = val),
                  ),
                  const SizedBox(width: 8),
                  _buildChoiceChip(
                    'Cette semaine',
                    'week',
                    _selectedPeriod,
                    (val) => setState(() => _selectedPeriod = val),
                  ),
                  const SizedBox(width: 8),
                  _buildChoiceChip(
                    'Ce mois',
                    'month',
                    _selectedPeriod,
                    (val) => setState(() => _selectedPeriod = val),
                  ),
                  const SizedBox(width: 8),
                  _buildChoiceChip(
                    'Cette année',
                    'year',
                    _selectedPeriod,
                    (val) => setState(() => _selectedPeriod = val),
                  ),

                  const SizedBox(width: 20),
                  Container(width: 1, height: 24, color: cs.outlineVariant),
                  const SizedBox(width: 20),

                  // Type Filter (Dropdown)
                  DropdownMenu<String?>(
                    initialSelection: _selectedType,
                    hintText: 'Tous types',
                    width: 140,
                    inputDecorationTheme: InputDecorationTheme(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    dropdownMenuEntries: [
                      const DropdownMenuEntry<String?>(value: null, label: 'Tous types'),
                      ...maintenanceTypes.map((type) => DropdownMenuEntry<String?>(value: type, label: type)),
                    ],
                    onSelected: (val) => setState(() => _selectedType = val),
                  ),

                  const SizedBox(width: 20),
                  Container(width: 1, height: 24, color: cs.outlineVariant),
                  const SizedBox(width: 20),

                  // Status Filter
                  _buildChoiceChip(
                    'Tout',
                    'all',
                    _selectedStatus,
                    (val) => setState(() => _selectedStatus = val),
                  ),
                  const SizedBox(width: 8),
                  _buildChoiceChip(
                    'Effectuées',
                    'done',
                    _selectedStatus,
                    (val) => setState(() => _selectedStatus = val),
                  ),
                  const SizedBox(width: 8),
                  _buildChoiceChip(
                    'Planifiées',
                    'planned',
                    _selectedStatus,
                    (val) => setState(() => _selectedStatus = val),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Terrain List
          terrainsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => SliverFillRemaining(
              child: Center(child: Text('Erreur: $error')),
            ),
            data: (terrains) {
              if (terrains.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text('Aucun terrain enregistré')),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final terrain = terrains[index];
                  return _TerrainHistoryTile(
                    terrain: terrain,
                    isExpanded: _expandedTerrains.contains(terrain.id),
                    onToggle: () => setState(() {
                      if (_expandedTerrains.contains(terrain.id)) {
                        _expandedTerrains.remove(terrain.id);
                      } else {
                        _expandedTerrains.add(terrain.id);
                      }
                    }),
                    selectedType: _selectedType,
                    selectedPeriod: _selectedPeriod,
                    selectedStatus: _selectedStatus,
                  );
                }, childCount: terrains.length),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildChoiceChip(
    String label,
    String value,
    String groupValue,
    ValueChanged<String> onSelected,
  ) {
    return ChoiceChip(
      label: Text(label),
      selected: groupValue == value,
      onSelected: (selected) {
        if (selected) onSelected(value);
      },
    );
  }

  Widget _buildKPIRow(
    List<Maintenance> allMaintenances,
    List<Maintenance> plannedMaintenances,
    ColorScheme cs,
    DashboardColors? dc,
    DateTime? startDate,
  ) {
    final doneCount = allMaintenances.where((m) {
      if (m.isPlanned) return false;
      if (startDate != null) {
        final date = DateTime.fromMillisecondsSinceEpoch(m.date);
        if (date.isBefore(startDate)) return false;
      }
      return true;
    }).length;
    final plannedCount = plannedMaintenances.where((m) {
      if (startDate != null) {
        final date = DateTime.fromMillisecondsSinceEpoch(m.date);
        if (date.isBefore(startDate)) return false;
      }
      return true;
    }).length;
    final totalCount = doneCount + plannedCount;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildKPIChip(
          icon: Icons.build,
          color: cs.onSurfaceVariant,
          label: '$totalCount total',
        ),
        _buildKPIChip(
          icon: Icons.check_circle,
          color: dc?.successColor ?? Colors.green,
          label: '$doneCount effectuées',
        ),
        _buildKPIChip(
          icon: Icons.calendar_today,
          color: dc?.warningColor ?? Colors.orange,
          label: '$plannedCount planifiées',
        ),
      ],
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

class _TerrainHistoryTile extends ConsumerWidget {
  final Terrain terrain;
  final bool isExpanded;
  final VoidCallback onToggle;
  final String? selectedType;
  final String selectedPeriod;
  final String selectedStatus;

  const _TerrainHistoryTile({
    required this.terrain,
    required this.isExpanded,
    required this.onToggle,
    this.selectedType,
    required this.selectedPeriod,
    required this.selectedStatus,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final dc = Theme.of(context).extension<DashboardColors>();
    final allDone =
        ref.watch(maintenancesGroupedByTerrainProvider)[terrain.id] ?? [];
    final allPlanned = ref.watch(
      plannedMaintenancesByTerrainProvider(terrain.id),
    );

    // Combine and apply filters
    final List<Maintenance> filteredMaintenances = [];

    final now = DateTime.now();
    DateTime? startDate;
    if (selectedPeriod == 'week') {
      startDate = DateTime.fromMillisecondsSinceEpoch(
        DateUtils.startOfWeek(now),
      );
    } else if (selectedPeriod == 'month') {
      startDate = DateTime.fromMillisecondsSinceEpoch(
        DateUtils.startOfMonth(now),
      );
    } else if (selectedPeriod == 'year') {
      startDate = DateTime(now.year, 1, 1);
    }

    if (selectedStatus == 'all' || selectedStatus == 'done') {
      filteredMaintenances.addAll(
        allDone.where((m) {
          if (selectedType != null && m.type != selectedType) return false;
          if (startDate != null) {
            final date = DateTime.fromMillisecondsSinceEpoch(m.date);
            if (date.isBefore(startDate)) return false;
          }
          return true;
        }),
      );
    }

    if (selectedStatus == 'all' || selectedStatus == 'planned') {
      filteredMaintenances.addAll(
        allPlanned.where((m) {
          if (selectedType != null && m.type != selectedType) return false;
          if (startDate != null) {
            final date = DateTime.fromMillisecondsSinceEpoch(m.date);
            if (date.isBefore(startDate)) return false;
          }
          return true;
        }),
      );
    }

    // Sort combined filtered list by date desc
    filteredMaintenances.sort((a, b) => b.date.compareTo(a.date));

    // Calculate collapsed counts
    int filteredDoneCount = 0;
    if (selectedStatus != 'planned') {
      filteredDoneCount = allDone.where((m) {
        if (selectedType != null && m.type != selectedType) return false;
        if (startDate != null) {
          final date = DateTime.fromMillisecondsSinceEpoch(m.date);
          if (date.isBefore(startDate)) return false;
        }
        return true;
      }).length;
    }

    final plannedCount = startDate == null
        ? allPlanned.length
        : allPlanned.where((m) {
            final date = DateTime.fromMillisecondsSinceEpoch(m.date);
            return !date.isBefore(startDate!);
          }).length;

    DateTime? lastDoneDate;
    if (allDone.isNotEmpty) {
      lastDoneDate = DateTime.fromMillisecondsSinceEpoch(allDone.first.date);
    }

    final formattedLastDate = lastDoneDate != null
        ? DateFormat('dd MMM', 'fr_FR').format(lastDoneDate)
        : 'Aucune maintenance';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: terrain.status.color.withValues(alpha: 0.2),
              child: Icon(terrain.status.icon, color: terrain.status.color),
            ),
            title: Text(
              terrain.nom,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline, size: 14, color: dc?.successColor ?? Colors.green),
                    const SizedBox(width: 4),
                    Text('$filteredDoneCount effectuées', style: TextStyle(color: dc?.successColor ?? Colors.green, fontSize: 12)),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 14, color: dc?.warningColor ?? Colors.orange),
                    const SizedBox(width: 4),
                    Text('$plannedCount planifiées', style: TextStyle(color: dc?.warningColor ?? Colors.orange, fontSize: 12)),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time_outlined, size: 14, color: cs.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text('Dernière: $formattedLastDate', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
              ],
            ),
            onTap: onToggle,
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: filteredMaintenances.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    child: Column(
                      children: [
                        Icon(Icons.inbox_outlined, size: 32, color: cs.onSurfaceVariant),
                        const SizedBox(height: 8),
                        Text(
                          'Aucune maintenance pour cette période',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredMaintenances.length,
                    itemBuilder: (context, index) {
                      return _MaintenanceHistoryItem(
                        maintenance: filteredMaintenances[index],
                        terrain: terrain,
                      );
                    },
                  ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

class _MaintenanceHistoryItem extends ConsumerWidget {
  final Maintenance maintenance;
  final Terrain terrain;

  const _MaintenanceHistoryItem({
    required this.maintenance,
    required this.terrain,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final dc = Theme.of(context).extension<DashboardColors>();
    final date = DateTime.fromMillisecondsSinceEpoch(maintenance.date);
    final formattedDate = DateFormat('dd MMM yyyy', 'fr_FR').format(date);
    final isPlanned = maintenance.isPlanned;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isPlanned ? Icons.schedule : Icons.check_circle,
                        color: isPlanned ? (dc?.warningColor ?? Colors.orange) : (dc?.successColor ?? Colors.green),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        maintenance.type,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (maintenance.imagePath != null) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.image_outlined,
                          size: 14,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (maintenance.commentaire != null &&
                      maintenance.commentaire!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      maintenance.commentaire!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (maintenance.sacsMantoUtilises > 0)
                        _SacChip(
                          'Manto: ${maintenance.sacsMantoUtilises}',
                          Colors.brown,
                        ),
                      if (maintenance.sacsSottomantoUtilises > 0)
                        _SacChip(
                          'Sott.: ${maintenance.sacsSottomantoUtilises}',
                          Colors.blueGrey,
                        ),
                      if (maintenance.sacsSiliceUtilises > 0)
                        _SacChip(
                          'Silice: ${maintenance.sacsSiliceUtilises}',
                          Colors.teal,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      showDragHandle: true,
                      builder: (_) => AddMaintenanceSheet(
                        terrain: terrain,
                        existingMaintenance: maintenance,
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: dc?.dangerColor ?? Colors.red,
                  ),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirmer la suppression'),
                        content: const Text(
                          'Voulez-vous vraiment supprimer cette maintenance ?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Annuler'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: TextButton.styleFrom(
                              foregroundColor: dc?.dangerColor ?? Colors.red,
                            ),
                            child: const Text('Supprimer'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && maintenance.firebaseId != null) {
                      try {
                        await ref
                            .read(maintenanceNotifierProvider.notifier)
                            .deleteMaintenance(maintenance.firebaseId!);
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
                      }
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SacChip extends StatelessWidget {
  final String label;
  final Color color;

  const _SacChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
