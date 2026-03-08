import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tenniscourtcare/core/theme/dashboard_theme_extension.dart';
import 'package:tenniscourtcare/features/maintenance/providers/maintenance_provider.dart';
import 'package:tenniscourtcare/core/providers/connectivity_providers.dart';

/// Bandeau d alertes fusionne : affiche overdue maintenances et/ou statut offline.
/// Priorite : overdue + offline > overdue seul > offline seul > masque.
class AlertStrip extends ConsumerWidget {
  const AlertStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overdueCount = ref.watch(overdueCountProvider);
    final isOnline = ref.watch(isOnlineStatusProvider).valueOrNull ?? true;

    if (overdueCount == 0 && isOnline) {
      return const SizedBox.shrink();
    }

    final dc = Theme.of(context).extension<DashboardColors>()!;
    final cs = Theme.of(context).colorScheme;

    final isDanger = overdueCount > 0;
    final backgroundColor = isDanger ? dc.dangerColor : cs.surfaceContainerHighest;
    final iconColor = isDanger ? Colors.white : cs.onSurfaceVariant;
    final textColor = isDanger ? Colors.white : cs.onSurfaceVariant;

    String text;
    if (overdueCount > 0 && !isOnline) {
      text = '$overdueCount en retard - Hors ligne';
    } else if (overdueCount > 0) {
      text = '$overdueCount maintenance(s) en retard';
    } else {
      text = 'Hors ligne - Mode lecture seule';
    }

    return GestureDetector(
      onTap: () {
        if (overdueCount > 0) {
          context.go('/maintenance');
        }
      },
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: backgroundColor,
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 16,
              color: iconColor,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
