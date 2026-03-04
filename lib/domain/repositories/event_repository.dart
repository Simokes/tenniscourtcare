import '../entities/app_event.dart';

abstract class EventRepository {
  Future<List<AppEvent>> getEvents({DateTime? start, DateTime? end});
  Future<String> addEvent(AppEvent event);
  Future<void> updateEvent(AppEvent event);
  Future<void> deleteEvent(String firebaseId);
}
