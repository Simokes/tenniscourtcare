import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'presentation/screens/home_screen.dart';


Future<void> main() async {
  // ✅ S'assure que les canaux plateforme (plugins) sont prêts
  WidgetsFlutterBinding.ensureInitialized();

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


    return MaterialApp(
      title: 'Court Care',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
