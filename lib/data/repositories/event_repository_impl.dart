import 'package:drift/drift.dart';
import '../../domain/entities/app_event.dart';
import '../../domain/entities/sync_status.dart';
import '../../domain/repositories/event_repository.dart';
import '../database/app_database.dart';
import '../services/firebase_sync_service.dart';

class EventRepositoryImpl implements EventRepository {
  final AppDatabase _db;
  final FirebaseSyncService _firebaseService;

  EventRepositoryImpl(this._db, this._firebaseService);

  @override
  Stream<List<AppEvent>> watchEvents({DateTime? start, DateTime? end}) {
    final query = _db.select(_db.events);

    if (start != null) {
      query.where((t) => t.startTime.isBiggerOrEqualValue(start));
    }
    if (end != null) {
      query.where((t) => t.endTime.isSmallerOrEqualValue(end));
    }

    return query.watch().map((rows) => rows.map((row) => _toDomain(row)).toList());
  }

  @override
  Future<List<AppEvent>> getEvents({DateTime? start, DateTime? end}) async {
    final query = _db.select(_db.events);

    if (start != null) {
      query.where((t) => t.startTime.isBiggerOrEqualValue(start));
    }
    if (end != null) {
      query.where((t) => t.endTime.isSmallerOrEqualValue(end));
    }

    final rows = await query.get();
    return rows.map((row) => _toDomain(row)).toList();
  }

  @override
  Future<int> addEvent(AppEvent event) async {
    // 1. Sauvegarde LOCAL
    final localEvent = event.copyWith(
      syncStatus: SyncStatus.local,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final id = await _db.into(_db.events).insert(
          EventsCompanion.insert(
            title: localEvent.title,
            description: Value(localEvent.description),
            startTime: localEvent.startTime,
            endTime: localEvent.endTime,
            color: localEvent.color,
            terrainIds: localEvent.terrainIds,
            // Sync fields
            createdAt: localEvent.createdAt,
            updatedAt: localEvent.updatedAt,
            syncStatus: Value(localEvent.syncStatus.name),
            firebaseId: Value(localEvent.firebaseId),
            createdBy: Value(localEvent.createdBy),
            modifiedBy: Value(localEvent.modifiedBy),
          ),
        );

    // 2. Sync Firebase
    _syncEventToFirebase(localEvent.copyWith(id: id));

    return id;
  }

  @override
  Future<bool> updateEvent(AppEvent event) async {
    if (event.id == null) return false;

    final updatedEvent = event.copyWith(
      syncStatus: SyncStatus.local,
      updatedAt: DateTime.now(),
    );

    final result = await (_db.update(_db.events)
          ..where((t) => t.id.equals(updatedEvent.id!)))
        .write(
      EventsCompanion(
        title: Value(updatedEvent.title),
        description: Value(updatedEvent.description),
        startTime: Value(updatedEvent.startTime),
        endTime: Value(updatedEvent.endTime),
        color: Value(updatedEvent.color),
        terrainIds: Value(updatedEvent.terrainIds),
        // Sync fields
        updatedAt: Value(updatedEvent.updatedAt),
        syncStatus: Value(updatedEvent.syncStatus.name),
        firebaseId: Value(updatedEvent.firebaseId),
        modifiedBy: Value(updatedEvent.modifiedBy),
      ),
    );

    if (result > 0) {
      _syncEventToFirebase(updatedEvent);
      return true;
    }
    return false;
  }

  @override
  Future<int> deleteEvent(int id) async {
    final result = await (_db.delete(_db.events)..where((t) => t.id.equals(id))).go();
    return result;
  }

  Future<void> _syncEventToFirebase(AppEvent event) async {
    try {
      await _firebaseService.eventService.uploadEventToFirestore(event);
    } catch (e) {
      print('Failed to sync event: $e');
    }
  }

  AppEvent _toDomain(EventRow row) {
    return AppEvent(
      id: row.id,
      title: row.title,
      description: row.description,
      startTime: row.startTime,
      endTime: row.endTime,
      color: row.color,
      terrainIds: row.terrainIds,
      syncStatus: SyncStatus.fromString(row.syncStatus),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      firebaseId: row.firebaseId,
      createdBy: row.createdBy,
      modifiedBy: row.modifiedBy,
    );
  }
}
