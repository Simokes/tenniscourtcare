import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../../terrain/providers/terrain_provider.dart';
import '../../../domain/entities/app_event.dart';
import '../../../domain/entities/maintenance.dart';
import '../../calendar/providers/event_provider.dart';
import '../../maintenance/providers/maintenance_provider.dart';
import '../models/timeline_item.dart';

/// Provider for the count of maintenances performed today
final todayMaintenanceCountProvider = StreamProvider<int>((ref) {
  final database = ref.watch(databaseProvider);
  final now = DateTime.now();
  final startOfDay = DateTime(
    now.year,
    now.month,
    now.day,
  ).millisecondsSinceEpoch;
  final endOfDay = DateTime(
    now.year,
    now.month,
    now.day,
    23,
    59,
    59,
  ).millisecondsSinceEpoch;

  final terrains = ref.watch(terrainsProvider).valueOrNull ?? [];
  final ids = terrains.map((t) => t.id).toSet();
  if (ids.isEmpty) return Stream.value(0);

  return database
      .watchDailyMaintenanceTypeCounts(
        terrainIds: ids,
        start: startOfDay,
        end: endOfDay,
      )
      .map((list) => list.fold(0, (sum, item) => sum + item.count));
});

/// Stats terrains opérationnels : ({int playable, int total}).
/// Utilisé par StatsCarousel pour afficher "X/Y opérationnels".
final operationalTerrainsStatsProvider =
    Provider<({int playable, int total})>((ref) {
      final total = ref.watch(terrainsProvider).valueOrNull?.length ?? 0;
      final playable = ref.watch(playableTerrainCountProvider);
      return (playable: playable, total: total);
    });

// Events happening RIGHT NOW (today, within current time)
final currentEventsProvider = Provider<List<AppEvent>>((ref) {
  final events = ref.watch(eventsProvider).valueOrNull ?? [];
  final now = DateTime.now();
  return events.where((e) =>
    e.startTime.isBefore(now) && e.endTime.isAfter(now)
  ).toList();
});

// Upcoming events today (not yet started)
final todayUpcomingEventsProvider = Provider<List<AppEvent>>((ref) {
  final events = ref.watch(eventsProvider).valueOrNull ?? [];
  final now = DateTime.now();
  final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
  return events.where((e) =>
    e.startTime.isAfter(now) && e.startTime.isBefore(endOfDay)
  ).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
});

// Planned maintenances for TODAY only
final todayPlannedMaintenancesProvider = Provider<List<Maintenance>>((ref) {
  final planned = ref.watch(plannedMaintenancesProvider).valueOrNull ?? [];
  final now = DateTime.now();
  return planned.where((m) {
    final d = DateTime.fromMillisecondsSinceEpoch(m.date);
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }).toList()..sort((a, b) => a.startHour.compareTo(b.startHour));
});

// Next planned maintenances (not today, future)
final upcomingPlannedMaintenancesProvider = Provider<List<Maintenance>>((ref) {
  final planned = ref.watch(plannedMaintenancesProvider).valueOrNull ?? [];
  final now = DateTime.now();
  final startOfTomorrow = DateTime(now.year, now.month, now.day + 1);
  return planned.where((m) {
    final d = DateTime.fromMillisecondsSinceEpoch(m.date);
    return d.isAfter(startOfTomorrow);
  }).toList()..sort((a, b) => a.date.compareTo(b.date));
});

// Timeline items for today (maintenances + events merged + sorted by hour)
final todayTimelineProvider = Provider<List<TimelineItem>>((ref) {
  final maintenances = ref.watch(plannedMaintenancesProvider).valueOrNull ?? [];
  final events = ref.watch(eventsProvider).valueOrNull ?? [];
  final now = DateTime.now();

  final items = <TimelineItem>[];

  // Add today's planned maintenances
  for (final m in maintenances) {
    final d = DateTime.fromMillisecondsSinceEpoch(m.date);
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      final start = DateTime(d.year, d.month, d.day, m.startHour);
      final end = start.add(Duration(minutes: m.durationMinutes));
      items.add(TimelineItem(
        startTime: start,
        endTime: end,
        title: m.type,
        terrainId: m.terrainId,
        type: TimelineItemType.maintenance,
        originalMaintenance: m,
      ));
    }
  }

  // Add today's events
  for (final e in events) {
    if (e.startTime.year == now.year &&
        e.startTime.month == now.month &&
        e.startTime.day == now.day) {
      items.add(TimelineItem(
        startTime: e.startTime,
        endTime: e.endTime,
        title: e.title,
        terrainId: e.terrainIds.isNotEmpty ? e.terrainIds.first : null,
        type: TimelineItemType.event,
        originalEvent: e,
      ));
    }
  }

  items.sort((a, b) => a.startTime.compareTo(b.startTime));
  return items;
});
