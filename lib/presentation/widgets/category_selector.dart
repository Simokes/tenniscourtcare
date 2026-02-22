import 'package:flutter/material.dart';

class CategorySelector extends StatelessWidget {
  final String? selectedCategory;
  final List<String> categories;
  final ValueChanged<String> onSelected;
  final bool enabled;

  const CategorySelector({
    super.key,
    required this.selectedCategory,
    required this.categories,
    required this.onSelected,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selectedCategory;
          return _CategoryCard(
            category: category,
            isSelected: isSelected,
            onTap: enabled ? () => onSelected(category) : null,
            enabled: enabled,
          );
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String category;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool enabled;

  const _CategoryCard({
    required this.category,
    required this.isSelected,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    IconData icon;

    if (category.toLowerCase().contains('matériaux')) {
      icon = Icons.layers;
    } else if (category.toLowerCase().contains('entretien')) {
      icon = Icons.cleaning_services;
    } else if (category.toLowerCase().contains('fourniture') || category.toLowerCase().contains('maintenance')) {
      icon = Icons.build;
    } else {
      icon = Icons.category;
    }

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 100,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.secondaryContainer : colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? colorScheme.secondary : colorScheme.outline.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 28,
                color: isSelected ? colorScheme.secondary : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                category,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? colorScheme.onSecondaryContainer : colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
