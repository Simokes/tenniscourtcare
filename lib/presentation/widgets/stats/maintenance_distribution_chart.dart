import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class MaintenanceDistributionChart extends StatefulWidget {
  final Map<String, int> distribution;

  const MaintenanceDistributionChart({
    super.key,
    required this.distribution,
  });

  @override
  State<MaintenanceDistributionChart> createState() => _MaintenanceDistributionChartState();
}

class _MaintenanceDistributionChartState extends State<MaintenanceDistributionChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.distribution.isEmpty) {
      return const Center(child: Text('Aucune donnée'));
    }

    final total = widget.distribution.values.fold(0, (sum, v) => sum + v);
    final sortedKeys = widget.distribution.keys.toList()
      ..sort((a, b) => widget.distribution[b]!.compareTo(widget.distribution[a]!));

    return AspectRatio(
      aspectRatio: 1.3,
      child: Row(
        children: [
          const SizedBox(height: 18),
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          touchedIndex = -1;
                          return;
                        }
                        touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 0,
                  centerSpaceRadius: 40,
                  sections: showingSections(sortedKeys, total),
                ),
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: sortedKeys.asMap().entries.map((entry) {
              final index = entry.key;
              final key = entry.value;
              final count = widget.distribution[key]!;
              final color = _getColor(index);
              final isTouched = index == touchedIndex;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: isTouched ? 16 : 12,
                      height: isTouched ? 16 : 12,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$key (${((count / total) * 100).toStringAsFixed(0)}%)',
                      style: TextStyle(
                        fontSize: isTouched ? 14 : 12,
                        fontWeight: isTouched ? FontWeight.bold : FontWeight.normal,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(width: 28),
        ],
      ),
    );
  }

  List<PieChartSectionData> showingSections(List<String> sortedKeys, int total) {
    return List.generate(sortedKeys.length, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 20.0 : 14.0;
      final radius = isTouched ? 60.0 : 50.0;
      final key = sortedKeys[i];
      final value = widget.distribution[key]!;
      final color = _getColor(i);

      return PieChartSectionData(
        color: color,
        value: value.toDouble(),
        title: '${((value / total) * 100).toStringAsFixed(0)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [Shadow(color: Colors.black26, blurRadius: 2)],
        ),
      );
    });
  }

  Color _getColor(int index) {
    const colors = [
      Color(0xFF0293ee),
      Color(0xFFf8b250),
      Color(0xFF845bef),
      Color(0xFF13d38e),
      Colors.redAccent,
      Colors.cyan,
      Colors.brown,
    ];
    return colors[index % colors.length];
  }
}
