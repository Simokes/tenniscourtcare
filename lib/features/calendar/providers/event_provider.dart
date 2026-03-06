import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/event_repository_impl.dart';
import '../../../domain/entities/app_event.dart';
import '../../../domain/entities/terrain.dart'; // Needed
import '../../../domain/repositories/event_repository.dart';
import '../../../core/providers/core_providers.dart';
import '../../maintenance/providers/maintenance_provider.dart';
import '../../terrain/providers/terrain_provider.dart';
import '../../../data/mappers/event_mapper.dart';
import '../../../domain/models/repository_exception.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return EventRepositoryImpl(db: db, fs: FirebaseFirestore.instance);
});

final eventsProvider = StreamProvider<List<AppEvent>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllEvents();
});

class EventNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> addEvent(AppEvent event) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(eventRepositoryProvider);
      final db = ref.read(databaseProvider);

      final firebaseId = await repo.addEvent(event);
      final eventWithId = event.copyWith(firebaseId: firebaseId);
      await db.upsertEvent(eventWithId.toCompanion());

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateEvent(AppEvent event) async {
    if (event.firebaseId == null) {
      throw const RepositoryException('Cannot update event without a firebaseId');
    }
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(eventRepositoryProvider);
      await repo.updateEvent(event);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteEvent(String firebaseId) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(eventRepositoryProvider);
      await repo.deleteEvent(firebaseId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final eventNotifierProvider = AsyncNotifierProvider<EventNotifier, void>(
  () => EventNotifier(),
);


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
  final bool isPlanned;

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
    this.isPlanned = false,
  });
}

final calendarItemsProvider =
    Provider.family<
      AsyncValue<List<CalendarItem>>,
      ({DateTime start, DateTime end})
    >((ref, range) {
      final eventsAsync = ref.watch(eventsProvider);
      final maintenancesAsync = ref.watch(maintenancesProvider);
      final plannedMaintenancesAsync = ref.watch(plannedMaintenancesProvider);
      final terrainsAsync = ref.watch(terrainsProvider);

      // If any is loading, return loading
      if (eventsAsync.isLoading ||
          maintenancesAsync.isLoading ||
          plannedMaintenancesAsync.isLoading ||
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
      if (plannedMaintenancesAsync.hasError) {
        return AsyncValue.error(
          plannedMaintenancesAsync.error!,
          plannedMaintenancesAsync.stackTrace!,
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
          plannedMaintenancesAsync.hasValue &&
          terrainsAsync.hasValue) {
        final events = eventsAsync.value!;
        final maintenances = [...maintenancesAsync.value!, ...plannedMaintenancesAsync.value!];
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
          final date = DateTime.fromMillisecondsSinceEpoch(maintenance.date);
          final startTime = DateTime(
            date.year,
            date.month,
            date.day,
            maintenance.startHour,
          );
          final endTime = startTime.add(
            Duration(minutes: maintenance.durationMinutes),
          );

          if (startTime.isBefore(range.end) && endTime.isAfter(range.start)) {
            items.add(
              CalendarItem(
                id: 'maint_${maintenance.id}',
                title: 'Maintenance: ${terrain.nom}',
                description: maintenance.commentaire ?? maintenance.type,
                startTime: startTime,
                endTime: endTime,
                color: maintenance.isPlanned ? TerrainStatus.maintenance.color : Colors.green,
                type: CalendarItemType.maintenance,
                originalObject: maintenance,
                terrainId: maintenance.terrainId,
                location: terrain.nom,
                isPlanned: maintenance.isPlanned,
              ),
            );
          }
        }

        return AsyncValue.data(items);
      }

      // Fallback
      return const AsyncValue.loading();
    });
