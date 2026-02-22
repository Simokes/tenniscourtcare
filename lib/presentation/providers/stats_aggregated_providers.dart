import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'stats_providers.dart';

/// Aggregates the daily maintenance type series into a total count per type for the selected period.
final maintenanceTypesDistributionProvider = Provider<Map<String, int>>((ref) {
  final seriesAsync = ref.watch(maintenanceTypesSeriesProvider);

  return seriesAsync.when(
    data: (series) {
      final Map<String, int> distribution = {};
      for (final item in series) {
        distribution.update(item.type, (value) => value + item.count, ifAbsent: () => item.count);
      }
      return distribution;
    },
    loading: () => {},
    error: (_, __) => {},
  );
});

/// Aggregates the sacks series into global totals for the selected period.
final sacksTotalsForPeriodProvider = Provider<({int manto, int sottomanto, int silice})>((ref) {
  final seriesAsync = ref.watch(sacksSeriesProvider);

  return seriesAsync.when(
    data: (series) {
      int manto = 0;
      int sottomanto = 0;
      int silice = 0;
      for (final item in series) {
        manto += item.manto;
        sottomanto += item.sottomanto;
        silice += item.silice;
      }
      return (manto: manto, sottomanto: sottomanto, silice: silice);
    },
    loading: () => (manto: 0, sottomanto: 0, silice: 0),
    error: (_, __) => (manto: 0, sottomanto: 0, silice: 0),
  );
});
