import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        title: const Text('Maintenances'), // TODO(i18n): S.maintenancesTitle
      ),
      body: terrainsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _ErrorView(
          message: 'Erreur: $error', // TODO(i18n): S.errorPrefix(error)
          onRetry: () => ref.refresh(terrainsProvider),
        ),
        data: (terrains) {
          if (terrains.isEmpty) {
            return _EmptyState(
              onAddCourt: () {
                // TODO: Naviguer vers l'écran d'ajout de terrain
              },
            );
          }

          return ListView.separated(
            itemCount: terrains.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final terrain = terrains[index];
              return ListTile(
                leading: _TerrainTypeIcon(typeName: terrain.type.displayName),
                title: Text(
                  terrain.nom,
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  terrain.type.displayName, // TODO(i18n) si besoin
                  style: Theme.of(context).textTheme.bodyMedium,
                ),

                trailing: IconButton(
                  icon: const Icon(Icons.add),
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
                      // Optionnel: invalider/refresh un provider d'historique si tu en as un :
                      // ref.invalidate(maintenancesByTerrainProvider(terrain.id));
                    }
                  },
                ),

                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          TerrainMaintenanceHistoryScreen(terrain: terrain),
                    ),
                  );
                },
              );
            },
          );
        },
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
            const Icon(Icons.sports_tennis, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'Aucun terrain enregistré', // TODO(i18n): S.noCourts
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onAddCourt,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un terrain'), // TODO(i18n): S.addCourt
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
              label: const Text('Réessayer'), // TODO(i18n): S.retry
            ),
          ],
        ),
      ),
    );
  }
}

class _TerrainTypeIcon extends StatelessWidget {
  const _TerrainTypeIcon({required this.typeName});
  final String typeName;

  @override
  Widget build(BuildContext context) {
    // Simpliste : mappe des mots-clés -> icônes
    final lower = typeName.toLowerCase();
    IconData icon;
    if (lower.contains('gazon')) {
      icon = Icons.grass;
    } else if (lower.contains('terre')) {
      icon = Icons.landscape;
    } else if (lower.contains('dur')) {
      icon = Icons.sports_tennis; // placeholder
    } else {
      icon = Icons.sports_tennis;
    }
    return Icon(icon, color: Theme.of(context).colorScheme.primary);
  }
}
