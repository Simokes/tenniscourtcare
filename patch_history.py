import re

with open('lib/features/maintenance/presentation/screens/maintenance_history_screen.dart', 'r') as f:
    content = f.read()

# 1. SliverAppBar
content = content.replace('''        slivers: [
          // KPI Row
          SliverToBoxAdapter(''', '''        slivers: [
          const SliverAppBar(
            title: Text('Historique'),
            floating: true,
            snap: true,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
          ),
          // KPI Row
          SliverToBoxAdapter(''')

# 2. KPIs synchronises avec filtre
# Add startDate to buildKPIRow signature and compute it in build()
# find where `_buildKPIRow` is called
build_kpi_row_call = '''              child: _buildKPIRow(
                maintenancesAsync.valueOrNull ?? [],
                plannedMaintenancesAsync.valueOrNull ?? [],
                cs,
                dc,
              ),'''

# We need to compute startDate based on _selectedPeriod in build()
# We can just extract it from _TerrainHistoryTile or just add the same logic at the start of build()
start_date_logic = '''
    final now = DateTime.now();
    DateTime? startDate;
    if (_selectedPeriod == 'week') {
      startDate = DateTime.fromMillisecondsSinceEpoch(DateUtils.startOfWeek(now));
    } else if (_selectedPeriod == 'month') {
      startDate = DateTime.fromMillisecondsSinceEpoch(DateUtils.startOfMonth(now));
    } else if (_selectedPeriod == 'year') {
      startDate = DateTime(now.year, 1, 1);
    }
'''

content = content.replace('''    final maintenanceTypes = ref.watch(maintenanceTypesProvider);

    return Scaffold(''', f'''    final maintenanceTypes = ref.watch(maintenanceTypesProvider);
{start_date_logic}
    return Scaffold(''')

content = content.replace('''              child: _buildKPIRow(
                maintenancesAsync.valueOrNull ?? [],
                plannedMaintenancesAsync.valueOrNull ?? [],
                cs,
                dc,
              ),''', '''              child: _buildKPIRow(
                maintenancesAsync.valueOrNull ?? [],
                plannedMaintenancesAsync.valueOrNull ?? [],
                cs,
                dc,
                startDate,
              ),''')

# Update `_buildKPIRow` definition
content = content.replace('''  Widget _buildKPIRow(
    List<Maintenance> allMaintenances,
    List<Maintenance> plannedMaintenances,
    ColorScheme cs,
    DashboardColors? dc,
  ) {
    final doneCount = allMaintenances.where((m) => !m.isPlanned).length;
    final plannedCount = plannedMaintenances.length;''', '''  Widget _buildKPIRow(
    List<Maintenance> allMaintenances,
    List<Maintenance> plannedMaintenances,
    ColorScheme cs,
    DashboardColors? dc,
    DateTime? startDate,
  ) {
    final doneCount = allMaintenances.where((m) {
      if (m.isPlanned) return false;
      if (startDate != null) {
        final date = DateTime.fromMillisecondsSinceEpoch(m.date);
        if (date.isBefore(startDate)) return false;
      }
      return true;
    }).length;

    final plannedCount = plannedMaintenances.where((m) {
      if (startDate != null) {
        final date = DateTime.fromMillisecondsSinceEpoch(m.date);
        if (date.isBefore(startDate)) return false;
      }
      return true;
    }).length;''')


# 3. DropdownButton -> DropdownMenu
content = content.replace('''                  // Type Filter (Dropdown)
                  DropdownButton<String?>(
                    value: _selectedType,
                    hint: const Text('Tous types'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Tous types'),
                      ),
                      ...maintenanceTypes.map(
                        (type) => DropdownMenuItem<String?>(
                          value: type,
                          child: Text(type),
                        ),
                      ),
                    ],
                    onChanged: (val) => setState(() => _selectedType = val),
                    underline: const SizedBox(),
                  ),''', '''                  // Type Filter (Dropdown)
                  DropdownMenu<String?>(
                    initialSelection: _selectedType,
                    hintText: 'Tous types',
                    width: 140,
                    inputDecorationTheme: InputDecorationTheme(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    dropdownMenuEntries: [
                      const DropdownMenuEntry<String?>(value: null, label: 'Tous types'),
                      ...maintenanceTypes.map((type) => DropdownMenuEntry<String?>(value: type, label: type)),
                    ],
                    onSelected: (val) => setState(() => _selectedType = val),
                  ),''')

