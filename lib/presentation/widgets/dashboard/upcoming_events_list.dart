import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/event_providers.dart';
import '../../screens/calendar/calendar_screen.dart';
import '../../widgets/premium/premium_card.dart';
import '../../screens/calendar/add_edit_event_screen.dart';
import '../../widgets/add_maintenance_sheet.dart';
import '../../providers/terrain_provider.dart';

class UpcomingEventsList extends ConsumerWidget {
  const UpcomingEventsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch events for the next 30 days
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 30));
    final range = (start: start, end: end);

    final itemsAsync = ref.watch(calendarItemsProvider(range));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Prochains Événements',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CalendarScreen()),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
                child: const Text('Voir tout'),
              ),
            ],
          ),
        ),
        itemsAsync.when(
          data: (items) {
            final upcoming = items.take(3).toList();

            if (upcoming.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: PremiumCard(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        'Aucun événement prévu prochainement.',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      ),
                    ),
                  ),
                ),
              );
            }

            return Column(
              children: upcoming.map((item) => _EventItem(item: item)).toList(),
            );
          },
          loading: () => const Center(child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          )),
          error: (err, stack) => Center(child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Erreur: $err', style: TextStyle(color: Colors.red)),
          )),
        ),
      ],
    );
  }
}

class _EventItem extends ConsumerWidget {
  final CalendarItem item;

  const _EventItem({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('dd MMM HH:mm', 'fr_FR');
    final isMaintenance = item.type == CalendarItemType.maintenance;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: PremiumCard(
        padding: EdgeInsets.zero,
        onTap: () async {
          if (isMaintenance) {
            // Edit Maintenance
             if (item.terrainId != null) {
              final terrain = await ref.read(terrainProvider(item.terrainId!).future);
              if (terrain != null && context.mounted) {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => AddMaintenanceSheet(
                    terrain: terrain,
                    maintenance: item.originalObject,
                  ),
                );
              }
            }
          } else {
            // Edit Event
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddEditEventScreen(eventToEdit: item.originalObject),
              ),
            );
          }
        },
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 6,
                decoration: BoxDecoration(
                  color: item.color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isMaintenance)
                            const Icon(Icons.build_circle, size: 16, color: Colors.orange),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            dateFormat.format(item.startTime),
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                          if (item.location != null) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.location_on, size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.location!,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}
