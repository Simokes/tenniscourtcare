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

    // Logic extracted to local variables for clarity
    final isLow = item.isLowOnStock;
    final timeAgo = _formatUpdatedAt(item.updatedAt);
    final iconData = _getIconForName(item.name);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          // Use error color if low, otherwise a subtle border for definition
          color: isLow
              ? colorScheme.error.withValues(alpha: 0.5)
              : colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _openEditSheet(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildLeadingIcon(colorScheme, iconData, isLow),
              const SizedBox(width: 16),
              Expanded(
                child: _buildItemDetails(theme, colorScheme, isLow, timeAgo),
              ),
              _buildQuantityControl(context, ref, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingIcon(ColorScheme colorScheme, IconData icon, bool isLow) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isLow ? colorScheme.errorContainer : colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: isLow ? colorScheme.onErrorContainer : colorScheme.onPrimaryContainer,
        size: 20,
      ),
    );
  }

  Widget _buildItemDetails(ThemeData theme, ColorScheme colorScheme, bool isLow, String timeAgo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                item.name,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isLow) _buildLowStockBadge(theme, colorScheme),
          ],
        ),
        if (item.comment?.isNotEmpty ?? false)
          Text(
            item.comment!,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        Text(
          'Màj $timeAgo',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.disabledColor,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildLowStockBadge(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
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
    );
  }

  Widget _buildQuantityControl(BuildContext context, WidgetRef ref, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _quantityButton(
            icon: Icons.remove,
            color: colorScheme.onSurfaceVariant,
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.read(stockNotifierProvider.notifier).adjustQuantity(item, -1);
            },
          ),
          InkWell(
            onTap: () => _showQuantityDialog(context, ref),
            borderRadius: BorderRadius.circular(4),
            child: Container(
              constraints: const BoxConstraints(minWidth: 44),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Column(
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
                    style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          _quantityButton(
            icon: Icons.add,
            color: colorScheme.primary,
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.read(stockNotifierProvider.notifier).adjustQuantity(item, 1);
            },
          ),
        ],
      ),
    );
  }

  Widget _quantityButton({required IconData icon, required Color color, required VoidCallback onPressed}) {
    return IconButton(
      icon: Icon(icon, size: 18),
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(),
      color: color,
      onPressed: onPressed,
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
    if (lower.contains('eau') || lower.contains('arros')) return Icons.water_drop;
    return Icons.inventory_2;
  }

  String _formatUpdatedAt(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return "à l'instant";
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    return DateFormat('dd/MM').format(dt);
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
      ref.read(stockNotifierProvider.notifier).updateItem(
        item.copyWith(
          quantity: newValue,
          updatedAt: DateTime.now(),
        ),
      );
    }
    Navigator.pop(context);
  }
}