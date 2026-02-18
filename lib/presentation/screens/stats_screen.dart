import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/stats_period_provider.dart';
import '../providers/selected_terrains_provider.dart';
import '../providers/terrain_provider.dart';
import '../providers/stats_providers.dart';
import '../widgets/grouped_bar_chart.dart';
import '../../utils/csv_export.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  bool _stacked = false;

  @override
  Widget build(BuildContext context) {
    final period = ref.watch(statsPeriodProvider);
    final selectedTerrains = ref.watch(selectedTerrainsProvider);
    final terrainsAsync = ref.watch(terrainsProvider);
    final sacksSeriesAsync = ref.watch(sacksSeriesProvider);
    final maintenanceTypesAsync = ref.watch(maintenanceTypesSeriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () async {
              sacksSeriesAsync.whenData((data) async {
                await CsvExport.exportSacksSeries(
                  data: data,
                  filename: 'sacks_series_${DateTime.now().millisecondsSinceEpoch}',
                  context: context,
                );
              });
            },
            tooltip: 'Exporter en CSV',
          ),
          IconButton(
            icon: Icon(_stacked ? Icons.view_column : Icons.view_agenda),
            onPressed: () {
              setState(() {
                _stacked = !_stacked;
              });
            },
            tooltip: _stacked ? 'Vue groupée' : 'Vue empilée',
          ),
        ],
      ),
      body: Column(
        children: [
          // Sélection période
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _PeriodButton(
                    label: 'Jour',
                    type: PeriodType.day,
                    currentType: period.type,
                    onTap: () {
                      ref.read(statsPeriodProvider.notifier).setPeriod(
                            PeriodType.day,
                          );
                    },
                  ),
                  _PeriodButton(
                    label: 'Semaine',
                    type: PeriodType.week,
                    currentType: period.type,
                    onTap: () {
                      ref.read(statsPeriodProvider.notifier).setPeriod(
                            PeriodType.week,
                          );
                    },
                  ),
                  _PeriodButton(
                    label: 'Mois',
                    type: PeriodType.month,
                    currentType: period.type,
                    onTap: () {
                      ref.read(statsPeriodProvider.notifier).setPeriod(
                            PeriodType.month,
                          );
                    },
                  ),
                  _PeriodButton(
                    label: 'Custom',
                    type: PeriodType.custom,
                    currentType: period.type,
                    onTap: () async {
                      final dates = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (dates != null) {
                        ref.read(statsPeriodProvider.notifier).setCustomPeriod(
                              dates.start,
                              dates.end,
                            );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          // Sélection multi-terrains
          Card(
            child: ExpansionTile(
              title: Text(
                selectedTerrains.isEmpty
                    ? 'Tous les terrains'
                    : '${selectedTerrains.length} terrain(s) sélectionné(s)',
              ),
              children: [
                terrainsAsync.when(
                  data: (terrains) => Column(
                    children: terrains.map((terrain) {
                      final isSelected = selectedTerrains.contains(terrain.id);
                      return CheckboxListTile(
                        title: Text(terrain.nom),
                        value: isSelected,
                        onChanged: (_) {
                          ref
                              .read(selectedTerrainsProvider.notifier)
                              .toggleTerrain(terrain.id);
                        },
                      );
                    }).toList(),
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text('Erreur: $e'),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      TextButton(
                        onPressed: () {
                          terrainsAsync.whenData((terrains) {
                            ref
                                .read(selectedTerrainsProvider.notifier)
                                .selectAll(terrains.map((t) => t.id).toList());
                          });
                        },
                        child: const Text('Tout sélectionner'),
                      ),
                      TextButton(
                        onPressed: () {
                          ref
                              .read(selectedTerrainsProvider.notifier)
                              .clearSelection();
                        },
                        child: const Text('Tout désélectionner'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Charts
          Expanded(
            child: ListView(
              children: [
                // Chart 1: Répartition par types de maintenance
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Répartition par types de maintenance',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 300,
                          child: maintenanceTypesAsync.when(
                            data: (data) {
                              if (data.isEmpty) {
                                return const Center(
                                  child: Text('Aucune donnée'),
                                );
                              }
                              // TODO: Implémenter le chart de répartition
                              return const Center(
                                child: Text('Chart à implémenter'),
                              );
                            },
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (e, _) => Text('Erreur: $e'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Chart 2: Séries de sacs
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Séries de sacs',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 300,
                          child: sacksSeriesAsync.when(
                            data: (data) {
                              if (data.isEmpty) {
                                return const Center(
                                  child: Text('Aucune donnée'),
                                );
                              }
                              return GroupedBarChart(
                                data: data,
                                stacked: _stacked,
                              );
                            },
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (e, _) => Text('Erreur: $e'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodButton extends StatelessWidget {
  final String label;
  final PeriodType type;
  final PeriodType currentType;
  final VoidCallback onTap;

  const _PeriodButton({
    required this.label,
    required this.type,
    required this.currentType,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = type == currentType;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : null,
          ),
        ),
      ),
    );
  }
}
