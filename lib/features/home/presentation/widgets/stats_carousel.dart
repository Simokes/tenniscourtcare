import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../providers/dashboard_providers.dart';
import '../../../inventory/providers/stock_provider.dart';
import 'package:tenniscourtcare/core/theme/dashboard_theme_extension.dart';

class StatsCarousel extends ConsumerWidget {
  const StatsCarousel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dc = Theme.of(context).extension<DashboardColors>()!;
    final stats = ref.watch(operationalTerrainsStatsProvider);
    final todayMaintenanceAsync = ref.watch(todayMaintenanceCountProvider);
    final lowStockCount = ref.watch(lowStockCountProvider);

    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          _buildStatCard(
            context,
            dc: dc,
            icon: Icons.check_circle,
            iconColor: Theme.of(context).colorScheme.primary,
            value: stats.total == 0
                ? '-'
                : '${stats.playable}/${stats.total}',
            label: 'Opérationnels',
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            context,
            dc: dc,
            icon: Icons.construction,
            iconColor: dc.maintenanceColor,
            value: todayMaintenanceAsync.when(
              data: (val) => '$val',
              loading: () => '-',
              error: (_, _) => '!',
            ),
            label: 'Maintenances',
            onTap: () => context.push('/maintenance'),
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            context,
            dc: dc,
            icon: Icons.inventory_2,
            iconColor: lowStockCount > 0 ? dc.dangerColor : dc.stockColor,
            value: '$lowStockCount',
            label: 'Stocks bas',
            onTap: () => context.push('/stock'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required DashboardColors dc,
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Flexible(
              child: Text(
                label.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
