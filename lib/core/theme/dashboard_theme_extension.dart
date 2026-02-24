import 'package:flutter/material.dart';

class DashboardColors extends ThemeExtension<DashboardColors> {
  final Color maintenanceColor;
  final Color stockColor;
  final Color weatherColor;
  final Color statsColor;

  const DashboardColors({
    required this.maintenanceColor,
    required this.stockColor,
    required this.weatherColor,
    required this.statsColor,
  });

  @override
  DashboardColors copyWith({
    Color? maintenanceColor,
    Color? stockColor,
    Color? weatherColor,
    Color? statsColor,
  }) {
    return DashboardColors(
      maintenanceColor: maintenanceColor ?? this.maintenanceColor,
      stockColor: stockColor ?? this.stockColor,
      weatherColor: weatherColor ?? this.weatherColor,
      statsColor: statsColor ?? this.statsColor,
    );
  }

  @override
  DashboardColors lerp(ThemeExtension<DashboardColors>? other, double t) {
    if (other is! DashboardColors) {
      return this;
    }
    return DashboardColors(
      maintenanceColor: Color.lerp(maintenanceColor, other.maintenanceColor, t)!,
      stockColor: Color.lerp(stockColor, other.stockColor, t)!,
      weatherColor: Color.lerp(weatherColor, other.weatherColor, t)!,
      statsColor: Color.lerp(statsColor, other.statsColor, t)!,
    );
  }

  static const light = DashboardColors(
    maintenanceColor: Color(0xFF1976D2), // blue.shade700
    stockColor: Color(0xFFEF6C00), // orange.shade800
    weatherColor: Color(0xFF00897B), // teal.shade600
    statsColor: Color(0xFF8E24AA), // purple.shade600
  );

  static const dark = DashboardColors(
    maintenanceColor: Color(0xFF64B5F6), // blue.shade300
    stockColor: Color(0xFFFFB74D), // orange.shade300
    weatherColor: Color(0xFF4DB6AC), // teal.shade300
    statsColor: Color(0xFFBA68C8), // purple.shade300
  );
}
