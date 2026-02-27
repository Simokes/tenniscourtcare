import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tenniscourtcare/domain/entities/stock_item.dart';
import 'package:tenniscourtcare/presentation/providers/stock_provider.dart';
import 'add_edit_stock_item_sheet.dart';

class StockItemTile extends ConsumerWidget {
  final StockItem item;

  const StockItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
  
   
    final isLow = item.isLowOnStock;
    final iconData = _getIconForName(item.name);

    return InkWell(
      onTap: () => _openEditSheet(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isLow ? Colors.red.shade100 : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                iconData,
                color: isLow ? Colors.red.shade600 : Colors.blue.shade800,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            // Text Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isLow ? Colors.red.shade800 : Colors.grey.shade900,
                    ),
                  ),
                  if (item.comment != null && item.comment!.isNotEmpty)
                    Text(
                      item.comment!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isLow
                            ? Colors.red.shade400
                            : Colors.grey.shade500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else if (isLow)
                    Text(
                      'Stock Critique',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                        color: Colors.red.shade600,
                      ),
                    )
                  else
                    Text(
                      item.category ?? 'Autre',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                ],
              ),
            ),

            // Quantity Input
            Container(
              width: 70,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isLow ? Colors.red.shade200 : Colors.grey.shade300,
                ),
              ),
              child: InkWell(
                onTap: () => _showQuantityDialog(context, ref),
                borderRadius: BorderRadius.circular(8),
                child: Center(
                  child: Text(
                    '${item.quantity}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isLow
                          ? Colors.red.shade600
                          : Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Methods ---

  void _openEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddEditStockItemSheet(item: item),
    );
  }

  IconData _getIconForName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('ball')) return Icons.sports_baseball;
    if (lower.contains('filet')) return Icons.grid_4x4;
    if (lower.contains('peint')) return Icons.format_paint;
    if (lower.contains('balai') || lower.contains('bross')) return Icons.brush;
    if (lower.contains('manto') || lower.contains('sotto')) return Icons.layers;
    if (lower.contains('silice')) return Icons.grain;
    if (lower.contains('eau') || lower.contains('arros')) {
      return Icons.water_drop;
    }
    if (lower.contains('chaux')) return Icons.grass;
    if (lower.contains('algicide')) return Icons.science;
    return Icons.inventory_2;
  }

  void _showQuantityDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: item.quantity.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier la quantité'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: false),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Quantité (${item.unit})',
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (val) => _handleDialogSubmit(context, ref, val),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => _handleDialogSubmit(context, ref, controller.text),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  void _handleDialogSubmit(BuildContext context, WidgetRef ref, String value) {
    final newValue = int.tryParse(value);
    if (newValue != null && newValue >= 0) {
      ref
          .read(stockNotifierProvider.notifier)
          .updateItem(
            item.copyWith(quantity: newValue, updatedAt: DateTime.now()),
          );
    }
    Navigator.pop(context);
  }
}
