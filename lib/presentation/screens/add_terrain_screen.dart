// lib/presentation/screens/add_terrain_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/terrain.dart'; // Pour TerrainType
import '../providers/terrain_provider.dart';

class AddTerrainScreen extends ConsumerStatefulWidget {
  const AddTerrainScreen({super.key});

  @override
  ConsumerState<AddTerrainScreen> createState() => _AddTerrainScreenState();
}

class _AddTerrainScreenState extends ConsumerState<AddTerrainScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  // On initialise avec une valeur de l'énumération
  TerrainType _selectedType = TerrainType.terreBattue;

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final addTerrainFn = ref.read(addTerrainProvider);

      await addTerrainFn(_nameController.text, _selectedType);

      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau Court')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nom du terrain'),
                validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<TerrainType>(
                initialValue: _selectedType,
                decoration: const InputDecoration(labelText: 'Type de surface'),
                // On boucle sur les valeurs de l'énumération TerrainType
                items: TerrainType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName), // Utilise ton getter displayName
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedType = val!),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('ENREGISTRER'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}