import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import './core/router/app_router.dart';
import './core/theme/app_theme.dart';
import './features/settings/providers/app_settings_provider.dart';
import './core/providers/core_providers.dart'; // ✅ IMPORT
import 'package:firebase_core/firebase_core.dart';
import './firebase_options.dart';
import 'package:tenniscourtcare/data/database/app_database.dart';

Future<void> main() async {
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Initialisation des locales
      await initializeDateFormatting('fr_FR', null);

      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // ✅ Initialize Database
      final db = AppDatabase();

      runApp(
        ProviderScope(
          overrides: [
            // ✅ Override providers with actual instances
            databaseProvider.overrideWithValue(db),
          ],
          child: const CourtCareApp(),
        ),
      );
    },
    (error, stack) {
      if (kDebugMode) {
        debugPrint('❌ ERREUR NON GÉRÉE: $error');
        debugPrint('📍 STACKTRACE: $stack');
      } else {
        debugPrint('⚠️ Erreur critique capturée: $error');
      }
    },
  );
}

class CourtCareApp extends ConsumerWidget {
  const CourtCareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final settingsAsync = ref.watch(appSettingsProvider);
    final themeMode = settingsAsync.valueOrNull?.themeMode ?? ThemeMode.system;

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Court Care',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        return child ?? const SizedBox();
      },
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr', 'FR'), Locale('en', 'US')],
      locale: const Locale('fr', 'FR'),
    );
  }
}
