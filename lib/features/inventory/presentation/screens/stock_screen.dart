import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tenniscourtcare/domain/logic/stock_categorizer.dart';
import 'package:tenniscourtcare/domain/entities/stock_item.dart';
import 'package:tenniscourtcare/features/inventory/providers/stock_provider.dart';
import 'package:tenniscourtcare/shared/widgets/common/sync_status_indicator.dart';
import '../widgets/stock_item_tile.dart';
import '../widgets/add_edit_stock_item_sheet.dart';
import '../widgets/stock_alert_section.dart';

class StockScreen extends ConsumerStatefulWidget {
  const StockScreen({super.key});

  @override
  ConsumerState<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends ConsumerState<StockScreen> {
  @override
  Widget build(BuildContext context) {
    final stockAsync = ref.watch(stockItemsProvider);
    final items = ref.watch(filteredStockItemsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header
            _buildHeader(context),

            // 2. Alert Section
            const StockAlertSection(),

            // 3. Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher un article...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                onChanged: (v) =>
                    ref.read(stockSearchQueryProvider.notifier).state = v,
              ),
            ),

            // 4. Content List
            Expanded(
              child: stockAsync.when(
                data: (_) => _buildStockList(items),
                loading: () => ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: List.generate(3, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      height: 72,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    );
                  }),
                ),
                error: (e, s) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_off_outlined, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(height: 12),
                      Text('Impossible de charger le stock', style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => ref.invalidate(stockItemsProvider),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: const CircleBorder(),
            ),
          ),
          Expanded(
            child: Text(
              'Inventaire',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Row(
            children: [
              const ConnectionStatusIndicator(mode: SyncIndicatorMode.minimal),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  // Check if the route exists as a top-level route or nested.
                  // Based on app_router.dart, it is nested under '/' as 'stock-history'.
                  // However, we are currently at '/stock'.
                  // Let's try absolute path if it was defined as top level, or relative.
                  // The router config shows:
                  // GoRoute(path: '/', ..., routes: [ GoRoute(path: 'stock-history', ...) ])
                  // So it is at /stock-history
                  context.push('/stock-history');
                },
                icon: const Icon(Icons.history),
                tooltip: 'Historique',
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  shape: const CircleBorder(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  showDragHandle: true,
                  builder: (_) => const AddEditStockItemSheet(),
                ),
                icon: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary, // Primary Blue
                  shape: const CircleBorder(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockList(List<StockItem> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 56, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'Aucun article trouvé',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Ajoutez votre premier article',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un article'),
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                showDragHandle: true,
                builder: (_) => const AddEditStockItemSheet(),
              ),
            ),
          ],
        ),
      );
    }

    // Group items
    final Map<String, List<StockItem>> groups = {};
    for (var item in items) {
      final cat = item.category ?? StockCategorizer.getCategory(item);
      groups.putIfAbsent(cat, () => []).add(item);
    }

    // Sort items within groups
    for (var key in groups.keys) {
      groups[key]!.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }

    // Define category order
    // Note: StockCategorizer.fournitureMaintenance ("Fourniture Maintenance") corresponds to "FOURNITURES DE COURT" in design?
    // StockCategorizer.produitsEntretien ("Produits d'entretien") matches design.
    // "ÉQUIPEMENT D'ENTRETIEN" in design -> Maybe StockCategorizer.materiaux?
    // I will use the domain constants but can map display names if needed.
    final order = [
      StockCategorizer.fournitureMaintenance,
      StockCategorizer.materiaux,
      StockCategorizer.produitsEntretien,
      StockCategorizer.autres,
    ];

    // Add custom categories found in data but not in default list
    for (var key in groups.keys) {
      if (!order.contains(key)) order.add(key);
    }

    // Filter to only active categories
    final activeCategories = order.where((k) => groups.containsKey(k)).toList();

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: activeCategories.length,
      itemBuilder: (context, index) {
        final category = activeCategories[index];
        final groupItems = groups[category]!;

        return _buildCategorySection(category, groupItems);
      },
    );
  }

  Widget _buildCategorySection(String category, List<StockItem> items) {
    // Map category names to uppercase as per design
    final displayTitle = category.toUpperCase();

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(
          displayTitle,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        children: items.map((item) => StockItemTile(item: item)).toList(),
      ),
    );
  }
}
