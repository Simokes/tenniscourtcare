import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/logic/stock_categorizer.dart';
import '../providers/stock_provider.dart';
import '../widgets/stock_item_tile.dart';
import '../widgets/add_edit_stock_item_sheet.dart';

class StockScreen extends ConsumerWidget {
  const StockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredItemsAsync = ref.watch(filteredStockItemsProvider);
    final currentFilter = ref.watch(stockFilterProvider);
    // ignore: unused_local_variable
    final searchQuery = ref.watch(stockSearchQueryProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: CustomScrollView(
        slivers: [
          // Premium SliverAppBar
          SliverAppBar(
            pinned: true,
            floating: true,
            expandedHeight: 140,
            title: const Text(
              'Gestion du Stock',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.shade800,
                      Colors.orange.shade500,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      bottom: -20,
                      child: Icon(
                        Icons.inventory_2,
                        size: 150,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  onChanged: (v) => ref.read(stockSearchQueryProvider.notifier).state = v,
                ),
              ),
            ),
          ),

          // Filters Sticky Header
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Tous',
                    isSelected: currentFilter == StockFilter.all,
                    onTap: () => ref.read(stockFilterProvider.notifier).state = StockFilter.all,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'En alerte',
                    isSelected: currentFilter == StockFilter.lowStock,
                    isAlert: true,
                    onTap: () => ref.read(stockFilterProvider.notifier).state = StockFilter.lowStock,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Fixes',
                    isSelected: currentFilter == StockFilter.fixed,
                    onTap: () => ref.read(stockFilterProvider.notifier).state = StockFilter.fixed,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Personnalisés',
                    isSelected: currentFilter == StockFilter.custom,
                    onTap: () => ref.read(stockFilterProvider.notifier).state = StockFilter.custom,
                  ),
                ],
              ),
            ),
          ),

          // Content
          ...filteredItemsAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return [
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun article trouvé',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  )
                ];
              }

              // Group items
              final groups = StockCategorizer.groupItems(items);

              final order = [
                StockCategorizer.materiaux,
                StockCategorizer.produitsEntretien,
                StockCategorizer.fournitureMaintenance,
                StockCategorizer.autres,
              ];

              return order.where((key) => groups.containsKey(key)).expand((key) {
                final groupItems = groups[key]!;
                return [
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _StockGroupHeaderDelegate(title: key),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => StockItemTile(item: groupItems[index]),
                      childCount: groupItems.length,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                ];
              }).toList();
            },
            loading: () => [const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))],
            error: (e, s) => [SliverFillRemaining(child: Center(child: Text('Erreur: $e')))],
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const AddEditStockItemSheet(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
        backgroundColor: Colors.orange.shade700,
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isAlert;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.isAlert = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isAlert ? Colors.red : Colors.orange;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color.shade900 : Colors.grey.shade700,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _StockGroupHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;

  _StockGroupHeaderDelegate({required this.title});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.grey.shade100, // Background matching scaffold to hide scroll
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.orange.shade700,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 40.0;

  @override
  double get minExtent => 40.0;

  @override
  bool shouldRebuild(covariant _StockGroupHeaderDelegate oldDelegate) {
    return oldDelegate.title != title;
  }
}
