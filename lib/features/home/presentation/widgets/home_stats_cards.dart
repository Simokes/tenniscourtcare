import 'package:flutter/material.dart';
import 'package:tenniscourtcare/core/theme/dashboard_theme_extension.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeStatCard extends StatelessWidget {
  final String title;
  final AsyncValue<int> valueAsync;
  final IconData icon;
  final Color color;
  final bool isAlert;
  final VoidCallback onTap;

  const HomeStatCard({
    super.key,
    required this.title,
    required this.valueAsync,
    required this.icon,
    required this.color,
    this.isAlert = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final dc = Theme.of(context).extension<DashboardColors>();

    // Calcul de l'état d'alerte : si isAlert=true et valeur > 0
    final val = valueAsync.asData?.value ?? 0;
    final hasActiveAlert = isAlert && val > 0;

    // Couleurs dynamiques
    final effectiveColor = hasActiveAlert ? (dc?.dangerColor ?? Colors.red) : color;

    // BgColor
    Color bgColor;
    if (hasActiveAlert) {
      bgColor = isDark
          ? (dc?.dangerBgColor.withValues(alpha: 0.8) ?? Colors.red.withValues(alpha: 0.15))
          : (dc?.dangerBgColor ?? Colors.red.shade50);
    } else {
      bgColor =
          Theme.of(context).cardTheme.color ??
          (isDark ? cs.surfaceContainer : cs.surface);
    }

    final iconColor = hasActiveAlert
        ? (dc?.dangerColor ?? Colors.red)
        : color;

    return Card(
      elevation: 4,
      shadowColor: effectiveColor.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: bgColor,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                bgColor,
                effectiveColor.withValues(alpha: isDark ? 0.15 : 0.05),
              ],
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: iconColor, size: 28),
                  valueAsync.when(
                    data: (val) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: hasActiveAlert
                            ? (isDark
                                  ? (dc?.dangerColor.withValues(alpha: 0.2) ?? Colors.red.withValues(alpha: 0.2))
                                  : cs.surface)
                            : (isDark
                                  ? cs.onSurface.withValues(alpha: 0.15)
                                  : cs.surfaceContainerHighest),
                        borderRadius: BorderRadius.circular(12),
                        border: hasActiveAlert
                            ? Border.all(
                                color: dc?.dangerColor ?? Colors.red,
                              )
                            : null,
                      ),
                      child: Text(
                        '$val',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: hasActiveAlert
                              ? (dc?.dangerColor ?? Colors.red)
                              : Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),
                    loading: () => const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (error, stack) =>
                        const Icon(Icons.error_outline, size: 16),
                  ),
                ],
              ),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: hasActiveAlert
                      ? (dc?.dangerColor ?? Colors.red)
                      : cs.onSurface,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const HomeActionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.15 : 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
