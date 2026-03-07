import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tenniscourtcare/core/theme/dashboard_theme_extension.dart';
import 'package:tenniscourtcare/features/inventory/providers/stock_provider.dart';

class StockAlertCard extends ConsumerWidget {
  const StockAlertCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lowStockItems = ref.watch(lowStockItemsProvider);
    final criticalItems = ref.watch(criticalStockItemsProvider);
    final allStockAsync = ref.watch(stockItemsProvider);

    return allStockAsync.when(
      data: (allItems) {
        if (lowStockItems.isEmpty) return const SizedBox.shrink();

        final totalItemsCount = allItems.length;
        final safeTotal = totalItemsCount == 0 ? 1 : totalItemsCount;

        final criticalItemsCount = criticalItems.length;
        final isCritical = criticalItemsCount > 0;
        final topItem = lowStockItems.first;

        final dc = Theme.of(context).extension<DashboardColors>();

        // Colors
        final backgroundColor = isCritical
            ? dc?.dangerBgColor ?? Colors.red.shade50
            : dc?.warningBgColor ?? Colors.yellow.shade50;
        final borderColor = isCritical
            ? (dc?.dangerColor ?? Colors.red).withValues(alpha: 0.3)
            : (dc?.warningColor ?? Colors.yellow).withValues(alpha: 0.5);
        final iconBackgroundColor = isCritical
            ? dc?.dangerColor ?? Colors.red
            : dc?.warningColor ?? Colors.yellow;
        final titleColor = isCritical
            ? dc?.dangerColor ?? Colors.red
            : dc?.warningColor ?? Colors.yellow.shade900;
        final subtitleColor = isCritical
            ? dc?.dangerColor ?? Colors.red
            : dc?.warningColor ?? Colors.yellow.shade800;
        final progressColor = isCritical
            ? dc?.dangerColor ?? Colors.red
            : dc?.warningColor ?? Colors.yellow;
        final progressBackgroundColor = isCritical
            ? dc?.dangerBgColor ?? Colors.red.shade100
            : dc?.warningBgColor ?? Colors.yellow.shade100;

        final titleText =
            '${lowStockItems.length} ${isCritical ? "Critical Items" : "Low Stock Items"}';
        final subtitleText =
            'Top: ${topItem.name} (${topItem.quantity}/${topItem.minThreshold} ${topItem.unit})';

        final ratio = (lowStockItems.length / safeTotal).clamp(0.0, 1.0);

        return GestureDetector(
          onTap: () => context.push('/stock'),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconBackgroundColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titleText,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: titleColor,
                            ),
                          ),
                          Text(
                            subtitleText,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: subtitleColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(ratio * 100).toInt()}% of Inventory Affected',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                    Text(
                      'Review Stock',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: ratio,
                  backgroundColor: progressBackgroundColor,
                  color: progressColor,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}
