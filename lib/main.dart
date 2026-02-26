import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/app_settings_provider.dart';
import 'providers/queue_providers.dart';
import 'presentation/widgets/queue_status_widget.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Initialisation des locales pour intl (fr_FR)
      await initializeDateFormatting('fr_FR', null);
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      runApp(const ProviderScope(child: CourtCareApp()));
    },
    (error, stack) {
      // Gestionnaire d'erreurs globales
      // Dans le futur, on pourrait intégrer Sentry ou Firebase Crashlytics ici.
      if (kDebugMode) {
        debugPrint('ERREUR NON GÉRÉE: $error');
        debugPrint('STACKTRACE: $stack');
      } else {
        // En production, on pourrait logger dans un fichier ou envoyer vers un service
        // Pour l'instant, on évite le crash silencieux complet en loggant a minima si possible
        debugPrint('Erreur critique capturée: $error');
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

    // Initialize background retry check
    ref.watch(scheduleRetryCheckProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Court Care',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        return Column(
          children: [
            const QueueStatusBanner(),
            Expanded(child: child ?? const SizedBox()),
          ],
        );
      },
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
