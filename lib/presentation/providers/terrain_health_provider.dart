import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core_providers.dart';
import 'app_settings_provider.dart';
import 'weather_providers.dart';

class TerrainHealthState {
  final int score;
  final String? warningMessage;

  const TerrainHealthState({required this.score, this.warningMessage});
}

/// Provider qui écoute les changements dans la table maintenances pour déclencher le recalcul
final maintenanceUpdateTriggerProvider = StreamProvider<int>((ref) {
  final db = ref.watch(databaseProvider);
  // On retourne un timestamp pour forcer le rafraîchissement à chaque modification
  return db
      .select(db.maintenances)
      .watch()
      .map((_) => DateTime.now().millisecondsSinceEpoch);
});

final terrainHealthProvider = FutureProvider.family<TerrainHealthState, int>((
  ref,
  terrainId,
) async {
  // Abonnement aux changements de la base de données (maintenances)
  ref.watch(maintenanceUpdateTriggerProvider);

  final db = ref.read(databaseProvider);
  final settingsAsync = ref.watch(appSettingsProvider);
  final location = settingsAsync.valueOrNull?.location;

  int score = 100;
  String? warning;

  // 1. Weather Logic (only if location is set)
  if (location != null) {
    try {
      final weatherService = ref.read(weatherServiceProvider);
      // On récupère la météo actuelle
      final weatherCtx = await weatherService.fetch(
        latitude: location.latitude,
        longitude: location.longitude,
      );

      final precip24h = weatherCtx.precipitationLast24h;
      final temp = weatherCtx.snapshot.temperature;

      // Règle : Blocage Impraticable (Pluie > 5mm)
      if (precip24h > 5.0) {
        return const TerrainHealthState(
          score: 0,
          warningMessage: 'Terrain inondé / impraticable (Pluie > 5mm)',
        );
      }

      // Règle : Malus Météo (Sécheresse)
      // Si temp > 28°C ET precip < 1mm ET pas d'arrosage aujourd'hui
      if (temp > 28.0 && precip24h < 1.0) {
        final lastArrosage = await db.getLastMaintenanceForTerrain(
          terrainId,
          type: 'Arrosage',
        );
        bool arrosageDoneToday = false;

        if (lastArrosage != null) {
          final now = DateTime.now();
          final maintenanceDate = DateTime.fromMillisecondsSinceEpoch(
            lastArrosage.date,
          );

          // Vérification simplifiée : maintenance faite le jour même
          if (maintenanceDate.year == now.year &&
              maintenanceDate.month == now.month &&
              maintenanceDate.day == now.day) {
            arrosageDoneToday = true;
          }
        }

        if (!arrosageDoneToday) {
          score -= 25;
        }
      }
    } catch (e) {
      // En cas d'erreur météo (ou pas de connexion), on ignore le malus météo (neutre)
      // On continue vers le calcul d'inactivité
    }
  }

  // 2. Inactivité Logic
  final lastMaintenance = await db.getLastMaintenanceForTerrain(terrainId);
  if (lastMaintenance != null) {
    final now = DateTime.now();
    final lastDate = DateTime.fromMillisecondsSinceEpoch(lastMaintenance.date);

    // Calcul de la différence en jours pleins
    final diff = now.difference(lastDate).inDays;

    // Règle : Si > 3 jours sans maintenance
    if (diff > 3) {
      final overdueDays = diff - 3;
      score -= (overdueDays * 15);
    }
  }

  // Clamp score 0-100
  if (score < 0) score = 0;
  if (score > 100) score = 100;

  return TerrainHealthState(score: score, warningMessage: warning);
});
