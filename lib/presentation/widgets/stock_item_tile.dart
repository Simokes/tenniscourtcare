import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/stock_item.dart';
import '../providers/stock_provider.dart';
import 'add_edit_stock_item_sheet.dart';

class StockItemTile extends ConsumerWidget {
  final StockItem item;

  const StockItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLow = item.isLowOnStock;
    final timeAgo = _formatUpdatedAt(item.updatedAt);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: isLow ? Border.all(color: colorScheme.error.withValues(alpha: 0.5), width: 1) : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
             // Show edit on tap or menu? Let's do menu on long press or icon
             showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => AddEditStockItemSheet(item: item),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isLow ? colorScheme.errorContainer : colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIconForName(item.name),
                        color: isLow ? colorScheme.onErrorContainer : colorScheme.onPrimaryContainer,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  item.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isLow) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: colorScheme.error,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'BAS',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onError,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (item.comment != null && item.comment!.isNotEmpty)
                            Text(
                              item.comment!,
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          Text(
                            'Màj $timeAgo',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.grey.shade400,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildQuantityControl(ref, colorScheme, item),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityControl(WidgetRef ref, ColorScheme colorScheme, StockItem item) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
            color: colorScheme.onSurfaceVariant,
            onPressed: () => ref.read(stockNotifierProvider.notifier).adjustQuantity(item, -1),
          ),
          GestureDetector(
            onTap: () => _showQuantityDialog(context, ref, item),
            child: Container(
              constraints: const BoxConstraints(minWidth: 40),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${item.quantity}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: item.isLowOnStock ? colorScheme.error : colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    item.unit,
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
            color: colorScheme.primary,
            onPressed: () => ref.read(stockNotifierProvider.notifier).adjustQuantity(item, 1),
          ),
        ],
      ),
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
    if (lower.contains('eau') || lower.contains('arros')) return Icons.water_drop;
    return Icons.inventory_2;
  }

  String _formatUpdatedAt(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'à l\'instant';
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    return DateFormat('dd/MM').format(dt);
  }

  void _showQuantityDialog(BuildContext context, WidgetRef ref, StockItem item) {
    final controller = TextEditingController(text: item.quantity.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier la quantité'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Quantité (${item.unit})',
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (val) {
            final newValue = int.tryParse(val);
            if (newValue != null && newValue >= 0) {
              ref.read(stockNotifierProvider.notifier).updateItem(
                    item.copyWith(
                      quantity: newValue,
                      updatedAt: DateTime.now(),
                    ),
                  );
            }
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              final newValue = int.tryParse(controller.text);
              if (newValue != null && newValue >= 0) {
                ref.read(stockNotifierProvider.notifier).updateItem(
                      item.copyWith(
                        quantity: newValue,
                        updatedAt: DateTime.now(),
                      ),
                    );
              }
              Navigator.pop(context);
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }
}
