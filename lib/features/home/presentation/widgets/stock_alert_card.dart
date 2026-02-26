import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tenniscourtcare/presentation/providers/stock_provider.dart';

class StockAlertCard extends ConsumerWidget {
  const StockAlertCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lowStockAsync = ref.watch(lowStockItemsProvider);
    final criticalAsync = ref.watch(criticalStockItemsProvider);
    final allStockAsync = ref.watch(stockProvider);

    return lowStockAsync.when(
      data: (lowStockItems) {
        if (lowStockItems.isEmpty) return const SizedBox.shrink();

        final totalItemsCount = allStockAsync.asData?.value.length ?? 1;
        final safeTotal = totalItemsCount == 0 ? 1 : totalItemsCount;

        final criticalItemsCount = criticalAsync.asData?.value.length ?? 0;
        final isCritical = criticalItemsCount > 0;
        final topItem = lowStockItems.first;

        // Colors
        final backgroundColor = isCritical
            ? const Color(0xFFFEF2F2)
            : const Color(0xFFFEFCE8);
        final borderColor = isCritical
            ? const Color(0xFFFECACA)
            : const Color(0xFFFEF08A);
        final iconBackgroundColor = isCritical
            ? const Color(0xFFEF4444)
            : const Color(0xFFEAB308);
        final titleColor = isCritical
            ? const Color(0xFF7F1D1D)
            : const Color(0xFF713F12);
        final subtitleColor = isCritical
            ? const Color(0xFFB91C1C)
            : const Color(0xFF854D0E);
        final progressColor = isCritical
            ? const Color(0xFFDC2626)
            : const Color(0xFFCA8A04);
        final progressBackgroundColor = isCritical
            ? const Color(0xFFFECACA)
            : const Color(0xFFFEF08A);

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
