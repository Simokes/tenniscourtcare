import 'package:flutter/material.dart';
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
