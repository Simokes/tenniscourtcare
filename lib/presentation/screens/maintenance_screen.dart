import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/terrain_provider.dart';
import '../widgets/add_maintenance_sheet.dart';
import '../widgets/terrain_card.dart';
import 'terrain_maintenance_history_screen.dart';

class MaintenanceScreen extends ConsumerWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final terrainsAsync = ref.watch(terrainsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            title: Text('Maintenances'), // TODO(i18n): S.maintenancesTitle
            floating: true,
            snap: true,
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              background: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFE0E0E0), // Light grey or theme color
                      Colors.white,
                    ],
                  ),
                ),
              ),
            ),
          ),
          terrainsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => SliverFillRemaining(
              child: _ErrorView(
                message: 'Erreur: $error',
                onRetry: () => ref.refresh(terrainsProvider),
              ),
            ),
            data: (terrains) {
              if (terrains.isEmpty) {
                return SliverFillRemaining(
                  child: _EmptyState(
                    onAddCourt: () {
                      // Navigate to add court screen if implemented
                      // For now show a message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Fonctionnalité non implémentée')),
                      );
                    },
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
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
                  childCount: terrains.length,
                ),
              );
            },
          ),
        ],
      ),
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
