import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class StockAlertCard extends ConsumerWidget {
  final AsyncValue<int> stockAlertCount;

  const StockAlertCard({super.key, required this.stockAlertCount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return stockAlertCount.when(
      data: (count) {
        if (count == 0) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2), // Red 50
            border: Border.all(color: const Color(0xFFFECACA)), // Red 200
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
                      color: const Color(0xFFEF4444), // Red 500
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
                          'Stock Alert: Clay Lime',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF7F1D1D), // Red 900
                          ),
                        ),
                        Text(
                          'Inventory is below 10% threshold.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFFB91C1C), // Red 700
                          ),
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
                    '8% Remaining',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF7F1D1D),
                    ),
                  ),
                  Text(
                    'Reorder Promptly',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF7F1D1D),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: 0.08,
                backgroundColor: const Color(0xFFFECACA), // Red 200
                color: const Color(0xFFDC2626), // Red 600
                minHeight: 6,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
