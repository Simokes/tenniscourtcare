import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/period_report.dart';
import 'database_provider.dart';
import 'stats_period_provider.dart';

final reportProvider = FutureProvider<PeriodReport>((ref) async {
  final db = ref.watch(databaseProvider);
  final period = ref.watch(statsPeriodProvider);

  // Get date range from period
  final bounds = period.bounds;
  final start = DateTime.fromMillisecondsSinceEpoch(bounds.start);
  final end = DateTime.fromMillisecondsSinceEpoch(bounds.end);

  // Fetch maintenances
  final maintenances = await db.getMaintenancesInPeriod(start, end);

  // Fetch terrains to map names
  final terrains = await db.getAllTerrains();
  final terrainMap = {for (var t in terrains) t.id: t.nom};

  // Calculate totals
  final int totalInterventions = maintenances.length;
  int totalManto = 0;
  int totalSottomanto = 0;
  int totalSilice = 0;
  final Map<int, int> terrainCounts = {};

  for (final m in maintenances) {
    totalManto += m.sacsMantoUtilises;
    totalSottomanto += m.sacsSottomantoUtilises;
    totalSilice += m.sacsSiliceUtilises;

    terrainCounts[m.terrainId] = (terrainCounts[m.terrainId] ?? 0) + 1;
  }

  // Find most maintained terrain
  String? mostMaintainedName;
  int mostMaintainedCount = 0;

  if (terrainCounts.isNotEmpty) {
    final entry =
        terrainCounts.entries.reduce((a, b) => a.value > b.value ? a : b);
    mostMaintainedName = terrainMap[entry.key] ?? 'Inconnu';
    mostMaintainedCount = entry.value;
  }

  return PeriodReport(
    start: start,
    end: end,
    totalInterventions: totalInterventions,
    totalSacksManto: totalManto,
    totalSacksSottomanto: totalSottomanto,
    totalSacksSilice: totalSilice,
    mostMaintainedTerrainName: mostMaintainedName,
    mostMaintainedTerrainCount: mostMaintainedCount,
  );
});
