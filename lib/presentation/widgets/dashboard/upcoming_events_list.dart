import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/event_providers.dart';
import '../../screens/calendar/calendar_screen.dart';

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
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                child: const Text('Voir tout'),
              ),
            ],
          ),
        ),
        itemsAsync.when(
          data: (items) {
            // Filter out past events (if provider returns range based, it might include today's past events depending on time)
            // But we requested start of today, so that's fine.
            // Take top 3
            final upcoming = items.take(3).toList();

            if (upcoming.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        'Aucun événement prévu prochainement.',
                        style: TextStyle(color: Colors.grey.shade600),
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
            child: Text('Erreur: $err'),
          )),
        ),
      ],
    );
  }
}

class _EventItem extends StatelessWidget {
  final CalendarItem item;

  const _EventItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM HH:mm', 'fr_FR');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      color: Colors.white,
      child: ListTile(
        leading: Container(
          width: 4,
          height: double.infinity,
          decoration: BoxDecoration(
            color: item.color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        title: Text(
          item.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${dateFormat.format(item.startTime)} • ${item.location ?? "Non spécifié"}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
        onTap: () {
          // Navigate to Calendar focused on this day
          // For now, just open CalendarScreen
           Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CalendarScreen()),
          );
        },
      ),
    );
  }
}
