import re

with open('lib/features/maintenance/presentation/screens/maintenance_history_screen.dart', 'r') as f:
    content = f.read()

# 1. Update plannedCount in _TerrainHistoryTile
content = content.replace('''    final plannedCount = allPlanned.length; // Always total for planned''', '''    final plannedCount = startDate == null
        ? allPlanned.length
        : allPlanned.where((m) {
            final date = DateTime.fromMillisecondsSinceEpoch(m.date);
            return !date.isBefore(startDate!);
          }).length;''')

# 2. Update _MaintenanceHistoryItem margin and borderRadius
content = content.replace('''    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),''', '''    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),''')

with open('lib/features/maintenance/presentation/screens/maintenance_history_screen.dart', 'w') as f:
    f.write(content)
