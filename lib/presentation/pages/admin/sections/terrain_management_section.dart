import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/terrain_provider.dart';
import '../../../../domain/entities/terrain.dart';
import '../../../widgets/premium/premium_card.dart';

class TerrainManagementSection extends ConsumerWidget {
  const TerrainManagementSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final terrainsAsync = ref.watch(terrainsProvider);

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Terrains',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showAddTerrainDialog(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 16),
          terrainsAsync.when(
            data: (terrains) {
              if (terrains.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: Text('Aucun terrain configuré.')),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: terrains.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final terrain = terrains[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(terrain.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Row(
                      children: [
                        Text(terrain.type.displayName),
                        const SizedBox(width: 8),
                        Chip(
                          label: Text(terrain.status.displayName, style: const TextStyle(fontSize: 12)),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          backgroundColor: terrain.status.color.withValues(alpha: 0.2),
                          labelStyle: TextStyle(
                            color: terrain.status.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showEditTerrainDialog(context, ref, terrain),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Confirmer'),
                                content: Text('Voulez-vous vraiment supprimer le terrain "${terrain.nom}" ?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Annuler'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      if (terrain.firebaseId != null) {
                                        ref.read(terrainNotifierProvider.notifier).deleteTerrain(terrain.firebaseId!);
                                      }
                                    },
                                    child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Text('Erreur: $err', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddTerrainDialog(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    String nom = '';
    TerrainType type = TerrainType.terreBattue;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajouter un terrain'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Nom du terrain'),
                    validator: (value) => value == null || value.isEmpty ? 'Champ requis' : null,
                    onSaved: (value) => nom = value!,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<TerrainType>(
                    decoration: const InputDecoration(labelText: 'Type de terrain'),
                    initialValue: type,
                    items: TerrainType.values.map((t) {
                      return DropdownMenuItem(
                        value: t,
                        child: Text(t.displayName),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          type = val;
                        });
                      }
                    },
                  ),
                ],
              ),
            );
          }
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                ref.read(terrainNotifierProvider.notifier).addTerrain(nom, type);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _showEditTerrainDialog(BuildContext context, WidgetRef ref, Terrain terrain) {
    final formKey = GlobalKey<FormState>();
    String nom = terrain.nom;
    TerrainType type = terrain.type;
    TerrainStatus status = terrain.status;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modifier le terrain'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: nom,
                    decoration: const InputDecoration(labelText: 'Nom du terrain'),
                    validator: (value) => value == null || value.isEmpty ? 'Champ requis' : null,
                    onSaved: (value) => nom = value!,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<TerrainType>(
                    decoration: const InputDecoration(labelText: 'Type de terrain'),
                    initialValue: type,
                    items: TerrainType.values.map((t) {
                      return DropdownMenuItem(
                        value: t,
                        child: Text(t.displayName),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          type = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<TerrainStatus>(
                    decoration: const InputDecoration(labelText: 'Statut'),
                    initialValue: status,
                    items: TerrainStatus.values.map((s) {
                      return DropdownMenuItem(
                        value: s,
                        child: Text(s.displayName),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          status = val;
                        });
                      }
                    },
                  ),
                ],
              ),
            );
          }
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                final updatedTerrain = terrain.copyWith(
                  nom: nom,
                  type: type,
                  status: status,
                  updatedAt: DateTime.now(),
                );
                ref.read(terrainNotifierProvider.notifier).updateTerrain(updatedTerrain);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}
