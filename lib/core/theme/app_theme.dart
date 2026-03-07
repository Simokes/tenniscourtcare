import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import './dashboard_theme_extension.dart';

/// Source unique de vérité pour toutes les couleurs de CourtCare.
///
/// Règle : ne jamais instancier [Color] en dehors de ce fichier.
/// Dans les widgets :
/// - [Theme.of(context).colorScheme] pour les couleurs Material adaptées au thème
/// - [AppColors] pour les constantes statiques (hors-widget ou const)
/// - [Theme.of(context).extension<DashboardColors>()!] pour les couleurs métier
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF003580);
  static const Color primaryDark = Color(0xFF002A5C);
  static const Color primaryLight = Color(0xFF0EA5E9);

  // Semantic Status
  static const Color success = Color(0xFF16A34A);
  static const Color successBg = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerBg = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF0EA5E9);
  static const Color infoBg = Color(0xFFE0F2FE);

  // Terrain types
  static const Color terreBattue = Color(0xFFEA580C);
  static const Color synthetique = Color(0xFF1D4ED8);
  static const Color dur = Color(0xFF475569);

  // Surfaces
  static const Color backgroundLight = Color(0xFFF5F7F8);
  static const Color backgroundDark = Color(0xFF101722);
  static const Color surfaceDark = Color(0xFF0F172A);
}

class AppTheme {
  static const Color _primary = AppColors.primary;
  static const Color _backgroundLight = AppColors.backgroundLight;
  static const Color _backgroundDark = AppColors.backgroundDark;
  static const Color _surfaceDark = AppColors.surfaceDark;

  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primary,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: _backgroundLight,
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
      cardTheme: CardThemeData(
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      extensions: const [DashboardColors.light],
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primary,
        brightness: Brightness.dark,
        surface: _surfaceDark,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: _backgroundDark,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      cardTheme: CardThemeData(
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: _surfaceDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _backgroundDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      extensions: const [DashboardColors.dark],
    );
  }
}
