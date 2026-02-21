import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/stock_provider.dart';
import '../widgets/stock_item_tile.dart';
import '../widgets/add_edit_stock_item_sheet.dart';

class StockScreen extends ConsumerWidget {
  const StockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredItemsAsync = ref.watch(filteredStockItemsProvider);
    final currentFilter = ref.watch(stockFilterProvider);
    final searchQuery = ref.watch(stockSearchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion du Stock'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context, ref),
          ),
          PopupMenuButton<StockFilter>(
            icon: const Icon(Icons.filter_list),
            initialValue: currentFilter,
            onSelected: (filter) => ref.read(stockFilterProvider.notifier).state = filter,
            itemBuilder: (context) => [
              const PopupMenuItem(value: StockFilter.all, child: Text('Tous')),
              const PopupMenuItem(value: StockFilter.fixed, child: Text('Fixes')),
              const PopupMenuItem(value: StockFilter.custom, child: Text('Personnalisés')),
              const PopupMenuItem(value: StockFilter.lowStock, child: Text('En alerte')),
            ],
          ),
        ],
      ),
      body: filteredItemsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Aucun article trouvé'));
          }

          final fixedItems = items.where((i) => !i.isCustom).toList();
          final customItems = items.where((i) => i.isCustom).toList();

          return ListView(
            children: [
              if (fixedItems.isNotEmpty) ...[
                _buildHeader(context, 'Articles fixes', Icons.lock_outline),
                ...fixedItems.map((item) => StockItemTile(item: item)),
              ],
              if (customItems.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildHeader(context, 'Articles personnalisés', Icons.person_outline),
                ...customItems.map((item) => StockItemTile(item: item)),
              ],
              const SizedBox(height: 80), // Espace pour le FAB
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const AddEditStockItemSheet(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechercher'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nom de l\'article...'),
          onChanged: (v) => ref.read(stockSearchQueryProvider.notifier).state = v,
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(stockSearchQueryProvider.notifier).state = '';
              Navigator.pop(context);
            },
            child: const Text('Réinitialiser'),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }
}
