import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/refill_recommendation.dart';
import 'app_settings_provider.dart';
import 'database_provider.dart';
import '../../features/weather/infrastructure/weather_service.dart';
import 'weather_providers.dart';

final refillRecommendationProvider =
    FutureProvider.family<RefillRecommendation, int>((ref, terrainId) async {
      // 1. Localisation
      final clubLocation = ref.watch(appSettingsProvider).value?.location;
      if (clubLocation == null) {
        // Impossible de calculer sans météo fiable -> fallback
        return const RefillRecommendation(
          recommendedBags: 2,
          reason: 'Localisation du club non définie (Météo indisponible).',
          isCritical: false,
        );
      }

      // 2. Météo
      final weatherService = ref.read(weatherServiceProvider);
      WeatherContext weatherContext;
      try {
        weatherContext = await weatherService.fetch(
          latitude: clubLocation.latitude,
          longitude: clubLocation.longitude,
        );
      } catch (e) {
        // Fallback si erreur météo
        return const RefillRecommendation(
          recommendedBags: 2,
          reason: 'Erreur récupération météo. Valeur par défaut appliquée.',
          isCritical: false,
        );
      }

      // 3. Historique
      final db = ref.read(databaseProvider);
      final lastRecharge = await db.getLastMaintenanceForTerrain(
        terrainId,
        type: 'Recharge',
      );

      // 4. Algorithme
      int bags = 2; // Base
      final List<String> reasons = ['Base: 2 sacs'];
      bool isCritical = false;

      // Règle météo 1 : Terre sèche
      if (weatherContext.snapshot.temperature > 25 &&
          weatherContext.precipitationLast24h < 0.5) {
        bags += 2;
        reasons.add('Météo chaude et sèche (>25°C, <0.5mm) : +2 sacs');
        isCritical =
            true; // On peut considérer que c'est critique de bien recharger quand il fait très sec
      }

      // Règle météo 2 : Terrain humide
      if (weatherContext.precipitationLast24h > 5.0) {
        bags -= 1;
        reasons.add('Pluie récente (>5mm) : -1 sac');
      }

      // Règle historique
      if (lastRecharge != null) {
        final lastDate = DateTime.fromMillisecondsSinceEpoch(lastRecharge.date);
        final diffDays = DateTime.now().difference(lastDate).inDays;

        if (diffDays > 10) {
          bags += 1;
          reasons.add('Dernière recharge il y a ${diffDays}j (>10j) : +1 sac');
          isCritical = true;
        }
      } else {
        // Pas d'historique
        bags += 3;
        reasons.add('Aucune recharge précédente : +3 sacs (Remise à neuf)');
        isCritical = true;
      }

      // Sécurité (pas de sacs négatifs)
      if (bags < 0) bags = 0;

      return RefillRecommendation(
        recommendedBags: bags,
        reason: reasons.join('\n'),
        isCritical: isCritical,
      );
    });
