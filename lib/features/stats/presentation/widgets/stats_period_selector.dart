import 'package:flutter/material.dart';
import '../../providers/stats_period_provider.dart';

class StatsPeriodSelector extends StatelessWidget {
  final PeriodType currentType;
  final ValueChanged<PeriodType> onPeriodChanged;
  final VoidCallback onCustomPeriod;

  const StatsPeriodSelector({
    super.key,
    required this.currentType,
    required this.onPeriodChanged,
    required this.onCustomPeriod,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: _Segment(
              label: 'Jour',
              isSelected: currentType == PeriodType.day,
              onTap: () => onPeriodChanged(PeriodType.day),
            ),
          ),
          Expanded(
            child: _Segment(
              label: 'Semaine',
              isSelected: currentType == PeriodType.week,
              onTap: () => onPeriodChanged(PeriodType.week),
            ),
          ),
          Expanded(
            child: _Segment(
              label: 'Mois',
              isSelected: currentType == PeriodType.month,
              onTap: () => onPeriodChanged(PeriodType.month),
            ),
          ),
          Expanded(
            child: _Segment(
              label: 'Custom',
              isSelected: currentType == PeriodType.custom,
              onTap: onCustomPeriod,
            ),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.black87 : Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
