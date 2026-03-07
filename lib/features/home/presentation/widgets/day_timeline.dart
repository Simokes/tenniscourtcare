import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/dashboard_providers.dart';
import '../../models/timeline_item.dart';
import '../../../admin/providers/club_info_provider.dart';
import 'package:tenniscourtcare/core/theme/dashboard_theme_extension.dart';

class DayTimeline extends ConsumerWidget {
  const DayTimeline({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final dc = Theme.of(context).extension<DashboardColors>();

    final timelineItems = ref.watch(todayTimelineProvider);
    if (timelineItems.isEmpty) {
      return const SizedBox.shrink();
    }

    final clubInfoAsync = ref.watch(clubInfoProvider);
    final clubInfo = clubInfoAsync.valueOrNull;

    final openingHour = clubInfo?.openingHour ?? 8;
    final closingHour = clubInfo?.closingHour ?? 21;
    final numHours = closingHour - openingHour;
    if (numHours <= 0) return const SizedBox.shrink();

    const hourWidth = 64.0;
    final now = DateTime.now();
    final timelineWidth = numHours * hourWidth;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Aujourd\'hui',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(width: 8),
              Text(
                DateFormat('EEEE d MMM', 'fr_FR').format(now),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              height: 80,
              width: timelineWidth + hourWidth, // Extra space for last label
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Hour labels and grid lines
                  for (int i = 0; i <= numHours; i++)
                    Positioned(
                      left: i * hourWidth,
                      top: 0,
                      bottom: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${openingHour + i}h',
                            style: TextStyle(
                              fontSize: 10,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          Expanded(
                            child: Container(
                              width: 1,
                              color: cs.outlineVariant.withValues(alpha: 0.3),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Timeline blocks
                  for (final item in timelineItems) ...[
                    Builder(
                      builder: (context) {
                        final startMinutesFromOpening = (item.startTime.hour * 60 + item.startTime.minute) - (openingHour * 60);
                        if (startMinutesFromOpening < 0) return const SizedBox.shrink();

                        final durationMinutes = item.endTime.difference(item.startTime).inMinutes;
                        final left = (startMinutesFromOpening / 60) * hourWidth;
                        final width = (durationMinutes / 60) * hourWidth;

                        final color = item.type == TimelineItemType.maintenance
                            ? dc?.maintenanceColor ?? Colors.orange
                            : Color(item.originalEvent?.color ?? cs.primary.toARGB32());

                        return Positioned(
                          left: left,
                          top: 24,
                          width: width,
                          height: 40,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(4),
                              border: item.isNow
                                  ? Border.all(color: Colors.white, width: 2)
                                  : null,
                              boxShadow: item.isNow
                                  ? [
                                      BoxShadow(
                                        color: color.withValues(alpha: 0.5),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      )
                                    ]
                                  : null,
                            ),
                            child: Text(
                              item.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      },
                    ),
                  ],

                  // Current time indicator
                  if (now.hour >= openingHour && now.hour <= closingHour)
                    Positioned(
                      left: ((now.hour * 60 + now.minute) - (openingHour * 60)) / 60 * hourWidth,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 2,
                        color: dc?.dangerColor ?? Colors.red,
                        child: Column(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: dc?.dangerColor ?? Colors.red,
                                shape: BoxShape.circle,
                              ),
                              transform: Matrix4.translationValues(-2, 0, 0),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
