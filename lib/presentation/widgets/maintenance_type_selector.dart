import 'package:flutter/material.dart';

class MaintenanceTypeSelector extends StatelessWidget {
  final String? selectedType;
  final List<String> types;
  final ValueChanged<String> onSelected;

  const MaintenanceTypeSelector({
    super.key,
    required this.selectedType,
    required this.types,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: types.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final type = types[index];
          final isSelected = type == selectedType;
          return _TypeCard(
            type: type,
            isSelected: isSelected,
            onTap: () => onSelected(type),
          );
        },
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final String type;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeCard({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Choose icon based on type (simple heuristic)
    IconData icon;
    if (type.toLowerCase().contains('arrosage') || type.toLowerCase().contains('nettoyage')) {
      icon = Icons.water_drop;
    } else if (type.toLowerCase().contains('brossage') || type.toLowerCase().contains('balayage')) {
      icon = Icons.cleaning_services;
    } else if (type.toLowerCase().contains('recharge') || type.toLowerCase().contains('silice')) {
      icon = Icons.add_circle;
    } else if (type.toLowerCase().contains('compactage') || type.toLowerCase().contains('nivelage')) {
      icon = Icons.landscape;
    } else if (type.toLowerCase().contains('ligne') || type.toLowerCase().contains('couture')) {
      icon = Icons.straighten;
    } else {
      icon = Icons.build;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              type,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
