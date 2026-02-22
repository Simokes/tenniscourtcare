import '../entities/app_event.dart';

abstract class EventRepository {
  Stream<List<AppEvent>> watchEvents({DateTime? start, DateTime? end});
  Future<List<AppEvent>> getEvents({DateTime? start, DateTime? end});
  Future<int> addEvent(AppEvent event);
  Future<bool> updateEvent(AppEvent event);
  Future<int> deleteEvent(int id);
}
