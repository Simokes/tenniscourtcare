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
      appBar: AppBar(title: const Text('Maintenances')),
      body: terrainsAsync.when(
        data: (terrains) {
          if (terrains.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Aucun terrain enregistré'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Ajouter un terrain
                    },
                    child: const Text('Ajouter un terrain'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: terrains.length,
            itemBuilder: (context, index) {
              final terrain = terrains[index];
              return ListTile(
                title: Text(terrain.nom),
                subtitle: Text(terrain.type.displayName),
                trailing: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => AddMaintenanceSheet(terrain: terrain),
                    );
                  },
                ),
                onTap: () {
                  Navigator.push(
                    context,
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Erreur: $error')),
      ),
    );
  }
}
