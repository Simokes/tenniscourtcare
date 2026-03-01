import '../entities/app_event.dart';

abstract class EventRepository {
  Stream<List<AppEvent>> watchEvents({DateTime? start, DateTime? end});
  Future<List<AppEvent>> getEvents({DateTime? start, DateTime? end});
  Future<void> addEvent(AppEvent event);
  Future<void> updateEvent(AppEvent event);
  Future<void> deleteEvent(String firebaseId);
}