# 4. Emojis -> Icon in _TerrainHistoryTile subtitle
content = content.replace('''            subtitle: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  '✅ $filteredDoneCount effectuées',
                  style: TextStyle(color: dc?.successColor ?? Colors.green, fontSize: 12),
                ),
                Text(
                  '📅 $plannedCount planifiées',
                  style: TextStyle(color: dc?.warningColor ?? Colors.orange, fontSize: 12),
                ),
                Text(
                  '🕒 Dernière: $formattedLastDate',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),''', '''            subtitle: Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline, size: 14, color: dc?.successColor ?? Colors.green),
                    const SizedBox(width: 4),
                    Text('$filteredDoneCount effectuées', style: TextStyle(color: dc?.successColor ?? Colors.green, fontSize: 12)),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 14, color: dc?.warningColor ?? Colors.orange),
                    const SizedBox(width: 4),
                    Text('$plannedCount planifiées', style: TextStyle(color: dc?.warningColor ?? Colors.orange, fontSize: 12)),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time_outlined, size: 14, color: cs.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text('Dernière: $formattedLastDate', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  ],
                ),
              ],
            ),''')

# 5. _TerrainHistoryTile Card
content = content.replace('''    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),''', '''    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),''')

content = content.replace('''            title: Text(
              terrain.nom,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),''', '''            title: Text(
              terrain.nom,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),''')

# 6. Empty state in terrain expanded
content = content.replace('''            secondChild: filteredMaintenances.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Aucune maintenance pour cette période',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  )''', '''            secondChild: filteredMaintenances.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    child: Column(
                      children: [
                        Icon(Icons.inbox_outlined, size: 32, color: cs.onSurfaceVariant),
                        const SizedBox(height: 8),
                        Text(
                          'Aucune maintenance pour cette période',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ],
                    ),
                  )''')

# 7. _MaintenanceHistoryItem
content = content.replace('''                      Text(
                        maintenance.type,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),''', '''                      Text(
                        maintenance.type,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),''')

content = content.replace('''                    Text(
                      maintenance.commentaire!,
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                      ),''', '''                    Text(
                      maintenance.commentaire!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),''')

content = content.replace('''                          color: Theme.of(context).primaryColor,''', '''                          color: Theme.of(context).colorScheme.primary,''')

content = content.replace('''                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => AddMaintenanceSheet(''', '''                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      showDragHandle: true,
                      builder: (_) => AddMaintenanceSheet(''')

# 8. _SacChip labels
content = content.replace('''                      if (maintenance.sacsMantoUtilises > 0)
                        _SacChip(
                          'M: ${maintenance.sacsMantoUtilises}',
                          Colors.brown,
                        ),
                      if (maintenance.sacsSottomantoUtilises > 0)
                        _SacChip(
                          'S: ${maintenance.sacsSottomantoUtilises}',
                          Colors.blueGrey,
                        ),
                      if (maintenance.sacsSiliceUtilises > 0)
                        _SacChip(
                          'Si: ${maintenance.sacsSiliceUtilises}',
                          Colors.teal,
                        ),''', '''                      if (maintenance.sacsMantoUtilises > 0)
                        _SacChip(
                          'Manto: ${maintenance.sacsMantoUtilises}',
                          Colors.brown,
                        ),
                      if (maintenance.sacsSottomantoUtilises > 0)
                        _SacChip(
                          'Sott.: ${maintenance.sacsSottomantoUtilises}',
                          Colors.blueGrey,
                        ),
                      if (maintenance.sacsSiliceUtilises > 0)
                        _SacChip(
                          'Silice: ${maintenance.sacsSiliceUtilises}',
                          Colors.teal,
                        ),''')


with open('lib/features/maintenance/presentation/screens/maintenance_history_screen.dart', 'w') as f:
    f.write(content)
