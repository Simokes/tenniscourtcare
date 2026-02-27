import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/event_repository_impl.dart';
import '../../domain/entities/app_event.dart';
import '../../domain/entities/terrain.dart'; // Needed
import '../../domain/repositories/event_repository.dart';
import 'database_provider.dart';
import 'maintenance_provider.dart';
import 'sync_status_provider.dart';
import 'terrain_provider.dart';

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final firebaseService = ref.watch(firebaseSyncServiceProvider);
  return EventRepositoryImpl(db, firebaseService);
});

final localEventsProvider = FutureProvider<List<AppEvent>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllEvents().first;
});

final firestoreEventsProvider = StreamProvider<List<AppEvent>>((ref) {
  final firebaseService = ref.watch(firebaseSyncServiceProvider);
  return firebaseService.eventService.watchEvents();
});

final eventsProvider = StreamProvider<List<AppEvent>>((ref) async* {
  final localFuture = ref.watch(localEventsProvider.future);

  final local = await localFuture;
  yield local;

  yield* ref.watch(firestoreEventsProvider.stream).map((remote) {
    return _mergeEvents(local, remote);
  });
});

final addEventProvider = Provider<Future<void> Function(AppEvent)>((ref) {
  return (AppEvent event) async {
    final repo = ref.read(eventRepositoryProvider);
    await repo.addEvent(event);
    ref.invalidate(eventsProvider);
  };
});

final updateEventProvider = Provider<Future<void> Function(AppEvent)>((ref) {
  return (AppEvent event) async {
    final repo = ref.read(eventRepositoryProvider);
    await repo.updateEvent(event);
    ref.invalidate(eventsProvider);
  };
});

List<AppEvent> _mergeEvents(List<AppEvent> local, List<AppEvent> remote) {
  final merged = <int, AppEvent>{};

  for (final t in local) {
    if (t.id != null) merged[t.id!] = t;
  }

  for (final t in remote) {
    if (t.id != null && merged.containsKey(t.id)) {
      final existing = merged[t.id]!;
      merged[t.id!] = existing.updatedAt.isAfter(t.updatedAt) ? existing : t;
    } else if (t.id != null) {
      merged[t.id!] = t;
    }
  }

  return merged.values.toList();
}

// --- Calendar Helpers ---

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
  final int? terrainId;
  final String? location;

  CalendarItem({
    required this.id,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    required this.color,
    required this.type,
    required this.originalObject,
    this.terrainId,
    this.location,
  });
}

final calendarItemsProvider =
    Provider.family<
      AsyncValue<List<CalendarItem>>,
      ({DateTime start, DateTime end})
    >((ref, range) {
      final eventsAsync = ref.watch(eventsProvider);
      final maintenancesAsync = ref.watch(maintenancesProvider);
      final terrainsAsync = ref.watch(terrainsProvider);

      // If any is loading, return loading
      if (eventsAsync.isLoading ||
          maintenancesAsync.isLoading ||
          terrainsAsync.isLoading) {
        return const AsyncValue.loading();
      }

      // If any has error, return error (priority to events)
      if (eventsAsync.hasError) {
        return AsyncValue.error(eventsAsync.error!, eventsAsync.stackTrace!);
      }
      if (maintenancesAsync.hasError) {
        return AsyncValue.error(
          maintenancesAsync.error!,
          maintenancesAsync.stackTrace!,
        );
      }
      if (terrainsAsync.hasError) {
        return AsyncValue.error(
          terrainsAsync.error!,
          terrainsAsync.stackTrace!,
        );
      }

      // If we have data (even empty)
      if (eventsAsync.hasValue &&
          maintenancesAsync.hasValue &&
          terrainsAsync.hasValue) {
        final events = eventsAsync.value!;
        final maintenances = maintenancesAsync.value!;
        final terrains = terrainsAsync.value!;

        final items = <CalendarItem>[];

        // Map Events
        for (final event in events) {
          if (event.startTime.isBefore(range.end) &&
              event.endTime.isAfter(range.start)) {
            items.add(
              CalendarItem(
                id: 'event_${event.id}',
                title: event.title,
                description: event.description,
                startTime: event.startTime,
                endTime: event.endTime,
                color: Color(event.color),
                type: CalendarItemType.event,
                originalObject: event,
                terrainId: event.terrainIds.isNotEmpty
                    ? event.terrainIds.first
                    : null,
                location: event.terrainIds.isNotEmpty
                    ? terrains
                          .where((t) => event.terrainIds.contains(t.id))
                          .map((t) => t.nom)
                          .join(', ')
                    : null,
              ),
            );
          }
        }

        // Map Maintenances
        for (final maintenance in maintenances) {
          final terrain = terrains.firstWhere(
            (t) => t.id == maintenance.terrainId,
            orElse: () => Terrain(
              id: 0,
              nom: 'Terrain inconnu',
              type: TerrainType.terreBattue,
              status: TerrainStatus.unavailable,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          final startTime = DateTime.fromMillisecondsSinceEpoch(
            maintenance.date,
          );
          final endTime = startTime.add(
            const Duration(hours: 1),
          ); // Default duration

          if (startTime.isBefore(range.end) && endTime.isAfter(range.start)) {
            items.add(
              CalendarItem(
                id: 'maint_${maintenance.id}',
                title: 'Maintenance: ${terrain.nom}',
                description: maintenance.commentaire ?? maintenance.type,
                startTime: startTime,
                endTime: endTime,
                color: Colors.orange,
                type: CalendarItemType.maintenance,
                originalObject: maintenance,
                terrainId: maintenance.terrainId,
                location: terrain.nom,
              ),
            );
          }
        }

        return AsyncValue.data(items);
      }

      // Fallback
      return const AsyncValue.loading();
    });
