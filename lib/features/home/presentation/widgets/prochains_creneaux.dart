import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tenniscourtcare/core/theme/dashboard_theme_extension.dart';
import 'package:tenniscourtcare/features/home/providers/dashboard_providers.dart';

class _CreneauItem {
  final DateTime startTime;
  final String title;
  final bool isMaintenance;

  _CreneauItem({
    required this.startTime,
    required this.title,
    required this.isMaintenance,
  });
}

/// Bandeau compact affichant les 2 prochains creneaux du jour (maintenances et evenements).
/// Sources : todayPlannedMaintenancesProvider + todayUpcomingEventsProvider.
class ProchainsCreneaux extends ConsumerWidget {
  const ProchainsCreneaux({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maintenances = ref.watch(todayPlannedMaintenancesProvider);
    final events = ref.watch(todayUpcomingEventsProvider);

    final now = DateTime.now();

    final items = <_CreneauItem>[];

    for (final m in maintenances) {
      final date = DateTime.fromMillisecondsSinceEpoch(m.date);
      final startTime = DateTime(
        date.year,
        date.month,
        date.day,
        m.startHour,
      );

      if (startTime.isAfter(now)) {
        items.add(
          _CreneauItem(
            startTime: startTime,
            title: m.type.isNotEmpty ? m.type : (m.commentaire ?? 'Maintenance'),
            isMaintenance: true,
          ),
        );
      }
    }

    for (final e in events) {
      if (e.startTime.isAfter(now)) {
        items.add(
          _CreneauItem(
            startTime: e.startTime,
            title: e.title,
            isMaintenance: false,
          ),
        );
      }
    }

    items.sort((a, b) => a.startTime.compareTo(b.startTime));

    final topItems = items.take(2).toList();

    if (topItems.isEmpty) {
      return const SizedBox.shrink();
    }

    final cs = Theme.of(context).colorScheme;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: _buildItem(context, topItems[0])),
          if (topItems.length > 1) ...[
            const Text(' · '),
            Expanded(child: _buildItem(context, topItems[1])),
          ],
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, _CreneauItem item) {
    final heure = item.startTime.hour.toString().padLeft(2, '0');
    final minute = item.startTime.minute.toString().padLeft(2, '0');
    final dc = Theme.of(context).extension<DashboardColors>();
    final cs = Theme.of(context).colorScheme;
    final iconColor = item.isMaintenance
        ? (dc?.maintenanceColor ?? cs.secondary)
        : cs.secondary;

    return InkWell(
      onTap: () {
        if (item.isMaintenance) {
          context.push('/maintenance');
        } else {
          context.go('/calendar');
        }
      },
      borderRadius: BorderRadius.circular(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            item.isMaintenance ? Icons.construction : Icons.event,
            size: 14,
            color: iconColor,
          ),
          const SizedBox(width: 4),
          Text(
            '${heure}h$minute',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              item.title,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
