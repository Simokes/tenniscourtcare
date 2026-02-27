import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dashboard_theme_extension.dart';

class AppTheme {
  static const Color _primary = Color(0xFF094CAA); // Primary Blue from design
  static const Color _backgroundLight = Color(0xFFF5F7F8); // bg-background-light
  static const Color _backgroundDark = Color(0xFF101722); // bg-background-dark
  static const Color _surfaceDark = Color(0xFF0F172A); // bg-slate-900

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
