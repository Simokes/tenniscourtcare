import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tenniscourtcare/core/theme/dashboard_theme_extension.dart';
import 'package:tenniscourtcare/features/home/providers/dashboard_providers.dart';
import 'package:tenniscourtcare/features/inventory/providers/stock_provider.dart';

/// Bande de 3 indicateurs cles du dashboard (courts, maintenances, stock).
/// Remplace StatsCarousel avec une empreinte verticale reduite (48px vs 120px).
class KpiStrip extends ConsumerWidget {
  const KpiStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(operationalTerrainsStatsProvider);
    final todayMaintenanceAsync = ref.watch(todayMaintenanceCountProvider);
    final lowStockCount = ref.watch(lowStockCountProvider);

    final dc = Theme.of(context).extension<DashboardColors>()!;

    return SizedBox(
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: _KpiChip(
              icon: Icons.check_circle_outline,
              label: '${stats.playable}/${stats.total} courts',
              iconColor: Theme.of(context).colorScheme.primary,
              onTap: null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: todayMaintenanceAsync.when(
              data: (val) => _KpiChip(
                icon: Icons.construction,
                label: '$val maintenances',
                iconColor: dc.maintenanceColor,
                onTap: () => context.push('/maintenance'),
              ),
              loading: () => const _KpiChip(
                icon: Icons.construction,
                label: '-',
              ),
              error: (err, stack) => const _KpiChip(
                icon: Icons.construction,
                label: '!',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _KpiChip(
              icon: Icons.inventory_2,
              label: '$lowStockCount alerte(s)',
              iconColor: lowStockCount > 0
                  ? dc.dangerColor
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              onTap: () => context.go('/stock'),
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiChip extends StatelessWidget {
  const _KpiChip({
    required this.icon,
    required this.label,
    this.iconColor,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color? iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: iconColor ?? cs.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
