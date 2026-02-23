import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/yearly_comparison_provider.dart';

class SeasonComparisonCard extends ConsumerWidget {
  const SeasonComparisonCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comparisonAsync = ref.watch(yearlyComparisonProvider);

    return comparisonAsync.when(
      data: (state) => _buildCard(context, state),
      loading: () => const SizedBox.shrink(), // Ou un placeholder
      error: (err, stack) => SizedBox(
        height: 100,
        child: Center(child: Text('Erreur: $err')),
      ),
    );
  }

  Widget _buildCard(BuildContext context, YearlyComparisonState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Couleurs
    const mantoColor = Color(0xFFf8b250);
    final sottoColor = isDark ? Colors.brown.shade300 : Colors.brown;
    const siliceColor = Color(0xFF0293ee);

    // Données pour le graphique
    final groups = [
      _makeGroupData(0, state.dataNMinus1.manto, state.dataN.manto, mantoColor),
      _makeGroupData(1, state.dataNMinus1.sottomanto, state.dataN.sottomanto, sottoColor),
      _makeGroupData(2, state.dataNMinus1.silice, state.dataN.silice, siliceColor),
    ];

    // Calcul du max Y pour l'échelle
    double maxY = 0;
    for (var g in groups) {
      for (var rod in g.barRods) {
        if (rod.toY > maxY) maxY = rod.toY;
      }
    }
    maxY = (maxY * 1.2).ceilToDouble(); // +20% de marge
    if (maxY == 0) maxY = 10;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comparaison Saisonnière',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            state.message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                ),
          ),
          const SizedBox(height: 24),
          AspectRatio(
            aspectRatio: 1.5,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Colors.blueGrey.withValues(alpha: 0.8),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final String yearLabel = rodIndex == 0 ? '${state.yearN - 1}' : '${state.yearN}';
                      String material = '';
                      switch (groupIndex) {
                        case 0: material = 'Manto'; break;
                        case 1: material = 'Sottomanto'; break;
                        case 2: material = 'Silice'; break;
                      }
                      return BarTooltipItem(
                        '$material ($yearLabel)\n',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: rod.toY.toInt().toString(),
                            style: const TextStyle(
                              color: Colors.white, // ou une couleur spécifique
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final style = TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        );
                        String text;
                        switch (value.toInt()) {
                          case 0:
                            text = 'Manto';
                            break;
                          case 1:
                            text = 'Sotto';
                            break;
                          case 2:
                            text = 'Silice';
                            break;
                          default:
                            text = '';
                        }
                        return SideTitleWidget(
                          meta: meta,
                          space: 4,
                          child: Text(text, style: style),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: maxY / 5,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 5,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Theme.of(context).dividerColor.withOpacity(0.1),
                    strokeWidth: 1,
                  ),
                ),
                barGroups: groups,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Légende
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(context, Colors.grey, 'Année N-1 (${state.yearN - 1})', isLight: true),
              const SizedBox(width: 24),
              _buildLegendItem(context, isDark ? Colors.grey.shade400 : Colors.grey.shade800, 'Année N (${state.yearN})', isLight: false),
            ],
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, int y1, int y2, Color color) {
    return BarChartGroupData(
      barsSpace: 4,
      x: x,
      barRods: [
        BarChartRodData(
          toY: y1.toDouble(),
          color: color.withValues(alpha: 0.3),
          width: 16,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
        BarChartRodData(
          toY: y2.toDouble(),
          color: color,
          width: 16,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(BuildContext context, Color color, String text, {required bool isLight}) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isLight ? color.withValues(alpha: 0.3) : color,
            borderRadius: BorderRadius.circular(2),
            border: isLight ? Border.all(color: color) : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodySmall?.color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
