// lib/presentation/providers/shared_prefs_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fournit l'instance SharedPreferences, lazy et sûre.
/// Grâce à WidgetsFlutterBinding.ensureInitialized() dans main(),
/// ce FutureProvider ne posera pas de problème de canal.
final sharedPrefsProvider = FutureProvider<SharedPreferences>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs;
});