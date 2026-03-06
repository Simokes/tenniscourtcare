import '../../../../domain/entities/maintenance.dart';
import '../../../../domain/entities/app_event.dart';

enum TimelineItemType { maintenance, event }

class TimelineItem {
  final DateTime startTime;
  final DateTime endTime;
  final String title;
  final int? terrainId;
  final TimelineItemType type;
  final Maintenance? originalMaintenance;
  final AppEvent? originalEvent;

  const TimelineItem({
    required this.startTime,
    required this.endTime,
    required this.title,
    this.terrainId,
    required this.type,
    this.originalMaintenance,
    this.originalEvent,
  });

  bool get isNow {
    final now = DateTime.now();
    return startTime.isBefore(now) && endTime.isAfter(now);
  }

  bool get isPast => endTime.isBefore(DateTime.now());
}
