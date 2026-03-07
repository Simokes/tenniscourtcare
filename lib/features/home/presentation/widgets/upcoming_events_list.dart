import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../calendar/providers/event_provider.dart';
import '../../../../shared/widgets/premium/premium_card.dart';
import '../../../calendar/presentation/screens/add_edit_event_screen.dart';
import '../../../maintenance/presentation/widgets/add_maintenance_sheet.dart';
import '../../../terrain/providers/terrain_provider.dart';
import '../../providers/dashboard_providers.dart';
import 'package:tenniscourtcare/core/theme/dashboard_theme_extension.dart';

class UpcomingEventsList extends ConsumerWidget {
  const UpcomingEventsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final dc = Theme.of(context).extension<DashboardColors>();

    // SECTION A — "Aujourd'hui"
    final todayUpcomingEvents = ref.watch(todayUpcomingEventsProvider);

    // SECTION B — "À venir" (next days)
    final now = DateTime.now();
    final startOfTomorrow = DateTime(now.year, now.month, now.day + 1);
    final end = startOfTomorrow.add(const Duration(days: 30));
    final range = (start: startOfTomorrow, end: end);
    final futureItemsAsync = ref.watch(calendarItemsProvider(range));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (todayUpcomingEvents.isNotEmpty) ...[
          _buildSectionHeader(context, "Aujourd'hui"),
          Column(
            children: todayUpcomingEvents.take(3).map((event) {
              // Convert AppEvent to CalendarItem format for _EventItem
              final item = CalendarItem(
                id: event.id.toString(),
                title: event.title,
                startTime: event.startTime,
                endTime: event.endTime,
                color: Color(event.color),
                type: CalendarItemType.event,
                originalObject: event,
                terrainId: event.terrainIds.isNotEmpty
                    ? event.terrainIds.first
                    : null,
              );
              return _EventItem(item: item);
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],

        _buildSectionHeader(context, 'À venir'),
        futureItemsAsync.when(
          data: (items) {
            final futureItems = items.take(3).toList();
            if (futureItems.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: PremiumCard(
                  color: cs.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        'Aucun événement prévu prochainement.',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }
            return Column(
              children: futureItems.map((item) => _EventItem(item: item)).toList(),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Erreur: $err',
                style: TextStyle(color: dc?.dangerColor ?? Colors.red),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          TextButton(
            onPressed: () {
              context.push('/calendar');
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            child: const Text('Voir tout'),
          ),
        ],
      ),
    );
  }
}

class _EventItem extends ConsumerWidget {
  final CalendarItem item;

  const _EventItem({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final dc = Theme.of(context).extension<DashboardColors>();
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
              final terrain = await ref.read(
                terrainProvider(item.terrainId!).future,
              );
              if (terrain != null && context.mounted) {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => AddMaintenanceSheet(
                    terrain: terrain,
                    existingMaintenance: item.originalObject,
                  ),
                );
              }
            }
          } else {
            // Edit Event
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    AddEditEventScreen(eventToEdit: item.originalObject),
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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isMaintenance)
                            Icon(
                              Icons.build_circle,
                              size: 16,
                              color: dc?.warningColor ?? Colors.orange,
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dateFormat.format(item.startTime),
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          if (item.location != null) ...[
                            const SizedBox(width: 12),
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.location!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurfaceVariant,
                                ),
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
              Icon(Icons.chevron_right, size: 20, color: cs.onSurfaceVariant),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}
