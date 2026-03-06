with open("lib/features/home/presentation/widgets/current_events_banner.dart", "w") as f:
    f.write("""import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/dashboard_providers.dart';
import '../../../terrain/providers/terrain_provider.dart';

class CurrentEventsBanner extends ConsumerStatefulWidget {
  const CurrentEventsBanner({super.key});

  @override
  ConsumerState<CurrentEventsBanner> createState() => _CurrentEventsBannerState();
}

class _CurrentEventsBannerState extends ConsumerState<CurrentEventsBanner> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentEvents = ref.watch(currentEventsProvider);
    if (currentEvents.isEmpty) {
      return const SizedBox.shrink();
    }

    final terrainsAsync = ref.watch(terrainsProvider);
    final terrains = terrainsAsync.valueOrNull ?? [];

    Widget buildEventBanner(dynamic event) {
      final startTimeStr = DateFormat('HH:mm').format(event.startTime);
      final endTimeStr = DateFormat('HH:mm').format(event.endTime);

      final terrainNames = event.terrainIds.map((id) {
        final matches = terrains.where((t) => t.id == id);
        return matches.isNotEmpty ? matches.first.nom : 'Terrain inconnu';
      }).join(', ');

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(event.color).withOpacity(0.15),
              Colors.white,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Color(currentEvents.first.color).withOpacity(0.4),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: Color(event.color),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.circle, size: 8, color: Color(event.color)),
            const SizedBox(width: 4),
            Text(
              'EN COURS',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(event.color),
                fontSize: 10,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$startTimeStr → $endTimeStr',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (terrainNames.isNotEmpty)
                    Text(
                      terrainNames,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (currentEvents.length == 1) {
      return SizedBox(
        height: 88,
        child: buildEventBanner(currentEvents.first),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 88,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: currentEvents.length,
            itemBuilder: (context, index) {
              return buildEventBanner(currentEvents[index]);
            },
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(currentEvents.length, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentPage == index ? Colors.blue : Colors.grey,
              ),
            );
          }),
        ),
      ],
    );
  }
}
""")

with open("lib/features/home/presentation/widgets/day_timeline.dart", "w") as f:
    f.write("""import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/dashboard_providers.dart';
import '../../models/timeline_item.dart';
import '../../../admin/providers/club_info_provider.dart';

class DayTimeline extends ConsumerWidget {
  const DayTimeline({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                'Aujourd\\'hui',
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
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                          Expanded(
                            child: Container(
                              width: 1,
                              color: Colors.grey.withOpacity(0.2),
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
                            ? Colors.orange
                            : Color(item.originalEvent?.color ?? Colors.blue.value);

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
                                        color: color.withOpacity(0.5),
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
                        color: Colors.red,
                        child: Column(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.red,
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
""")
