import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/stats_period_provider.dart';
import '../providers/stats_providers.dart';
import '../providers/stats_aggregated_providers.dart';
import '../widgets/stats/stats_period_selector.dart';
import '../widgets/stats/maintenance_distribution_chart.dart';
import '../widgets/stats/sacks_line_chart.dart';
import '../widgets/stats/summary_grid.dart';
import '../widgets/stats/season_comparison_card.dart';
import '../../utils/csv_export.dart';
import '../providers/report_provider.dart';
import '../../infrastructure/services/share_report_service.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(statsPeriodProvider);
    final sacksSeriesAsync = ref.watch(sacksSeriesProvider);
    final distribution = ref.watch(maintenanceTypesDistributionProvider);
    final sacksTotals = ref.watch(sacksTotalsForPeriodProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Premium Gradient logic for AppBar
    final gradientColors = isDark
        ? [const Color(0xFF1A1A1A), const Color(0xFF2C2C2C)]
        : [Colors.blue.shade800, Colors.blue.shade500];

    return Scaffold(
      // backgroundColor: handled by Theme
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            pinned: true,
            floating: true,
            expandedHeight: 120,
            title: const Text(
              'Statistiques',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () async {
                  try {
                    final report = await ref.read(reportProvider.future);
                    await ShareReportService.share(report);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                    }
                  }
                },
                tooltip: 'Partager le bilan',
              ),
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: () async {
                  sacksSeriesAsync.whenData((data) async {
                    await CsvExport.exportSacksSeries(
                      data: data,
                      filename:
                          'stats_export_${DateTime.now().millisecondsSinceEpoch}',
                      context: context,
                    );
                  });
                },
                tooltip: 'Exporter CSV',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),

          // Filters
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: StatsPeriodSelector(
                currentType: period.type,
                onPeriodChanged: (type) {
                  ref.read(statsPeriodProvider.notifier).setPeriod(type);
                },
                onCustomPeriod: () async {
                  final dates = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: isDark
                              ? ColorScheme.dark(
                                  primary: Colors.blue.shade300,
                                  onPrimary: Colors.black,
                                )
                              : ColorScheme.light(
                                  primary: Colors.blue.shade800,
                                ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (dates != null) {
                    ref
                        .read(statsPeriodProvider.notifier)
                        .setCustomPeriod(dates.start, dates.end);
                  }
                },
              ),
            ),
          ),

          // Global Consumption Summary
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Consommation Totale',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SummaryGrid(
                  manto: sacksTotals.manto,
                  sottomanto: sacksTotals.sottomanto,
                  silice: sacksTotals.silice,
                ),
              ],
            ),
          ),

          // Yearly Comparison
          const SliverToBoxAdapter(child: SeasonComparisonCard()),

          // Distribution Chart
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.3)
                        : Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Répartition des Interventions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  MaintenanceDistributionChart(distribution: distribution),
                ],
              ),
            ),
          ),

          // Evolution Chart
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.3)
                        : Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Évolution de la consommation',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  sacksSeriesAsync.when(
                    data: (data) => SacksLineChart(data: data),
                    loading: () => const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, s) => SizedBox(
                      height: 200,
                      child: Center(child: Text('Erreur: $e')),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}
