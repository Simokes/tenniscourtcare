import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tenniscourtcare/domain/entities/terrain.dart';
import 'package:tenniscourtcare/presentation/providers/terrain_provider.dart';
import 'package:google_fonts/google_fonts.dart';

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
              return _buildCourtItem(context, terrain);
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

  Widget _buildCourtItem(BuildContext context, Terrain terrain) {
    final status = terrain.status;
    Color statusColor;
    Color statusTextColor;
    String statusText;

    switch (status) {
      case TerrainStatus.playable:
        statusColor = Colors.green.shade100;
        statusTextColor = Colors.green.shade800;
        statusText = 'PLAYABLE';
        break;
      case TerrainStatus.maintenance:
        statusColor = Colors.blue.shade100;
        statusTextColor = Colors.blue.shade800;
        statusText = 'MAINTENANCE';
        break;
      case TerrainStatus.unavailable:
        statusColor = Colors.red.shade100;
        statusTextColor = Colors.red.shade800;
        statusText = 'UNAVAILABLE';
        break;
      case TerrainStatus.frozen:
        statusColor = Colors.cyan.shade100;
        statusTextColor = Colors.cyan.shade800;
        statusText = 'FROZEN';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
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
                  _getStatusDescription(status),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusText,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: statusTextColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusDescription(TerrainStatus status) {
    switch (status) {
      case TerrainStatus.playable:
        return 'Available now';
      case TerrainStatus.maintenance:
        return 'Under maintenance';
      case TerrainStatus.unavailable:
        return 'Temporarily closed';
      case TerrainStatus.frozen:
        return 'Frozen / Unplayable';
    }
  }
}
