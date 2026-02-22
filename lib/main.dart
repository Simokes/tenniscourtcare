import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/router/app_router.dart';



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation des locales pour intl (fr_FR)
  await initializeDateFormatting('fr_FR', null);

  // Si tu as d'autres initialisations async (ex: SharedPreferences.getInstance(),
  // Firebase.initializeApp(), etc.), fais-les ici AVANT runApp().

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

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Court Care',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32), // Premium Green
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
        cardTheme: CardThemeData( // 👈 Le 'const' a été retiré
        surfaceTintColor: Colors.transparent,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      routerConfig: router,
    );
  }
}
