import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tenniscourtcare/data/database/stock_history_queries.dart';
import 'package:tenniscourtcare/core/providers/core_providers.dart';
import 'package:tenniscourtcare/shared/widgets/premium/premium_card.dart';
import 'package:tenniscourtcare/shared/widgets/common/sync_status_indicator.dart';
import 'package:tenniscourtcare/core/theme/dashboard_theme_extension.dart';


final stockHistoryProvider =
    StreamProvider.autoDispose<List<StockMovementWithDetails>>((ref) {
      final db = ref.watch(databaseProvider);
      return db.watchStockHistory(limit: 50); // Pagination could be added
    });

class StockHistoryScreen extends ConsumerStatefulWidget {
  const StockHistoryScreen({super.key});

  @override
  ConsumerState<StockHistoryScreen> createState() => _StockHistoryScreenState();
}

class _StockHistoryScreenState extends ConsumerState<StockHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(stockHistoryProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal des Stocks'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        tooltip: 'État de synchronisation',
        onPressed: () => _showSyncDetails(context),
        child: const Icon(Icons.sync),
      ),
      body: historyAsync.when(
        data: (movements) {
          if (movements.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: cs.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun mouvement enregistré',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: movements.length,
            itemBuilder: (context, index) {
              final item = movements[index];
              return _buildHistoryItem(context, item);
            },
          );
        },
        loading: () => ListView(
          padding: const EdgeInsets.all(16),
          children: List.generate(3, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
            );
          }),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_outlined, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(height: 12),
              Text('Impossible de charger le journal', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(stockHistoryProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSyncDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'État de synchronisation',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            const ConnectionStatusIndicator(mode: SyncIndicatorMode.detailed),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(
    BuildContext context,
    StockMovementWithDetails item,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final dc = theme.extension<DashboardColors>();
    final movement = item.movement;
    final isPositive = movement.quantityChange > 0;
    final changeColor = isPositive ? (dc?.successColor ?? Colors.green) : (dc?.dangerColor ?? Colors.red);
    final icon = isPositive
        ? Icons.add_circle_outline
        : Icons.remove_circle_outline;

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: changeColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: changeColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.itemName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        movement.reason,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isPositive ? '+' : ''}${movement.quantityChange}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: changeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Total: ${movement.newQuantity}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    movement.description ?? '',
                    style: theme.textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateFormat.format(movement.occurredAt),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                if (item.userName != null)
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 14,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.userName!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
