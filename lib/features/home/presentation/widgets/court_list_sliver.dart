import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tenniscourtcare/domain/entities/terrain.dart';
import 'package:tenniscourtcare/domain/entities/app_event.dart';
import 'package:tenniscourtcare/domain/entities/maintenance.dart';
import 'package:tenniscourtcare/features/terrain/providers/terrain_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tenniscourtcare/core/theme/dashboard_theme_extension.dart';
import '../../../maintenance/presentation/widgets/add_maintenance_sheet.dart';
import '../../providers/dashboard_providers.dart';

class CourtListSliver extends ConsumerWidget {
  const CourtListSliver({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final terrainsAsync = ref.watch(terrainsProvider);

    return terrainsAsync.when(
      data: (terrains) {
        if (terrains.isEmpty) {
          return const SliverToBoxAdapter(
            child: Center(child: Text('No courts available.')),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.only(left: 24, right: 24, bottom: 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final terrain = terrains[index];
              return _buildCourtItem(context, ref, terrain);
            }, childCount: terrains.length),
          ),
        );
      },
      loading: () => const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, s) =>
          SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
    );
  }

  Widget _buildCourtItem(BuildContext context, WidgetRef ref, Terrain terrain) {
    final cs = Theme.of(context).colorScheme;
    final dc = Theme.of(context).extension<DashboardColors>();

    final currentEvents = ref.watch(currentEventsProvider);
    final todayMaintenances = ref.watch(todayPlannedMaintenancesProvider);

    final todayTerrainMaintenances = todayMaintenances
        .where((m) => m.terrainId == terrain.id)
        .toList();
    final terrainEvents = currentEvents
        .where((e) => e.terrainIds.contains(terrain.id))
        .toList();

    final statusDisplay = _CourtStatusDisplay.resolve(
      terrain: terrain,
      todayMaintenances: todayTerrainMaintenances,
      currentEvents: terrainEvents,
      context: context,
    );

    Widget? actionWidget;

    if (terrain.status == TerrainStatus.maintenance && todayTerrainMaintenances.isNotEmpty) {
      final m = todayTerrainMaintenances.first;
      actionWidget = IconButton(
        icon: Icon(Icons.check_circle_outline, color: dc?.successColor ?? Colors.green),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => AddMaintenanceSheet(
              terrain: terrain,
              existingMaintenance: m,
              forceCompleteMode: true,
            ),
          );
        },
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.only(right: 12, top: 12, bottom: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: cs.onSurface.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 56,
            decoration: BoxDecoration(
              color: statusDisplay.color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              image: terrain.photoUrl != null
                  ? DecorationImage(
                      image: NetworkImage(terrain.photoUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: terrain.photoUrl == null
                ? Icon(Icons.sports_tennis, color: cs.onSurfaceVariant)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${terrain.nom} • ${terrain.type.name}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  statusDisplay.subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          ?actionWidget,
          IconButton(
            icon: Icon(Icons.add, size: 20, color: cs.onSurfaceVariant),
            tooltip: 'Maintenance urgente',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => AddMaintenanceSheet(
                  terrain: terrain,
                  urgentMode: true,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CourtStatusDisplay {
  final Color color;
  final String subtitle;

  const _CourtStatusDisplay({required this.color, required this.subtitle});

  static _CourtStatusDisplay resolve({
    required Terrain terrain,
    required List<Maintenance> todayMaintenances,
    required List<AppEvent> currentEvents,
    required BuildContext context,
  }) {
    final cs = Theme.of(context).colorScheme;
    final dc = Theme.of(context).extension<DashboardColors>();

    if (terrain.status == TerrainStatus.maintenance) {
      if (todayMaintenances.isNotEmpty) {
        final m = todayMaintenances.first;
        final start = TimeOfDay(hour: m.startHour, minute: 0).format(context);
        final end = TimeOfDay(
          hour: m.startHour + (m.durationMinutes ~/ 60),
          minute: m.durationMinutes % 60,
        ).format(context);
        return _CourtStatusDisplay(
          color: dc?.maintenanceColor ?? Colors.blue,
          subtitle: 'Maintenance · $start → $end',
        );
      }
      return _CourtStatusDisplay(
        color: dc?.maintenanceColor ?? Colors.blue,
        subtitle: 'En maintenance',
      );
    }
    if (currentEvents.isNotEmpty) {
      return _CourtStatusDisplay(
        color: Color(currentEvents.first.color),
        subtitle: '${currentEvents.first.title} en cours',
      );
    }
    if (terrain.status == TerrainStatus.playable) {
      if (todayMaintenances.isNotEmpty) {
        final start = TimeOfDay(
          hour: todayMaintenances.first.startHour,
          minute: 0,
        ).format(context);
        return _CourtStatusDisplay(
          color: dc?.successColor ?? Colors.green,
          subtitle: 'Maintenance prévue à $start',
        );
      }
      return _CourtStatusDisplay(
        color: dc?.successColor ?? Colors.green,
        subtitle: 'Disponible',
      );
    }
    if (terrain.status == TerrainStatus.frozen) {
      return _CourtStatusDisplay(color: cs.secondary, subtitle: 'Gelé');
    }
    if (terrain.status == TerrainStatus.unavailable) {
      return _CourtStatusDisplay(
        color: dc?.dangerColor ?? Colors.red,
        subtitle: 'Indisponible',
      );
    }
    return _CourtStatusDisplay(
      color: cs.outlineVariant,
      subtitle: 'Disponible',
    );
  }
}
