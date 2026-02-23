import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/router/app_router.dart';
import 'presentation/providers/app_settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation des locales pour intl (fr_FR)
  await initializeDateFormatting('fr_FR', null);

  runApp(
    const ProviderScope(
      child: CourtCareApp(),
    ),
  );
}

class CourtCareApp extends ConsumerWidget {
  const CourtCareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final settingsAsync = ref.watch(appSettingsProvider);
    final themeMode = settingsAsync.valueOrNull?.themeMode ?? ThemeMode.system;

    // Light Theme
    final lightTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2E7D32), // Premium Green
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.grey.shade100,
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
      /*
      cardTheme: CardTheme(
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: Colors.white,
      ),
      */
    );

    // Dark Theme
    final darkTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF81C784), // Desaturated Green for Dark Mode
        brightness: Brightness.dark,
        surface: const Color(0xFF1E1E1E),
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF121212), // Deep Grey/Black
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      /*
      cardTheme: CardTheme(
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: const Color(0xFF1E1E1E),
      ),
      */
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF121212),
        surfaceTintColor: Colors.transparent,
      ),
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Court Care',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('en', 'US'), // Optional fallback
      ],
      locale: const Locale('fr', 'FR'), // Force French locale
    );
  }
}
