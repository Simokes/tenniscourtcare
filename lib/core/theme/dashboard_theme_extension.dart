import 'package:flutter/material.dart';

/// Extension de thème pour les couleurs métier de CourtCare.
///
/// Accès dans les widgets :
/// ```dart
/// final dc = Theme.of(context).extension<DashboardColors>()!;
/// ```
class DashboardColors extends ThemeExtension<DashboardColors> {
  // Couleurs dashboard (existantes — inchangées)
  final Color maintenanceColor;
  final Color stockColor;
  final Color weatherColor;
  final Color statsColor;

  // Couleurs sémantiques (nouvelles)
  final Color successColor;
  final Color successBgColor;
  final Color warningColor;
  final Color warningBgColor;
  final Color dangerColor;
  final Color dangerBgColor;

  // Couleurs types de terrain (nouvelles)
  final Color terreBattueColor;
  final Color synthetiqueColor;
  final Color durColor;

  const DashboardColors({
    required this.maintenanceColor,
    required this.stockColor,
    required this.weatherColor,
    required this.statsColor,
    required this.successColor,
    required this.successBgColor,
    required this.warningColor,
    required this.warningBgColor,
    required this.dangerColor,
    required this.dangerBgColor,
    required this.terreBattueColor,
    required this.synthetiqueColor,
    required this.durColor,
  });

  @override
  DashboardColors copyWith({
    Color? maintenanceColor,
    Color? stockColor,
    Color? weatherColor,
    Color? statsColor,
    Color? successColor,
    Color? successBgColor,
    Color? warningColor,
    Color? warningBgColor,
    Color? dangerColor,
    Color? dangerBgColor,
    Color? terreBattueColor,
    Color? synthetiqueColor,
    Color? durColor,
  }) {
    return DashboardColors(
      maintenanceColor: maintenanceColor ?? this.maintenanceColor,
      stockColor:       stockColor       ?? this.stockColor,
      weatherColor:     weatherColor     ?? this.weatherColor,
      statsColor:       statsColor       ?? this.statsColor,
      successColor:     successColor     ?? this.successColor,
      successBgColor:   successBgColor   ?? this.successBgColor,
      warningColor:     warningColor     ?? this.warningColor,
      warningBgColor:   warningBgColor   ?? this.warningBgColor,
      dangerColor:      dangerColor      ?? this.dangerColor,
      dangerBgColor:    dangerBgColor    ?? this.dangerBgColor,
      terreBattueColor: terreBattueColor ?? this.terreBattueColor,
      synthetiqueColor: synthetiqueColor ?? this.synthetiqueColor,
      durColor:         durColor         ?? this.durColor,
    );
  }

  @override
  DashboardColors lerp(ThemeExtension<DashboardColors>? other, double t) {
    if (other is! DashboardColors) return this;
    return DashboardColors(
      maintenanceColor: Color.lerp(maintenanceColor, other.maintenanceColor, t)!,
      stockColor:       Color.lerp(stockColor,       other.stockColor,       t)!,
      weatherColor:     Color.lerp(weatherColor,     other.weatherColor,     t)!,
      statsColor:       Color.lerp(statsColor,       other.statsColor,       t)!,
      successColor:     Color.lerp(successColor,     other.successColor,     t)!,
      successBgColor:   Color.lerp(successBgColor,   other.successBgColor,   t)!,
      warningColor:     Color.lerp(warningColor,     other.warningColor,     t)!,
      warningBgColor:   Color.lerp(warningBgColor,   other.warningBgColor,   t)!,
      dangerColor:      Color.lerp(dangerColor,      other.dangerColor,      t)!,
      dangerBgColor:    Color.lerp(dangerBgColor,    other.dangerBgColor,    t)!,
      terreBattueColor: Color.lerp(terreBattueColor, other.terreBattueColor, t)!,
      synthetiqueColor: Color.lerp(synthetiqueColor, other.synthetiqueColor, t)!,
      durColor:         Color.lerp(durColor,         other.durColor,         t)!,
    );
  }

  static const light = DashboardColors(
    // Dashboard (inchangés)
    maintenanceColor: Color(0xFF1976D2),
    stockColor:       Color(0xFFEF6C00),
    weatherColor:     Color(0xFF00897B),
    statsColor:       Color(0xFF8E24AA),
    // Semantic (light)
    successColor:     Color(0xFF16A34A),
    successBgColor:   Color(0xFFDCFCE7),
    warningColor:     Color(0xFFF59E0B),
    warningBgColor:   Color(0xFFFEF3C7),
    dangerColor:      Color(0xFFDC2626),
    dangerBgColor:    Color(0xFFFEE2E2),
    // Terrains (light)
    terreBattueColor: Color(0xFFEA580C),
    synthetiqueColor: Color(0xFF1D4ED8),
    durColor:         Color(0xFF475569),
  );

  static const dark = DashboardColors(
    // Dashboard (inchangés)
    maintenanceColor: Color(0xFF64B5F6),
    stockColor:       Color(0xFFFFB74D),
    weatherColor:     Color(0xFF4DB6AC),
    statsColor:       Color(0xFFBA68C8),
    // Semantic (dark — versions plus claires pour fond sombre)
    successColor:     Color(0xFF4ADE80),
    successBgColor:   Color(0xFF14532D),
    warningColor:     Color(0xFFFBBF24),
    warningBgColor:   Color(0xFF451A03),
    dangerColor:      Color(0xFFF87171),
    dangerBgColor:    Color(0xFF450A0A),
    // Terrains (dark — versions éclaircies)
    terreBattueColor: Color(0xFFFB923C),
    synthetiqueColor: Color(0xFF60A5FA),
    durColor:         Color(0xFF94A3B8),
  );
}
