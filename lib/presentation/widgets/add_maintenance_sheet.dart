import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/terrain.dart';
import '../../domain/entities/maintenance.dart';
import '../providers/maintenance_provider.dart';

class AddMaintenanceSheet extends StatefulWidget {
  final Terrain terrain;
  final Maintenance? maintenance;

  const AddMaintenanceSheet({
    super.key,
    required this.terrain,
    this.maintenance,
  });

  @override
  State<AddMaintenanceSheet> createState() => _AddMaintenanceSheetState();
}

class _AddMaintenanceSheetState extends State<AddMaintenanceSheet> {
  final _formKey = GlobalKey<FormState>();
  late String _type;
  String? _commentaire;
  late DateTime _date;
  late int _sacsManto;
  late int _sacsSottomanto;
  late int _sacsSilice;

  @override
  void initState() {
    super.initState();
    if (widget.maintenance != null) {
      _type = widget.maintenance!.type;
      _commentaire = widget.maintenance!.commentaire;
      _date = DateTime.fromMillisecondsSinceEpoch(widget.maintenance!.date);
      _sacsManto = widget.maintenance!.sacsMantoUtilises;
      _sacsSottomanto = widget.maintenance!.sacsSottomantoUtilises;
      _sacsSilice = widget.maintenance!.sacsSiliceUtilises;
    } else {
      _type = '';
      _date = DateTime.now();
      _sacsManto = 0;
      _sacsSottomanto = 0;
      _sacsSilice = 0;
    }
  }

  Future<void> _save(WidgetRef ref) async {
    if (!_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      return;
    }
    _formKey.currentState!.save();

    final maintenance = Maintenance(
      id: widget.maintenance?.id,
      terrainId: widget.terrain.id,
      type: _type,
      commentaire: _commentaire?.isEmpty ?? true ? null : _commentaire,
      date: _date.millisecondsSinceEpoch,
      sacsMantoUtilises: _sacsManto,
      sacsSottomantoUtilises: _sacsSottomanto,
      sacsSiliceUtilises: _sacsSilice,
    );

    try {
      if (widget.maintenance != null) {
        await ref
            .read(maintenanceNotifierProvider.notifier)
            .updateMaintenance(maintenance);
      } else {
        await ref
            .read(maintenanceNotifierProvider.notifier)
            .addMaintenance(maintenance);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.maintenance != null
                  ? 'Maintenance mise à jour'
                  : 'Maintenance ajoutée',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTerreBattue = widget.terrain.type == TerrainType.terreBattue;
    final isSynthetique = widget.terrain.type == TerrainType.synthetique;
    final isDur = widget.terrain.type == TerrainType.dur;

    return Consumer(
      builder: (context, ref, _) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.maintenance != null
                        ? 'Modifier la maintenance'
                        : 'Nouvelle maintenance',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  // Type de maintenance
                  TextFormField(
                    initialValue: _type,
                    decoration: const InputDecoration(
                      labelText: 'Type de maintenance *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Le type est requis';
                      }
                      // Validation pour terrains durs
                      if (isDur) {
                        const typesInterdits = [
                          'Recharge',
                          'recharge',
                          'Compactage',
                          'compactage',
                          'Décompactage',
                          'décompactage',
                          'Travail de ligne',
                          'travail de ligne',
                        ];
                        if (typesInterdits.contains(value)) {
                          return 'Ce type de maintenance n\'est pas autorisé pour les terrains durs';
                        }
                      }
                      return null;
                    },
                    onSaved: (value) => _type = value!,
                  ),
                  const SizedBox(height: 16),
                  // Date
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          _date = picked;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date *',
                        border: OutlineInputBorder(),
                      ),
                      child: Text('${_date.day}/${_date.month}/${_date.year}'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Commentaire
                  TextFormField(
                    initialValue: _commentaire,
                    decoration: const InputDecoration(
                      labelText: 'Commentaire (optionnel)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    onSaved: (value) => _commentaire = value,
                  ),
                  const SizedBox(height: 16),
                  // Matériaux selon le type de terrain
                  if (isTerreBattue) ...[
                    TextFormField(
                      initialValue: _sacsManto.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Sacs Manto utilisés *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Requis';
                        }
                        final intValue = int.tryParse(value);
                        if (intValue == null || intValue < 0) {
                          return 'Nombre valide requis';
                        }
                        return null;
                      },
                      onSaved: (value) => _sacsManto = int.parse(value ?? '0'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: _sacsSottomanto.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Sacs Sottomanto utilisés *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Requis';
                        }
                        final intValue = int.tryParse(value);
                        if (intValue == null || intValue < 0) {
                          return 'Nombre valide requis';
                        }
                        return null;
                      },
                      onSaved: (value) =>
                          _sacsSottomanto = int.parse(value ?? '0'),
                    ),
                    // Masquer silice pour terre battue
                    const SizedBox(height: 8),
                    Text(
                      'Note: La silice n\'est pas autorisée pour les terrains en terre battue',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ] else if (isSynthetique) ...[
                    TextFormField(
                      initialValue: _sacsSilice.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Sacs Silice utilisés *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Requis';
                        }
                        final intValue = int.tryParse(value);
                        if (intValue == null || intValue < 0) {
                          return 'Nombre valide requis';
                        }
                        return null;
                      },
                      onSaved: (value) => _sacsSilice = int.parse(value ?? '0'),
                    ),
                    // Masquer manto et sottomanto pour synthétique
                    const SizedBox(height: 8),
                    Text(
                      'Note: Manto et Sottomanto ne sont pas autorisés pour les terrains synthétiques',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ] else if (isDur) ...[
                    // Pour les terrains durs : aucun matériau autorisé
                    const SizedBox(height: 8),
                    Text(
                      'Note: Les terrains durs ne peuvent pas utiliser de matériaux (manto, sottomanto ou silice).\n'
                      'Les types de maintenance suivants sont interdits : Recharge, Compactage, Décompactage, Travail de ligne.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Boutons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Annuler'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _save(ref),
                        child: const Text('Enregistrer'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
