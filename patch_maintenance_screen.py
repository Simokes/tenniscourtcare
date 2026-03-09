import re

with open('lib/features/maintenance/presentation/screens/maintenance_screen.dart', 'r') as f:
    content = f.read()

# FAB
content = content.replace('''      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle maintenance'),
        onPressed: () => showModalBottomSheet(
          context: context,
          useSafeArea: true,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => const AddMaintenanceSheet(),
        ),
      ),''', '''      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        tooltip: 'Nouvelle maintenance',
        onPressed: () => showModalBottomSheet(
          context: context,
          useSafeArea: true,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => const AddMaintenanceSheet(),
        ),
        child: const Icon(Icons.add),
      ),''')

# KPI Strip
content = content.replace('''        slivers: [
          // KPI Strip
          SliverToBoxAdapter(
            child: Container(
              height: 48,''', '''        slivers: [
          // KPI Strip
          const SliverToBoxAdapter(
            child: SizedBox(height: 12),
          ),
          SliverToBoxAdapter(
            child: Container(
              height: 56,''')

content = content.replace('''  Widget _buildKpiChip({
    required IconData icon,
    required String text,
    required Color color,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(''', '''  Widget _buildKpiChip({
    required IconData icon,
    required String text,
    required Color color,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(''')

# Section Header
content = content.replace('''class _MaintenanceSectionHeader extends StatelessWidget {
  final String label;
  final int count;
  final Color? color;

  const _MaintenanceSectionHeader({
    required this.label,
    required this.count,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            color: color ?? colorScheme.primary,
            margin: const EdgeInsets.only(right: 8),
          ),
          Text(
            '$label ($count)',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: color ?? colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}''', '''class _MaintenanceSectionHeader extends StatelessWidget {
  final String label;
  final int count;
  final Color? color;

  const _MaintenanceSectionHeader({
    required this.label,
    required this.count,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeColor = color ?? colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 18,
            color: themeColor,
            margin: const EdgeInsets.only(right: 8),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: themeColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: themeColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}''')

# _MaintenanceActionCard
content = content.replace('''      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(''', '''      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(''')

content = content.replace('''                  if (isOverdue)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: dangerColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'EN RETARD',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),''', '''                  if (isOverdue)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: dangerColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'EN RETARD',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          letterSpacing: 0.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),''')

content = content.replace('''                  TextButton.icon(
                    icon: const Icon(Icons.edit_calendar, size: 16),
                    label: const Text('Reporter'),
                    style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact),''', '''                  TextButton.icon(
                    icon: const Icon(Icons.edit_calendar, size: 16),
                    label: const Text('Reporter'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.standard,
                      minimumSize: const Size(0, 44),
                    ),''')

content = content.replace('''                  FilledButton.icon(
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Compléter'),
                    style: FilledButton.styleFrom(
                      backgroundColor: successColor,
                      visualDensity: VisualDensity.compact,
                    ),''', '''                  FilledButton.icon(
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Compléter'),
                    style: FilledButton.styleFrom(
                      backgroundColor: successColor,
                      visualDensity: VisualDensity.standard,
                      minimumSize: const Size(0, 44),
                    ),''')

# _MaintenancePlannedCard
content = content.replace('''      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        color: colorScheme.surface,
        child: ListTile(
          dense: true,
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: maintenanceColor.withValues(alpha: 0.15),
            child: Icon(Icons.build_circle_outlined,
                size: 18, color: maintenanceColor),
          ),
          title: Text('${terrain.nom} • ${maintenance.type}',
              style: Theme.of(context).textTheme.bodyMedium),
          subtitle: Text(
              '${maintenance.startHour.toString().padLeft(2, '0')}h • $dayLabel',
              style: Theme.of(context).textTheme.bodySmall),
          trailing: const Icon(Icons.chevron_right, size: 18),''', '''      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        color: colorScheme.surface,
        child: ListTile(
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: maintenanceColor.withValues(alpha: 0.15),
            child: Icon(Icons.build_circle_outlined,
                size: 18, color: maintenanceColor),
          ),
          title: Text('${terrain.nom} • ${maintenance.type}',
              style: Theme.of(context).textTheme.bodyMedium),
          subtitle: Text(
              '${maintenance.startHour.toString().padLeft(2, '0')}h • $dayLabel',
              style: Theme.of(context).textTheme.bodySmall),
          trailing: Icon(Icons.edit_outlined, size: 18, color: colorScheme.onSurfaceVariant),''')

# Loading and Error states
content = content.replace('''              builder: (context, ref, child) {
                if (plannedAsync.isLoading || terrainsAsync.isLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (plannedAsync.hasError || terrainsAsync.hasError) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('Erreur de chargement'),
                    ),
                  );
                }''', '''              builder: (context, ref, child) {
                if (plannedAsync.isLoading || terrainsAsync.isLoading) {
                  return Column(
                    children: List.generate(3, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        height: 80,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      );
                    }),
                  );
                }

                if (plannedAsync.hasError || terrainsAsync.hasError) {
                  return Column(
                    children: [
                      const SizedBox(height: 32),
                      Icon(Icons.cloud_off_outlined,
                          size: 48, color: colorScheme.onSurfaceVariant),
                      const SizedBox(height: 12),
                      Text('Impossible de charger les maintenances',
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          ref.invalidate(plannedMaintenancesProvider);
                          ref.invalidate(terrainsProvider);
                        },
                        child: const Text('Réessayer'),
                      ),
                    ],
                  );
                }''')

# Empty state and Navigation
content = content.replace('''                    if (planned.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.check_circle_outline,
                                  size: 48,
                                  color: dc?.successColor ?? Colors.green),
                              const SizedBox(height: 12),
                              Text('Aucune maintenance planifiée',
                                  style: Theme.of(context).textTheme.titleMedium),
                            ],
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 16),
                      child: TextButton.icon(
                        icon: const Icon(Icons.history),
                        label: const Text("Voir l'historique"),
                        onPressed: () {
                          // Essayer GoRouter en premier, fallback sur Navigator
                          try {
                            context.go('/maintenance/history');
                          } catch (e) {
                            debugPrint('Route /maintenance/history non trouvée, fallback Navigator: $e');
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MaintenanceHistoryScreen(),
                              ),
                            );
                          }
                        },
                      ),
                    ),''', '''                    if (planned.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.check_circle_outline,
                                  size: 56,
                                  color: dc?.successColor ?? Colors.green),
                              const SizedBox(height: 16),
                              Text('Tout est à jour',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text('Aucune maintenance planifiée',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                          color: colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.history),
                          label: const Text("Voir l'historique"),
                          onPressed: () => context.push('/maintenance/history'),
                        ),
                      ),
                    ),''')


with open('lib/features/maintenance/presentation/screens/maintenance_screen.dart', 'w') as f:
    f.write(content)
