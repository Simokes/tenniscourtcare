import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SacksLineChart extends StatefulWidget {
  final List<({int date, int manto, int sottomanto, int silice})> data;

  const SacksLineChart({super.key, required this.data});

  @override
  State<SacksLineChart> createState() => _SacksLineChartState();
}

class _SacksLineChartState extends State<SacksLineChart> {
  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return const Center(child: Text('Aucune donnée'));
    }

    final data = widget.data;
    double maxY = 0;
    for (final item in data) {
      if (item.manto > maxY) maxY = item.manto.toDouble();
      if (item.sottomanto > maxY) maxY = item.sottomanto.toDouble();
      if (item.silice > maxY) maxY = item.silice.toDouble();
    }
    // Add some padding to maxY
    maxY = (maxY * 1.2).ceilToDouble();
    if (maxY == 0) maxY = 5;

    return AspectRatio(
      aspectRatio: 1.5,
      child: Padding(
        padding: const EdgeInsets.only(right: 18, left: 12, top: 24, bottom: 12),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: maxY / 5,
              verticalInterval: 1,
              getDrawingHorizontalLine: (value) {
                return const FlLine(
                  color: Color(0xffe7e8ec),
                  strokeWidth: 1,
                );
              },
              getDrawingVerticalLine: (value) {
                return const FlLine(
                  color: Color(0xffe7e8ec),
                  strokeWidth: 1,
                );
              },
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
                  reservedSize: 30,
                  interval: (data.length / 5).ceilToDouble(), // Show fewer labels
                  getTitlesWidget: bottomTitleWidgets,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: maxY / 5,
                  getTitlesWidget: leftTitleWidgets,
                  reservedSize: 42,
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: const Color(0xff37434d)),
            ),
            minX: 0,
            maxX: (data.length - 1).toDouble(),
            minY: 0,
            maxY: maxY,
            lineBarsData: [
              // Manto
              LineChartBarData(
                spots: data.asMap().entries.map((e) {
                  return FlSpot(e.key.toDouble(), e.value.manto.toDouble());
                }).toList(),
                isCurved: true,
                color: Colors.orange,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.orange.withValues(alpha: 0.1),
                ),
              ),
              // Sottomanto
              LineChartBarData(
                spots: data.asMap().entries.map((e) {
                  return FlSpot(e.key.toDouble(), e.value.sottomanto.toDouble());
                }).toList(),
                isCurved: true,
                color: Colors.brown,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.brown.withValues(alpha: 0.1),
                ),
              ),
              // Silice
              LineChartBarData(
                spots: data.asMap().entries.map((e) {
                  return FlSpot(e.key.toDouble(), e.value.silice.toDouble());
                }).toList(),
                isCurved: true,
                color: Colors.blue,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.blue.withValues(alpha: 0.1),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (touchedSpot) => Colors.blueGrey.withValues(alpha: 0.8),
                getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                  return touchedBarSpots.map((barSpot) {
                    final flSpot = barSpot;
                    // Find name based on barIndex (0: Manto, 1: Sotto, 2: Silice)
                    String label = '';
                    Color color = Colors.white;
                    if (barSpot.barIndex == 0) {
                      label = 'Manto';
                      color = Colors.orange.shade200;
                    } else if (barSpot.barIndex == 1) {
                      label = 'Sotto';
                      color = Colors.brown.shade200;
                    } else {
                      label = 'Silice';
                      color = Colors.blue.shade200;
                    }

                    return LineTooltipItem(
                      '$label: ${flSpot.y.toInt()}',
                      TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 10);
    if (value.toInt() >= 0 && value.toInt() < widget.data.length) {
      final dateMs = widget.data[value.toInt()].date;
      final date = DateTime.fromMillisecondsSinceEpoch(dateMs);
      // Format simpler: dd/MM
      final text = DateFormat('dd/MM').format(date);

      return SideTitleWidget(
        meta: meta,
        child: Text(text, style: style),
      );
    }
    return Container();
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.grey);
    return Text(value.toInt().toString(), style: style, textAlign: TextAlign.left);
  }
}
