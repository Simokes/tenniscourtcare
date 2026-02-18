import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../../utils/date_utils.dart'; // <- inutile ici, à retirer si non utilisé
import 'database_provider.dart';
import 'stats_period_provider.dart';
import 'selected_terrains_provider.dart';
import 'terrain_provider.dart';

/// Provider pour obtenir les IDs des terrains sélectionnés, ou tous si aucun sélectionné.
final _terrainIdsProvider = Provider<Set<int>>((ref) {
  final selectedTerrains = ref.watch(selectedTerrainsProvider);
  if (selectedTerrains.isNotEmpty) {
    return selectedTerrains; // déjà un Set<int>
  }

  // Si aucun terrain sélectionné, on retourne l'ensemble des terrains connus.
  final terrainsAsync = ref.watch(terrainsProvider);
  return terrainsAsync.when(
    data: (terrains) => terrains.map((t) => t.id).toSet(),
    loading: () => <int>{}, // <- Set<int> vide
    error: (_, __) => <int>{}, // <- Set<int> vide
  );
});

/// Provider pour les totaux de sacs avec filtres (mono- ou multi-terrains)
final sacsTotalsProvider =
    StreamProvider.family<
      ({int manto, int sottomanto, int silice}),
      ({int? terrainId, int? start, int? end})
    >((ref, params) {
      final database = ref.watch(databaseProvider);

      // Filtre mono-terrain
      if (params.terrainId != null) {
        return database.watchSacsTotals(
          terrainId: params.terrainId,
          start: params.start,
          end: params.end,
        );
      }

      // Multi-terrains (sélection en cours ou tous)
      final terrainIds = ref.watch(_terrainIdsProvider);
      if (terrainIds.isEmpty) {
        return Stream.value((manto: 0, sottomanto: 0, silice: 0));
      }
      return database.watchSacsTotalsAllTerrains(
        terrainIds: terrainIds,
        start: params.start,
        end: params.end,
      );
    });

/// Totaux mensuels par terrain
final monthlyTotalsByTerrainProvider =
    StreamProvider.family<
      ({int manto, int sottomanto, int silice}),
      (int terrainId, DateTime anyDay)
    >((ref, params) {
      final database = ref.watch(databaseProvider);
      return database.watchMonthlyTotalsByTerrain(
        terrainId: params.$1,
        anyDay: params.$2,
      );
    });

/// Totaux mensuels pour tous les terrains (ou sélection)
final monthlyTotalsAllTerrainsProvider =
    StreamProvider.family<({int manto, int sottomanto, int silice}), DateTime>((
      ref,
      anyDay,
    ) {
      final database = ref.watch(databaseProvider);
      final terrainIds = ref.watch(_terrainIdsProvider);

      if (terrainIds.isEmpty) {
        return Stream.value((manto: 0, sottomanto: 0, silice: 0));
      }

      return database.watchMonthlyTotalsAllTerrains(
        terrainIds: terrainIds,
        anyDay: anyDay,
      );
    });

/// Séries de sacs (jour/semaine/mois) en fonction de la période choisie
final sacksSeriesProvider =
    StreamProvider<List<({int date, int manto, int sottomanto, int silice})>>((
      ref,
    ) {
      final database = ref.watch(databaseProvider);
      final period = ref.watch(statsPeriodProvider);
      final terrainIds = ref.watch(_terrainIdsProvider);

      if (terrainIds.isEmpty) {
        return Stream.value(
          <({int date, int manto, int sottomanto, int silice})>[],
        );
      }

      final bounds = period.bounds;

      switch (period.type) {
        case PeriodType.day:
        case PeriodType.custom:
          return database.watchDailySacsSeriesForTerrains(
            terrainIds: terrainIds,
            start: bounds.start,
            end: bounds.end,
          );

        case PeriodType.week:
          return database
              .watchWeeklySeries(
                terrainIds: terrainIds,
                start: bounds.start,
                end: bounds.end,
              )
              .map((weekly) {
                return weekly
                    .map(
                      (w) => (
                        date: w.weekStart,
                        manto: w.manto,
                        sottomanto: w.sottomanto,
                        silice: w.silice,
                      ),
                    )
                    .toList();
              });

        case PeriodType.month:
          return database
              .watchMonthlySeries(
                terrainIds: terrainIds,
                start: bounds.start,
                end: bounds.end,
              )
              .map((monthly) {
                return monthly
                    .map(
                      (m) => (
                        date: m.monthStart,
                        manto: m.manto,
                        sottomanto: m.sottomanto,
                        silice: m.silice,
                      ),
                    )
                    .toList();
              });
      }
    });

/// Séries de types de maintenance (par jour)
final maintenanceTypesSeriesProvider =
    StreamProvider<List<({int date, String type, int count})>>((ref) {
      final database = ref.watch(databaseProvider);
      final period = ref.watch(statsPeriodProvider);
      final terrainIds = ref.watch(_terrainIdsProvider);

      if (terrainIds.isEmpty) {
        return Stream.value(<({int date, String type, int count})>[]);
      }

      final bounds = period.bounds;

      return database.watchDailyMaintenanceTypeCounts(
        terrainIds: terrainIds,
        start: bounds.start,
        end: bounds.end,
      );
    });
