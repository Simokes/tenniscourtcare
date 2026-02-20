import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/terrain.dart';
import '../providers/terrain_provider.dart';

class EditCoordsPage extends ConsumerStatefulWidget {
  final Terrain terrain;
  const EditCoordsPage({super.key, required this.terrain});

  @override
  ConsumerState<EditCoordsPage> createState() => _EditCoordsPageState();
}

class _EditCoordsPageState extends ConsumerState<EditCoordsPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _latCtrl;
  late TextEditingController _lonCtrl;

  @override
  void initState() {
    super.initState();
    _latCtrl = TextEditingController(text: widget.terrain.latitude?.toStringAsFixed(6) ?? '');
    _lonCtrl = TextEditingController(text: widget.terrain.longitude?.toStringAsFixed(6) ?? '');
  }

  @override
  void dispose() {
    _latCtrl.dispose();
    _lonCtrl.dispose();
    super.dispose();
  }

  String? _validateLat(String? v) {
    if (v == null || v.trim().isEmpty) return 'Latitude requise';
    final d = double.tryParse(v.replaceAll(',', '.'));
    if (d == null) return 'Nombre invalide';
    if (d < -90 || d > 90) return 'Doit être entre -90 et 90';
    return null;
  }

  String? _validateLon(String? v) {
    if (v == null || v.trim().isEmpty) return 'Longitude requise';
    final d = double.tryParse(v.replaceAll(',', '.'));
    if (d == null) return 'Nombre invalide';
    if (d < -180 || d > 180) return 'Doit être entre -180 et 180';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final lat = double.parse(_latCtrl.text.replaceAll(',', '.'));
    final lon = double.parse(_lonCtrl.text.replaceAll(',', '.'));

    final updated = widget.terrain.copyWith(latitude: lat, longitude: lon);

    try {
      await ref.read(updateTerrainProvider)(updated);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Coordonnées - ${widget.terrain.nom}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
            tooltip: 'Enregistrer',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text('Type : ${widget.terrain.type.displayName}'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _latCtrl,
                decoration: const InputDecoration(
                  labelText: 'Latitude *',
                  hintText: 'Ex: 43.552847',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[-0-9\.,]')),
                ],
                validator: _validateLat,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lonCtrl,
                decoration: const InputDecoration(
                  labelText: 'Longitude *',
                  hintText: 'Ex: 7.017369',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[-0-9\.,]')),
                ],
                validator: _validateLon,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}