import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/terrain.dart';
import '../providers/terrain_provider.dart';
import '../providers/database_provider.dart';

class TerrainsManagementScreen extends ConsumerWidget {
  const TerrainsManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final terrainsAsync = ref.watch(terrainsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des terrains'),
      ),
      body: terrainsAsync.when(
        data: (terrains) {
          if (terrains.isEmpty) {
            return const Center(child: Text('Aucun terrain enregistré'));
          }
          return ListView.builder(
            itemCount: terrains.length,
            itemBuilder: (context, index) {
              final terrain = terrains[index];
              return ListTile(
                leading: Icon(_getTerrainIcon(terrain.type)),
                title: Text(terrain.nom),
                subtitle: Text(_getTerrainTypeName(terrain.type)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _confirmDelete(context, ref, terrain),
                ),
                onTap: () => _showEditTerrainDialog(context, ref, terrain),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTerrainDialog(context, ref),
        label: const Text('Ajouter'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  IconData _getTerrainIcon(TerrainType type) {
    switch (type) {
      case TerrainType.terreBattue:
        return Icons.landscape;
      case TerrainType.synthetique:
        return Icons.grass;
      case TerrainType.dur:
        return Icons.layers;
    }
  }

  String _getTerrainTypeName(TerrainType type) {
    switch (type) {
      case TerrainType.terreBattue:
        return 'Terre battue';
      case TerrainType.synthetique:
        return 'Synthétique';
      case TerrainType.dur:
        return 'Dur';
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Terrain terrain) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le terrain ?'),
        content: Text('Voulez-vous vraiment supprimer "${terrain.nom}" ? Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(databaseProvider).deleteTerrain(terrain.id);
      ref.invalidate(terrainsProvider);
    }
  }

  void _showAddTerrainDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const _TerrainDialog(),
    );
  }

  void _showEditTerrainDialog(BuildContext context, WidgetRef ref, Terrain terrain) {
    showDialog(
      context: context,
      builder: (context) => _TerrainDialog(terrain: terrain),
    );
  }
}

class _TerrainDialog extends StatefulWidget {
  final Terrain? terrain;
  const _TerrainDialog({this.terrain});

  @override
  State<_TerrainDialog> createState() => _TerrainDialogState();
}

class _TerrainDialogState extends State<_TerrainDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late TerrainType _type;

  @override
  void initState() {
    super.initState();
    _name = widget.terrain?.nom ?? '';
    _type = widget.terrain?.type ?? TerrainType.terreBattue;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.terrain != null;

    return Consumer(
      builder: (context, ref, _) => AlertDialog(
        title: Text(isEditing ? 'Modifier le terrain' : 'Nouveau terrain'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: 'Nom du court (ex: Court 1)'),
                validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                onSaved: (v) => _name = v!,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TerrainType>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Surface'),
                items: TerrainType.values
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t == TerrainType.terreBattue
                              ? 'Terre battue'
                              : t == TerrainType.synthetique
                                  ? 'Synthétique'
                                  : 'Dur'),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _type = v!),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;
              _formKey.currentState!.save();

              if (isEditing) {
                await ref.read(updateTerrainProvider)(
                  widget.terrain!.copyWith(nom: _name, type: _type),
                );
              } else {
                await ref.read(addTerrainProvider)(_name, _type);
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(isEditing ? 'Mettre à jour' : 'Créer'),
          ),
        ],
      ),
    );
  }
}
