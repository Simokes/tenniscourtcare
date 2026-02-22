import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../providers/event_providers.dart';
import 'add_edit_event_screen.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late ({DateTime start, DateTime end}) _range;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay;
    _updateRange();
  }

  void _updateRange() {
    // Fetch data for the whole month + 1 week padding
    final start = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
    final end = DateTime(_focusedDay.year, _focusedDay.month + 2, 0);
    _range = (start: start, end: end);
  }

  @override
  Widget build(BuildContext context) {
    // Watch items for the current range
    final itemsAsync = ref.watch(calendarItemsProvider(_range));

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Calendrier', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Calendar Widget
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 16),
            child: TableCalendar<CalendarItem>(
              locale: 'fr_FR',
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay; // update focused day as well
                });
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                  _updateRange(); // Update fetch range
                });
              },
              eventLoader: (day) {
                // If loading or error, return empty
                if (!itemsAsync.hasValue) return [];

                final items = itemsAsync.value!;
                // Simple overlap check
                // An event happens on 'day' if it overlaps with [day 00:00, day 23:59]
                final startOfDay = DateTime(day.year, day.month, day.day);
                final endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));

                return items.where((item) {
                  return item.startTime.isBefore(endOfDay) && item.endTime.isAfter(startOfDay);
                }).toList();
              },
              calendarStyle: const CalendarStyle(
                markersMaxCount: 4,
                markerDecoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
            ),
          ),

          const Divider(height: 1),

          // Selected Day Events List
          Expanded(
            child: itemsAsync.when(
              data: (allItems) {
                // Filter again for selected day (could reuse logic but this is safe)
                final startOfDay = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
                final endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));

                final selectedItems = allItems.where((item) {
                  return item.startTime.isBefore(endOfDay) && item.endTime.isAfter(startOfDay);
                }).toList();

                if (selectedItems.isEmpty) {
                  return const Center(
                    child: Text('Aucun événement ce jour.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: selectedItems.length,
                  itemBuilder: (context, index) {
                    final item = selectedItems[index];
                    return _CalendarItemCard(item: item);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Erreur: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditEventScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CalendarItemCard extends StatelessWidget {
  final CalendarItem item;

  const _CalendarItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('HH:mm');
    final duration = item.endTime.difference(item.startTime);
    final isLongEvent = duration.inHours >= 24;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (item.location != null)
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.location!,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  isLongEvent
                    ? 'Toute la journée'
                    : '${dateFormat.format(item.startTime)} - ${dateFormat.format(item.endTime)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        trailing: item.type == CalendarItemType.event
            ? IconButton(
                icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                onPressed: () {
                   Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddEditEventScreen(eventToEdit: item.originalObject),
                    ),
                  );
                },
              )
            : null, // Maintenance is managed elsewhere for now
        onTap: () {
           if (item.type == CalendarItemType.event) {
             Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditEventScreen(eventToEdit: item.originalObject),
                ),
              );
           }
        },
      ),
    );
  }
}
