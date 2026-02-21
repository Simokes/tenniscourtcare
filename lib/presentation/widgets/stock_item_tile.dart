import 'package:flutter/material.dart';
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
    final isLow = item.isLowOnStock;
    final timeAgo = _formatUpdatedAt(item.updatedAt);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isLow ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isLow ? BorderSide(color: theme.colorScheme.error, width: 2) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(item.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          if (isLow) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: theme.colorScheme.error, borderRadius: BorderRadius.circular(4)),
                              child: Text('BAS', style: theme.textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      if (item.comment != null && item.comment!.isNotEmpty)
                        Text(item.comment!, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('MAJ $timeAgo', style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey)),
                    ],
                  ),
                ),
                _buildQuantityControl(ref, theme),
                _buildPopupMenu(context, ref),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityControl(WidgetRef ref, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, size: 20),
            onPressed: () => ref.read(stockNotifierProvider.notifier).adjustQuantity(item, -1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              children: [
                Text('${item.quantity}', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: item.isLowOnStock ? theme.colorScheme.error : null)),
                Text(item.unit, style: theme.textTheme.labelSmall),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 20),
            onPressed: () => ref.read(stockNotifierProvider.notifier).adjustQuantity(item, 1),
          ),
        ],
      ),
    );
  }

  Widget _buildPopupMenu(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'edit') {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => AddEditStockItemSheet(item: item),
          );
        } else if (value == 'delete') {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Supprimer ?'),
              content: Text('Voulez-vous vraiment supprimer "${item.name}" ?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
              ],
            ),
          );
          if (confirm == true) {
            ref.read(stockNotifierProvider.notifier).deleteItem(item.id!);
          }
        } else if (value == 'add5') {
          ref.read(stockNotifierProvider.notifier).adjustQuantity(item, 5);
        } else if (value == 'sub5') {
          ref.read(stockNotifierProvider.notifier).adjustQuantity(item, -5);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'add5', child: Text('+5')),
        const PopupMenuItem(value: 'sub5', child: Text('-5')),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'edit', child: Text('Modifier')),
        if (item.isCustom)
          const PopupMenuItem(value: 'delete', child: Text('Supprimer', style: TextStyle(color: Colors.red))),
      ],
    );
  }

  String _formatUpdatedAt(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'à l\'instant';
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    return DateFormat('dd/MM HH:mm').format(dt);
  }
}
