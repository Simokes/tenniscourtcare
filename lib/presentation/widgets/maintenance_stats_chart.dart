import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class MaintenanceStatsChart extends StatelessWidget {
  final int manto;
  final int sottomanto;
  final int silice;
  final String title;

  const MaintenanceStatsChart({
    super.key,
    required this.manto,
    required this.sottomanto,
    required this.silice,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final total = manto + sottomanto + silice;

    // Determine if we have data to show
    final hasData = total > 0;

    return Column(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 150, // Fixed height for the chart area
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: hasData
                      ? [
                          if (manto > 0)
                            PieChartSectionData(
                              color: Colors.orange,
                              value: manto.toDouble(),
                              title: '$manto',
                              radius: 20,
                              titleStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          if (sottomanto > 0)
                            PieChartSectionData(
                              color: Colors.brown,
                              value: sottomanto.toDouble(),
                              title: '$sottomanto',
                              radius: 20,
                              titleStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          if (silice > 0)
                            PieChartSectionData(
                              color: Colors.blue,
                              value: silice.toDouble(),
                              title: '$silice',
                              radius: 20,
                              titleStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                        ]
                      : [
                          PieChartSectionData(
                            color: Colors.grey.shade300,
                            value: 1,
                            title: '',
                            radius: 15,
                          ),
                        ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$total',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Text(
                    'Sacs',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Legend
        if (hasData)
          Wrap(
            spacing: 12,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: [
              if (manto > 0) _LegendItem(color: Colors.orange, text: 'Manto'),
              if (sottomanto > 0) _LegendItem(color: Colors.brown, text: 'Sotto'),
              if (silice > 0) _LegendItem(color: Colors.blue, text: 'Silice'),
            ],
          )
        else
          const Text(
            'Aucune donnée',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const _LegendItem({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
