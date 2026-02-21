import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/terrain.dart';
import '../providers/terrain_provider.dart';
import '../widgets/add_maintenance_sheet.dart';
import 'terrain_maintenance_history_screen.dart';

class MaintenanceScreen extends ConsumerWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final terrainsAsync = ref.watch(terrainsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenances',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: terrainsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _ErrorView(
          message: 'Erreur: $error',
          onRetry: () => ref.refresh(terrainsProvider),
        ),
        data: (terrains) {
          if (terrains.isEmpty) {
            return _EmptyState(
              onAddCourt: () {
                // Navigation vers écran ajout terrain (non implémenté ici)
              },
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: terrains.length,
            itemBuilder: (context, index) {
              final terrain = terrains[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _TerrainMaintenanceCard(terrain: terrain),
              );
            },
          );
        },
      ),
    );
  }
}

class _TerrainMaintenanceCard extends StatelessWidget {
  final Terrain terrain;

  const _TerrainMaintenanceCard({required this.terrain});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    IconData icon;
    Color surfaceColor;
    Color onSurfaceColor;

    switch (terrain.type) {
      case TerrainType.terreBattue:
        icon = Icons.landscape;
        surfaceColor = Colors.orange.shade100;
        onSurfaceColor = Colors.orange.shade900;
        break;
      case TerrainType.synthetique:
        icon = Icons.grass;
        surfaceColor = Colors.green.shade100;
        onSurfaceColor = Colors.green.shade900;
        break;
      case TerrainType.dur:
        icon = Icons.sports_tennis;
        surfaceColor = Colors.blue.shade100;
        onSurfaceColor = Colors.blue.shade900;
        break;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TerrainMaintenanceHistoryScreen(terrain: terrain),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: onSurfaceColor, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          terrain.nom,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          terrain.type.displayName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              TerrainMaintenanceHistoryScreen(terrain: terrain),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: () async {
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
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Nouvelle maintenance'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_tennis,
                size: 64, color: Theme.of(context).disabledColor),
            const SizedBox(height: 16),
            Text(
              'Aucun terrain',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez des terrains pour commencer à suivre leur maintenance.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onAddCourt,
              child: const Text('Ajouter un terrain'),
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
            Text(message, textAlign: TextAlign.center),
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
