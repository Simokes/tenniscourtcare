import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tenniscourtcare/domain/entities/terrain.dart';
import 'package:tenniscourtcare/features/terrain/providers/terrain_provider.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final currentEvents = ref.watch(currentEventsProvider);
    final todayMaintenances = ref.watch(todayPlannedMaintenancesProvider);

    final todayTerrainMaintenances = todayMaintenances
        .where((m) => m.terrainId == terrain.id)
        .toList();
    final terrainEvents = currentEvents
        .where((e) => e.terrainIds.contains(terrain.id))
        .toList();

    Color leftBorderColor = Colors.grey.shade300;
    String subtitle = 'Disponible';
    Widget? actionWidget;

    if (terrain.status == TerrainStatus.maintenance) {
      leftBorderColor = Colors.blue;
      subtitle = '🔧 En maintenance';

      if (todayTerrainMaintenances.isNotEmpty) {
        final m = todayTerrainMaintenances.first;
        final start = TimeOfDay(hour: m.startHour, minute: 0).format(context);
        final end = TimeOfDay(hour: m.startHour + (m.durationMinutes ~/ 60), minute: m.durationMinutes % 60).format(context);
        subtitle = 'Maintenance • $start → $end';
        actionWidget = IconButton(
          icon: const Icon(Icons.check_circle_outline, color: Colors.green),
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
    } else if (terrainEvents.isNotEmpty) {
      final e = terrainEvents.first;
      leftBorderColor = Color(e.color);
      subtitle = '🎾 ${e.title} en cours';
    } else if (terrain.status == TerrainStatus.playable) {
      leftBorderColor = Colors.green;
      if (todayTerrainMaintenances.isNotEmpty) {
        final m = todayTerrainMaintenances.first;
        final start = TimeOfDay(hour: m.startHour, minute: 0).format(context);
        subtitle = '📅 Maintenance prévue à $start';
      }
    } else if (terrain.status == TerrainStatus.frozen) {
      leftBorderColor = Colors.cyan;
      subtitle = '❄️ Gelé';
    } else if (terrain.status == TerrainStatus.unavailable) {
      leftBorderColor = Colors.red;
      subtitle = '❌ Indisponible';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.only(right: 12, top: 12, bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              color: leftBorderColor,
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
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
              image: terrain.photoUrl != null
                  ? DecorationImage(
                      image: NetworkImage(terrain.photoUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: terrain.photoUrl == null
                ? const Icon(Icons.sports_tennis, color: Colors.grey)
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
                    color: Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          if (actionWidget != null) actionWidget,
          IconButton(
            icon: const Icon(Icons.add, size: 20, color: Colors.grey),
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
