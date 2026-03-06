import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../terrain/providers/terrain_provider.dart';
import '../../providers/maintenance_provider.dart';
import '../widgets/add_maintenance_sheet.dart';
import '../../../terrain/presentation/widgets/terrain_card.dart';
import '../../../../shared/widgets/common/sync_status_indicator.dart';
import './terrain_maintenance_history_screen.dart';

class MaintenanceScreen extends ConsumerStatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  ConsumerState<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends ConsumerState<MaintenanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              title: const Text('Maintenances'),
              floating: true,
              pinned: true,
              expandedHeight: 120,
              actions: const [
                ConnectionStatusIndicator(mode: SyncIndicatorMode.compact),
                SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFFE0E0E0), // Light grey or theme color
                        Theme.of(context).scaffoldBackgroundColor,
                      ],
                    ),
                  ),
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'À venir'),
                  Tab(text: 'Historique'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _UpcomingMaintenancesTab(),
            _HistoryTab(),
          ],
        ),
      ),
    );
  }
}

class _UpcomingMaintenancesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plannedMaintenancesAsync = ref.watch(plannedMaintenancesProvider);
    final terrainsAsync = ref.watch(terrainsProvider);

    if (plannedMaintenancesAsync.isLoading || terrainsAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (plannedMaintenancesAsync.hasError) {
      return Center(child: Text('Erreur: ${plannedMaintenancesAsync.error}'));
    }

    final maintenances = plannedMaintenancesAsync.value ?? [];
    final terrains = terrainsAsync.value ?? [];

    if (maintenances.isEmpty) {
      return const Center(
        child: Text('Aucune maintenance planifiée à venir.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: maintenances.length,
      itemBuilder: (context, index) {
        final maintenance = maintenances[index];
        final terrain = terrains.firstWhere(
          (t) => t.id == maintenance.terrainId,
          orElse: () => throw Exception('Terrain not found'),
        );
        final date = DateTime.fromMillisecondsSinceEpoch(maintenance.date);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.orangeAccent,
              child: Icon(Icons.schedule, color: Colors.white),
            ),
            title: Text('${terrain.nom} — ${maintenance.type}'),
            subtitle: Text('Prévu le ${DateFormat('dd/MM/yyyy').format(date)}'),
            trailing: FilledButton.tonal(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  useSafeArea: true,
                  isScrollControlled: true,
                  showDragHandle: true,
                  builder: (_) => AddMaintenanceSheet(
                    terrain: terrain,
                    existingMaintenance: maintenance,
                    forceCompleteMode: true,
                  ),
                );
              },
              child: const Text('Effectuer'),
            ),
          ),
        );
      },
    );
  }
}

class _HistoryTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final terrainsAsync = ref.watch(terrainsProvider);

    return terrainsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _ErrorView(
        message: 'Erreur: $error',
        onRetry: () => ref.refresh(terrainsProvider),
      ),
      data: (terrains) {
        if (terrains.isEmpty) {
          return _EmptyState(
            onAddCourt: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fonctionnalité non implémentée'),
                ),
              );
            },
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: terrains.length,
          itemBuilder: (context, index) {
            final terrain = terrains[index];
            return TerrainCard(
              terrain: terrain,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        TerrainMaintenanceHistoryScreen(terrain: terrain),
                  ),
                );
              },
              onAddMaintenance: () async {
                final success = await showModalBottomSheet<bool>(
                  context: context,
                  useSafeArea: true,
                  isScrollControlled: true,
                  showDragHandle: true,
                  builder: (_) => AddMaintenanceSheet(terrain: terrain),
                );

                if (success == true && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Maintenance ajoutée')),
                  );
                }
              },
            );
          },
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAddCourt});
  final VoidCallback onAddCourt;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sports_tennis, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Aucun terrain enregistré',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAddCourt,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un terrain'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
