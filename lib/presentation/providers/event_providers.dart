import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/event_repository_impl.dart';
import '../../domain/entities/app_event.dart';
import '../../domain/entities/maintenance.dart';
import '../../domain/repositories/event_repository.dart';
import 'database_provider.dart';
import 'terrain_provider.dart';

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepositoryImpl(ref.watch(databaseProvider));
});

typedef DateRange = ({DateTime start, DateTime end});

final eventsProvider = StreamProvider.family<List<AppEvent>, DateRange>((ref, range) {
  return ref.watch(eventRepositoryProvider).watchEvents(
    start: range.start,
    end: range.end,
  );
});

final maintenancesInRangeProvider = StreamProvider.family<List<Maintenance>, DateRange>((ref, range) {
  final db = ref.watch(databaseProvider);
  return db.watchMaintenancesInRange(
    range.start.millisecondsSinceEpoch,
    range.end.millisecondsSinceEpoch,
  );
});

enum CalendarItemType { event, maintenance }

class CalendarItem {
  final String id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final Color color;
  final CalendarItemType type;
  final dynamic originalObject;
  final String? location; // E.g., "Terrain 1, Terrain 2"

  const CalendarItem({
    required this.id,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    required this.color,
    required this.type,
    required this.originalObject,
    this.location,
  });
}

final calendarItemsProvider = Provider.family<AsyncValue<List<CalendarItem>>, DateRange>((ref, range) {
  final eventsAsync = ref.watch(eventsProvider(range));
  final maintenancesAsync = ref.watch(maintenancesInRangeProvider(range));
  final terrainsAsync = ref.watch(terrainsProvider);

  if (eventsAsync.isLoading || maintenancesAsync.isLoading || terrainsAsync.isLoading) {
    return const AsyncValue.loading();
  }

  if (eventsAsync.hasError) return AsyncValue.error(eventsAsync.error!, eventsAsync.stackTrace!);
  if (maintenancesAsync.hasError) return AsyncValue.error(maintenancesAsync.error!, maintenancesAsync.stackTrace!);
  if (terrainsAsync.hasError) return AsyncValue.error(terrainsAsync.error!, terrainsAsync.stackTrace!);

  final events = eventsAsync.valueOrNull ?? [];
  final maintenances = maintenancesAsync.valueOrNull ?? [];
  final terrains = terrainsAsync.valueOrNull ?? [];

  final List<CalendarItem> items = [];

  // Process Events
  for (final event in events) {
    // Map terrain IDs to names
    final terrainNames = event.terrainIds.map((id) {
       try {
         return terrains.firstWhere((t) => t.id == id).nom;
       } catch (_) {
         return 'Terrain Inconnu';
       }
    }).join(', ');

    items.add(CalendarItem(
      id: 'event_${event.id}',
      title: event.title,
      description: event.description,
      startTime: event.startTime,
      endTime: event.endTime,
      color: Color(event.color),
      type: CalendarItemType.event,
      originalObject: event,
      location: terrainNames.isNotEmpty ? terrainNames : null,
    ));
  }

  // Process Maintenances
  for (final maintenance in maintenances) {
    String terrainName = 'Terrain Inconnu';
    try {
      final t = terrains.firstWhere((t) => t.id == maintenance.terrainId);
      terrainName = t.nom;
    } catch (_) {}

    // Maintenance date is epoch ms. Assume 1 hour duration.
    final startDate = DateTime.fromMillisecondsSinceEpoch(maintenance.date);
    final endDate = startDate.add(const Duration(hours: 1));

    items.add(CalendarItem(
      id: 'maint_${maintenance.id}',
      title: 'Maintenance: ${maintenance.type}',
      description: maintenance.commentaire,
      startTime: startDate,
      endTime: endDate,
      color: Colors.orange, // Default color for maintenance
      type: CalendarItemType.maintenance,
      originalObject: maintenance,
      location: terrainName,
    ));
  }

  // Sort by start time
  items.sort((a, b) => a.startTime.compareTo(b.startTime));

  return AsyncValue.data(items);
});
