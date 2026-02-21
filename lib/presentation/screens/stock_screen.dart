import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/logic/stock_categorizer.dart';
import '../../domain/entities/stock_item.dart';
import '../providers/stock_provider.dart';
import '../widgets/stock_item_tile.dart';
import '../widgets/add_edit_stock_item_sheet.dart';

class StockScreen extends ConsumerStatefulWidget {
  const StockScreen({super.key});

  @override
  ConsumerState<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends ConsumerState<StockScreen> {
  bool _isReorderMode = false;

  @override
  Widget build(BuildContext context) {
    final filteredItemsAsync = ref.watch(filteredStockItemsProvider);
    final currentFilter = ref.watch(stockFilterProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: CustomScrollView(
        slivers: [
          // AppBar
          SliverAppBar(
            pinned: true,
            floating: true,
            expandedHeight: 140,
            title: const Text(
              'Gestion du Stock',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: Icon(_isReorderMode ? Icons.check : Icons.sort),
                tooltip: _isReorderMode ? 'Terminer' : 'Réorganiser',
                onPressed: () {
                  setState(() {
                    _isReorderMode = !_isReorderMode;
                  });
                },
              ),
            ],
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
                child: _isReorderMode
                    ? Container(
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          'Mode réorganisation activé',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : TextField(
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

          // Filters (Hide in reorder mode)
          if (!_isReorderMode)
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
          filteredItemsAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'Aucun article trouvé',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                );
              }

              // Group items
              // Use category field if present, else fallback to categorizer
              final Map<String, List<StockItem>> groups = {};
              for (var item in items) {
                final cat = item.category ?? StockCategorizer.getCategory(item);
                groups.putIfAbsent(cat, () => []).add(item);
              }

              // Sort items within groups by sortOrder
              for (var key in groups.keys) {
                groups[key]!.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
              }

              final order = [
                StockCategorizer.materiaux,
                StockCategorizer.produitsEntretien,
                StockCategorizer.fournitureMaintenance,
                StockCategorizer.autres,
              ];
              // Add any custom categories found that aren't in the default list
              for (var key in groups.keys) {
                if (!order.contains(key)) order.add(key);
              }

              if (_isReorderMode) {
                // Flatten list for ReorderableList, but keep headers as non-draggable items?
                // ReorderableListView in Sliver is tricky.
                // Alternative: Single SliverList where each item is draggable?
                // Or just show a non-sliver ReorderableListView for the whole body content?
                // Let's use a simpler approach: Show groups, allow reorder WITHIN groups.

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final key = order.where((k) => groups.containsKey(k)).toList()[index];
                      final groupItems = groups[key]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _StockGroupHeader(title: key),
                          // Use a ReorderableListView inside a constrained box or just custom drag targets?
                          // Standard ReorderableListView needs to scroll.
                          // Let's try visual reordering: just list them with a drag handle icon visually
                          // but since we can't easily implement drag-drop across slivers without complex lib,
                          // we might fallback to just showing the list.
                          // Actually, "reorder groups" + "reorder items in groups" is best done
                          // by just listing everything.
                          // Let's use ReorderableListView.builder for the whole list? No, grouped.

                          // Pragmatic solution for "Reorder Mode":
                          // Render a generic list where items can be moved.
                          // If moved to a new position, we calculate new sortOrder.

                          ReorderableListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: groupItems.length,
                            onReorder: (oldIndex, newIndex) {
                              if (oldIndex < newIndex) newIndex -= 1;
                              final item = groupItems.removeAt(oldIndex);
                              groupItems.insert(newIndex, item);

                              // Update DB logic
                              ref.read(stockNotifierProvider.notifier).reorderItems(groupItems);
                            },
                            itemBuilder: (context, i) {
                              final item = groupItems[i];
                              return Card(
                                key: ValueKey(item.id),
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                child: ListTile(
                                  leading: const Icon(Icons.drag_handle),
                                  title: Text(item.name),
                                  trailing: Text('${item.quantity} ${item.unit}'),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                    childCount: order.where((k) => groups.containsKey(k)).length,
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final keys = order.where((k) => groups.containsKey(k)).toList();
                    if (index >= keys.length) return null;

                    final key = keys[index];
                    final groupItems = groups[key]!;

                    return Column(
                      children: [
                        // Let's use the 'sticky header' style manually:
                        _StockGroupHeader(title: key),
                        ...groupItems.map((item) => StockItemTile(item: item)),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                  childCount: order.where((k) => groups.containsKey(k)).length,
                ),
              );
            },
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (e, s) => SliverFillRemaining(child: Center(child: Text('Erreur: $e'))),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: !_isReorderMode ? FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const AddEditStockItemSheet(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
        backgroundColor: Colors.orange.shade700,
      ) : null,
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

class _StockGroupHeader extends StatelessWidget {
  final String title;
  const _StockGroupHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
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
}
