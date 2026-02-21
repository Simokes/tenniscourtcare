// lib/presentation/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_settings_provider.dart';
import '../providers/database_provider.dart';
import '../../data/database/seed_data.dart';
import 'court_management_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _latCtrl;
  late final TextEditingController _lonCtrl;
  bool _seededFromSettings = false;

  @override
  void initState() {
    super.initState();
    _latCtrl = TextEditingController();
    _lonCtrl = TextEditingController();
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

    await ref
        .read(appSettingsProvider.notifier)
        .setClubLocation(ClubLocation(latitude: lat, longitude: lon));

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coordonnées enregistrées')),
    );
  }

  Future<void> _delete() async {
    await ref.read(appSettingsProvider.notifier).setClubLocation(null);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coordonnées supprimées')),
    );

    _latCtrl.text = '';
    _lonCtrl.text = '';
    _seededFromSettings = false;
  }

  Future<void> _seedData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Générer les données de test'),
        content: const Text(
          'Cela va ajouter des terrains par défaut (6 terres battues, 2 synthétiques, 3 durs) si aucun terrain n\'existe.\n'
          'Continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Générer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final database = ref.read(databaseProvider);
    await seedDevData(database);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Données générées (si la base était vide)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
            tooltip: 'Enregistrer',
          ),
        ],
      ),
      body: settings.when(
        data: (loc) {
          // Seed des champs une seule fois quand les données arrivent
          if (loc != null && !_seededFromSettings) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _latCtrl.text = loc.latitude.toStringAsFixed(6);
              _lonCtrl.text = loc.longitude.toStringAsFixed(6);
              _seededFromSettings = true;
              setState(() {}); // si tu veux re-peindre, sinon pas indispensable
            });
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  Text(
                    'Coordonnées du club (utilisées pour tous les terrains)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _latCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Latitude *',
                      hintText: 'Ex: 43.552847 (Cannes)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      signed: true, decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[-0-9\.,]')),
                    ],
                    validator: _validateLat,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _lonCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Longitude *',
                      hintText: 'Ex: 7.017369 (Cannes)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      signed: true, decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[-0-9\.,]')),
                    ],
                    validator: _validateLon,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check),
                    label: const Text('Enregistrer'),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: _delete,
                    icon: const Icon(Icons.delete),
                    label: const Text('Supprimer la coordonnée'),
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'Gestion des données',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.stadium),
                    title: const Text('Gérer les terrains'),
                    subtitle: const Text('Ajouter, modifier ou supprimer des courts'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CourtManagementScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.science),
                    title: const Text('Générer les données de test (Seed)'),
                    subtitle: const Text('Ajoute des terrains par défaut'),
                    onTap: _seedData,
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Erreur: $e')),
      ),
    );
  }
}
