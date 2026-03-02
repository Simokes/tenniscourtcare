import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tenniscourtcare/domain/logic/stock_categorizer.dart';
import 'package:tenniscourtcare/domain/entities/stock_item.dart';
import 'package:tenniscourtcare/presentation/providers/stock_provider.dart';
import 'package:tenniscourtcare/presentation/widgets/sync_status_indicator.dart';
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
    final filteredItemsAsync = ref.watch(filteredStockItemsProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
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
                  fillColor: Colors.white,
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
              child: filteredItemsAsync.when(
                data: (items) => _buildStockList(items),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Erreur: $e')),
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
              backgroundColor: Colors.white,
              shape: const CircleBorder(),
            ),
          ),
          const Expanded(
            child: Text(
              'Inventaire',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
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
                  backgroundColor: Colors.white,
                  shape: const CircleBorder(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const AddEditStockItemSheet(),
                ),
                icon: const Icon(Icons.add, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF003580), // Primary Blue
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
        child: Text(
          'Aucun article trouvé',
          style: TextStyle(color: Colors.grey.shade600),
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
            color: Colors.grey.shade600,
          ),
        ),
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        children: items.map((item) => StockItemTile(item: item)).toList(),
      ),
    );
  }
}
