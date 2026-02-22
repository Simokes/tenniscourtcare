import 'package:drift/drift.dart';
import '../../domain/entities/app_event.dart';
import '../../domain/repositories/event_repository.dart';
import '../database/app_database.dart';

class EventRepositoryImpl implements EventRepository {
  final AppDatabase _db;

  EventRepositoryImpl(this._db);

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
  Future<int> addEvent(AppEvent event) {
    return _db.into(_db.events).insert(
          EventsCompanion.insert(
            title: event.title,
            description: Value(event.description),
            startTime: event.startTime,
            endTime: event.endTime,
            color: event.color,
            terrainIds: event.terrainIds,
          ),
        );
  }

  @override
  Future<bool> updateEvent(AppEvent event) async {
    if (event.id == null) return false;
    final result = await (_db.update(_db.events)
          ..where((t) => t.id.equals(event.id!)))
        .write(
      EventsCompanion(
        title: Value(event.title),
        description: Value(event.description),
        startTime: Value(event.startTime),
        endTime: Value(event.endTime),
        color: Value(event.color),
        terrainIds: Value(event.terrainIds),
      ),
    );
    return result > 0;
  }

  @override
  Future<int> deleteEvent(int id) {
    return (_db.delete(_db.events)..where((t) => t.id.equals(id))).go();
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
    );
  }
}
