import 'package:flutter/material.dart';
import 'dart:math' as math;

class GroupedBarChart extends StatelessWidget {
  final List<({int date, int manto, int sottomanto, int silice})> data;
  final bool stacked;

  const GroupedBarChart({super.key, required this.data, this.stacked = false});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('Aucune donnée'));
    }

    return CustomPaint(
      painter: _GroupedBarChartPainter(data: data, stacked: stacked),
      child: const SizedBox.expand(),
    );
  }
}

class _GroupedBarChartPainter extends CustomPainter {
  final List<({int date, int manto, int sottomanto, int silice})> data;
  final bool stacked;

  _GroupedBarChartPainter({required this.data, required this.stacked});

  static const double _padding = 40.0;
  static const double _barGroupSpacing = 20.0;
  static const double _barWidth = 20.0;
  static const double _barSpacing = 8.0;

  static const Color _mantoColor = Color(0xFF4CAF50);
  static const Color _sottomantoColor = Color(0xFF2196F3);
  static const Color _siliceColor = Color(0xFFFF9800);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final chartWidth = size.width - 2 * _padding;
    final chartHeight = size.height - 2 * _padding;

    // Calculer les valeurs max pour l'échelle
    final maxValue =
        (stacked
                ? data
                      .map((d) => d.manto + d.sottomanto + d.silice)
                      .reduce(math.max)
                : [
                    data.map((d) => d.manto).reduce(math.max),
                    data.map((d) => d.sottomanto).reduce(math.max),
                    data.map((d) => d.silice).reduce(math.max),
                  ].reduce(math.max))
            .toDouble();

    final scaleY = chartHeight / (maxValue * 1.1); // 10% de marge en haut

    // Calculer l'espacement entre les groupes de barres
    final barGroupWidth = stacked
        ? _barWidth
        : (_barWidth * 3 + _barSpacing * 2); // 3 barres + 2 espacements

    // Dessiner les axes
    _drawAxes(canvas, size, chartWidth, chartHeight);

    // Dessiner la grille
    _drawGrid(canvas, size, chartWidth, chartHeight, maxValue);

    // Dessiner les barres
    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final x =
          _padding +
          (i * (barGroupWidth + _barGroupSpacing)) +
          (barGroupWidth / 2);

      if (stacked) {
        // Barres empilées
        double yOffset = 0;
        if (item.manto > 0) {
          final height = item.manto * scaleY;
          _drawBar(
            canvas,
            x - _barWidth / 2,
            _padding + chartHeight - yOffset - height,
            _barWidth,
            height,
            _mantoColor,
          );
          yOffset += height;
        }
        if (item.sottomanto > 0) {
          final height = item.sottomanto * scaleY;
          _drawBar(
            canvas,
            x - _barWidth / 2,
            _padding + chartHeight - yOffset - height,
            _barWidth,
            height,
            _sottomantoColor,
          );
          yOffset += height;
        }
        if (item.silice > 0) {
          final height = item.silice * scaleY;
          _drawBar(
            canvas,
            x - _barWidth / 2,
            _padding + chartHeight - yOffset - height,
            _barWidth,
            height,
            _siliceColor,
          );
        }
      } else {
        // Barres groupées
        final barStartX = x - (_barWidth * 1.5 + _barSpacing);
        _drawBar(
          canvas,
          barStartX,
          _padding + chartHeight - item.manto * scaleY,
          _barWidth,
          item.manto * scaleY,
          _mantoColor,
        );
        _drawBar(
          canvas,
          barStartX + _barWidth + _barSpacing,
          _padding + chartHeight - item.sottomanto * scaleY,
          _barWidth,
          item.sottomanto * scaleY,
          _sottomantoColor,
        );
        _drawBar(
          canvas,
          barStartX + (_barWidth + _barSpacing) * 2,
          _padding + chartHeight - item.silice * scaleY,
          _barWidth,
          item.silice * scaleY,
          _siliceColor,
        );
      }

      // Label de date
      final date = DateTime.fromMillisecondsSinceEpoch(item.date);
      final dateLabel = '${date.day}/${date.month}';
      final textPainter = TextPainter(
        text: TextSpan(
          text: dateLabel,
          style: const TextStyle(fontSize: 10, color: Colors.black87),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, _padding + chartHeight + 5),
      );
    }

    // Légende
    _drawLegend(canvas, size);
  }

  void _drawAxes(
    Canvas canvas,
    Size size,
    double chartWidth,
    double chartHeight,
  ) {
    final paint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 2;

    // Axe Y (vertical, gauche)
    canvas.drawLine(
      Offset(_padding, _padding),
      Offset(_padding, _padding + chartHeight),
      paint,
    );

    // Axe X (horizontal, bas)
    canvas.drawLine(
      Offset(_padding, _padding + chartHeight),
      Offset(_padding + chartWidth, _padding + chartHeight),
      paint,
    );
  }

  void _drawGrid(
    Canvas canvas,
    Size size,
    double chartWidth,
    double chartHeight,
    double maxValue,
  ) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1;

    // 5 lignes de grille horizontales
    for (int i = 0; i <= 5; i++) {
      final y = _padding + (chartHeight / 5) * i;
      canvas.drawLine(
        Offset(_padding, y),
        Offset(_padding + chartWidth, y),
        paint,
      );

      // Labels de valeurs sur l'axe Y
      final value = maxValue * (1 - i / 5);
      final textPainter = TextPainter(
        text: TextSpan(
          text: value.toInt().toString(),
          style: const TextStyle(fontSize: 10, color: Colors.black87),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(_padding - textPainter.width - 5, y - textPainter.height / 2),
      );
    }
  }

  void _drawBar(
    Canvas canvas,
    double x,
    double y,
    double width,
    double height,
    Color color,
  ) {
    final paint = Paint()..color = color;
    final rect = Rect.fromLTWH(x, y, width, height);
    canvas.drawRect(rect, paint);

    // Bordure
    final borderPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(rect, borderPaint);
  }

  void _drawLegend(Canvas canvas, Size size) {
    final legendItems = [
      ('Manto', _mantoColor),
      ('Sottomanto', _sottomantoColor),
      ('Silice', _siliceColor),
    ];

    double x = size.width - 100;
    double y = 20;

    for (final (label, color) in legendItems) {
      // Carré de couleur
      final paint = Paint()..color = color;
      canvas.drawRect(Rect.fromLTWH(x, y, 12, 12), paint);

      // Label
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x + 16, y));

      y += 20;
    }
  }

  @override
  bool shouldRepaint(_GroupedBarChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.stacked != stacked;
  }
}
