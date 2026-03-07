import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tenniscourtcare/features/inventory/providers/stock_provider.dart';
import './add_edit_stock_item_sheet.dart';
import 'package:tenniscourtcare/core/theme/dashboard_theme_extension.dart';


class StockAlertSection extends ConsumerWidget {
  const StockAlertSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final criticalItems = ref.watch(criticalStockItemsProvider);
    final stockAsync = ref.watch(stockItemsProvider);

    return stockAsync.when(
      data: (_) {
        if (criticalItems.isEmpty) return const SizedBox.shrink();


        final dc = Theme.of(context).extension<DashboardColors>();

        // Take the first item (most critical as it is sorted by quantity)
        final item = criticalItems.first;
        final otherCount = criticalItems.length - 1;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Alertes Critiques',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: dc?.dangerBgColor ?? Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: (dc?.dangerColor ?? Colors.red).withValues(alpha: 0.3)),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.warning_rounded,
                                color: dc?.dangerColor ?? Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: TextStyle(
                                    color: dc?.dangerColor ?? Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Stock dangereusement bas. Plus que ${item.quantity} ${item.unit} disponible${item.quantity > 1 ? 's' : ''}.',
                            style: TextStyle(
                              color: dc?.dangerColor ?? Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (otherCount > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '+ $otherCount autre${otherCount > 1 ? 's' : ''} article${otherCount > 1 ? 's' : ''} critique${otherCount > 1 ? 's' : ''}',
                                style: TextStyle(
                                  color: dc?.dangerColor ?? Colors.red,
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => AddEditStockItemSheet(item: item),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: dc?.dangerColor ?? Colors.red,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 0,
                        ),
                        minimumSize: const Size(0, 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Réapprovisionner',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
    );
  }
}
