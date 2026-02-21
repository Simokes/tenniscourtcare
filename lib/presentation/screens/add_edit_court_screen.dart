import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/terrain.dart';
import '../providers/terrain_provider.dart';

class AddEditCourtScreen extends ConsumerStatefulWidget {
  final Terrain? terrain;

  const AddEditCourtScreen({super.key, this.terrain});

  @override
  ConsumerState<AddEditCourtScreen> createState() => _AddEditCourtScreenState();
}

class _AddEditCourtScreenState extends ConsumerState<AddEditCourtScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  TerrainType _selectedType = TerrainType.terreBattue;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.terrain?.nom ?? '');
    if (widget.terrain != null) {
      _selectedType = widget.terrain!.type;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();

    if (widget.terrain == null) {
      // Add
      final newTerrain = Terrain(
        id: 0, // ID will be auto-generated
        nom: name,
        type: _selectedType,
      );
      await ref.read(addTerrainProvider)(newTerrain);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Terrain ajouté')),
        );
      }
    } else {
      // Edit
      final updatedTerrain = widget.terrain!.copyWith(
        nom: name,
        type: _selectedType,
      );
      await ref.read(updateTerrainProvider)(updatedTerrain);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Terrain modifié')),
        );
      }
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.terrain != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier le terrain' : 'Ajouter un terrain'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du terrain',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TerrainType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Type de surface',
                  border: OutlineInputBorder(),
                ),
                items: TerrainType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
