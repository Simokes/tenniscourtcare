import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/providers/seed_provider.dart';

Future<void> main() async {
  // ✅ S'assure que les canaux plateforme (plugins) sont prêts
  WidgetsFlutterBinding.ensureInitialized();

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
    // Initialiser les données de seed en mode debug (si ce provider déclenche des I/O,
    // c'est désormais sûr puisque le binding est initialisé).
    ref.watch(seedDataProvider);

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
