import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/terrain.dart';
import '../providers/terrain_provider.dart';
import 'add_edit_court_screen.dart';

class CourtManagementScreen extends ConsumerWidget {
  const CourtManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final terrainsAsync = ref.watch(terrainsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des terrains'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddEditCourtScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: terrainsAsync.when(
        data: (terrains) {
          if (terrains.isEmpty) {
            return const Center(
              child: Text('Aucun terrain enregistré.'),
            );
          }
          return ListView.builder(
            itemCount: terrains.length,
            itemBuilder: (context, index) {
              final terrain = terrains[index];
              return ListTile(
                title: Text(terrain.nom),
                subtitle: Text(terrain.type.displayName),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => AddEditCourtScreen(
                              terrain: terrain,
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDelete(context, ref, terrain),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Erreur: $error')),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Terrain terrain,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce terrain ?'),
        content: Text(
          'Voulez-vous vraiment supprimer "${terrain.nom}" ?\n'
          'Cela pourrait affecter l\'historique des maintenances liées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(deleteTerrainProvider)(terrain.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Terrain supprimé')),
        );
      }
    }
  }
}
