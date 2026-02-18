import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/date_utils.dart';
import 'database_provider.dart';
import 'stats_period_provider.dart';
import 'selected_terrains_provider.dart';
import 'terrain_provider.dart';

/// Provider pour obtenir les IDs des terrains sélectionnés ou tous
final _terrainIdsProvider = Provider<Set<int>>((ref) {
  final selectedTerrains = ref.watch(selectedTerrainsProvider);
  if (selectedTerrains.isNotEmpty) {
    return selectedTerrains;
  }
  // Si aucun terrain sélectionné, on attend la liste complète
  final terrainsAsync = ref.watch(terrainsProvider);
  return terrainsAsync.when(
    data: (terrains) => terrains.map((t) => t.id).toSet(),
    loading: () => {},
    error: (_, __) => {},
  );
});

/// Provider pour les totaux de sacs avec filtres
final sacsTotalsProvider = StreamProvider.family<
    ({int manto, int sottomanto, int silice}),
    ({int? terrainId, int? start, int? end})>((ref, params) {
  final database = ref.watch(databaseProvider);

  if (params.terrainId != null) {
    return database.watchSacsTotals(
      terrainId: params.terrainId,
      start: params.start,
      end: params.end,
    );
  } else {
    final terrainIds = ref.watch(_terrainIdsProvider);
    if (terrainIds.isEmpty) {
      // Retourner un stream vide si aucun terrain
      return Stream.value((manto: 0, sottomanto: 0, silice: 0));
    }
    return database.watchSacsTotalsAllTerrains(
      terrainIds: terrainIds,
      start: params.start,
      end: params.end,
    );
  }
});

/// Provider pour les totaux mensuels par terrain
final monthlyTotalsByTerrainProvider = StreamProvider.family<
    ({int manto, int sottomanto, int silice}),
    (int terrainId, DateTime anyDay)>((ref, params) {
  final database = ref.watch(databaseProvider);
  return database.watchMonthlyTotalsByTerrain(
    terrainId: params.$1,
    anyDay: params.$2,
  );
});

/// Provider pour les totaux mensuels tous terrains
final monthlyTotalsAllTerrainsProvider = StreamProvider.family<
    ({int manto, int sottomanto, int silice}),
    DateTime>((ref, anyDay) {
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

/// Provider pour les séries de sacs (jour/semaine/mois selon la période)
final sacksSeriesProvider = StreamProvider<
    List<({int date, int manto, int sottomanto, int silice})>>((ref) {
  final database = ref.watch(databaseProvider);
  final period = ref.watch(statsPeriodProvider);
  final terrainIds = ref.watch(_terrainIdsProvider);

  if (terrainIds.isEmpty) {
    return Stream.value([]);
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
      return database.watchWeeklySeries(
        terrainIds: terrainIds,
        start: bounds.start,
        end: bounds.end,
      ).map((weekly) {
        return weekly.map((w) => (
              date: w.weekStart,
              manto: w.manto,
              sottomanto: w.sottomanto,
              silice: w.silice,
            )).toList();
      });
    case PeriodType.month:
      return database.watchMonthlySeries(
        terrainIds: terrainIds,
        start: bounds.start,
        end: bounds.end,
      ).map((monthly) {
        return monthly.map((m) => (
              date: m.monthStart,
              manto: m.manto,
              sottomanto: m.sottomanto,
              silice: m.silice,
            )).toList();
      });
  }
});

/// Provider pour les séries de types de maintenance
final maintenanceTypesSeriesProvider = StreamProvider<
    List<({int date, String type, int count})>>((ref) {
  final database = ref.watch(databaseProvider);
  final period = ref.watch(statsPeriodProvider);
  final terrainIds = ref.watch(_terrainIdsProvider);

  if (terrainIds.isEmpty) {
    return Stream.value([]);
  }

  final bounds = period.bounds;

  return database.watchDailyMaintenanceTypeCounts(
    terrainIds: terrainIds,
    start: bounds.start,
    end: bounds.end,
  );
});
