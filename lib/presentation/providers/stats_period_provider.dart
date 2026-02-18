import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/date_utils.dart';

enum PeriodType { day, week, month, custom }

class StatsPeriod {
  final PeriodType type;
  final DateTime? customStart;
  final DateTime? customEnd;

  const StatsPeriod({required this.type, this.customStart, this.customEnd});

  /// Retourne les bornes (start, end) en epoch ms
  ({int start, int end}) get bounds {
    final now = DateTime.now();

    switch (type) {
      case PeriodType.day:
        return (start: DateUtils.startOfDay(now), end: DateUtils.endOfDay(now));
      case PeriodType.week:
        return (
          start: DateUtils.startOfWeek(now),
          end: DateUtils.endOfWeek(now),
        );
      case PeriodType.month:
        return (
          start: DateUtils.startOfMonth(now),
          end: DateUtils.endOfMonth(now),
        );
      case PeriodType.custom:
        if (customStart == null || customEnd == null) {
          throw Exception('Dates personnalisées requises pour custom');
        }
        return (
          start: DateUtils.startOfDay(customStart!),
          end: DateUtils.endOfDay(customEnd!),
        );
    }
  }

  StatsPeriod copyWith({
    PeriodType? type,
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    return StatsPeriod(
      type: type ?? this.type,
      customStart: customStart ?? this.customStart,
      customEnd: customEnd ?? this.customEnd,
    );
  }
}

class StatsPeriodNotifier extends StateNotifier<StatsPeriod> {
  StatsPeriodNotifier() : super(const StatsPeriod(type: PeriodType.month));

  void setPeriod(PeriodType type) {
    state = StatsPeriod(type: type);
  }

  void setCustomPeriod(DateTime start, DateTime end) {
    state = StatsPeriod(
      type: PeriodType.custom,
      customStart: start,
      customEnd: end,
    );
  }
}

final statsPeriodProvider =
    StateNotifierProvider<StatsPeriodNotifier, StatsPeriod>((ref) {
      return StatsPeriodNotifier();
    });
