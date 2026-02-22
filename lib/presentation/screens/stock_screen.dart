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
                        color: Colors.white.withAlpha(40),
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
                          color: Colors.white.withAlpha(50),
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
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'Aucun article trouvé',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                );
              }

              // Group items
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

              final activeCategories = order.where((k) => groups.containsKey(k)).toList();

              if (_isReorderMode) {
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= activeCategories.length) return null;
                      final key = activeCategories[index];
                      final groupItems = groups[key]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _StockGroupHeader(title: key),
                          ReorderableListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: groupItems.length,
                            onReorder: (oldIndex, newIndex) {
                              if (oldIndex < newIndex) newIndex -= 1;
                              final item = groupItems.removeAt(oldIndex);
                              groupItems.insert(newIndex, item);

                              ref.read(stockNotifierProvider.notifier).reorderItems(groupItems);
                            },
                            itemBuilder: (context, i) {
                              final item = groupItems[i];
                              return Card(
                                key: ValueKey('reorder_${item.id ?? i}'),
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
                    childCount: activeCategories.length,
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= activeCategories.length) return null;
                    final key = activeCategories[index];
                    final groupItems = groups[key]!;

                    return Column(
                      children: [
                        _StockGroupHeader(title: key),
                        ...groupItems.map((item) => StockItemTile(item: item)),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                  childCount: activeCategories.length,
                ),
              );
            },
            loading: () => const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator())),
            error: (e, s) => SliverFillRemaining(hasScrollBody: false, child: Center(child: Text('Erreur: $e'))),
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
