import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/terrain.dart';
import '../../domain/entities/maintenance.dart';
import '../providers/maintenance_provider.dart';
import '../../domain/entities/weather_snapshot.dart';
import '../providers/weather_for_club_provider.dart';
import '../providers/app_settings_provider.dart';
import 'maintenance_type_selector.dart';
import 'quantity_selector.dart';
import 'weather_card.dart';
import 'premium/premium_card.dart';
import 'premium/premium_button.dart';
import 'premium/premium_text_form_field.dart';

class AddMaintenanceSheet extends ConsumerStatefulWidget {
  final Terrain terrain;
  final Maintenance? maintenance;

  const AddMaintenanceSheet({
    super.key,
    required this.terrain,
    this.maintenance,
  });

  @override
  ConsumerState<AddMaintenanceSheet> createState() => _AddMaintenanceSheetState();
}

class _AddMaintenanceSheetState extends ConsumerState<AddMaintenanceSheet> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();

  late String _type;
  late DateTime _date;
  late int _sacsManto;
  late int _sacsSottomanto;
  late int _sacsSilice;
  WeatherSnapshot? _weather;
  double? _precip24h;
  bool? _frozen;
  bool? _unplayable;

  final _dateFormat = DateFormat('dd MMM yyyy', 'fr_FR');

  @override
  void initState() {
    super.initState();
    final m = widget.maintenance;
    if (m != null) {
      _type = m.type;
      _commentController.text = m.commentaire ?? '';
      _date = DateTime.fromMillisecondsSinceEpoch(m.date);
      _sacsManto = m.sacsMantoUtilises;
      _sacsSottomanto = m.sacsSottomantoUtilises;
      _sacsSilice = m.sacsSiliceUtilises;
      _weather = m.weather;
      _frozen = m.terrainGele;
      _unplayable = m.terrainImpraticable;
    } else {
      _type = '';
      _date = DateTime.now();
      _sacsManto = 0;
      _sacsSottomanto = 0;
      _sacsSilice = 0;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadWeather() async {
    final clubLoc = ref.read(appSettingsProvider).value;
    if (clubLoc == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Définis d’abord les coordonnées du club dans Paramètres')),
      );
      return;
    }

    try {
      final computed = await ref.read(weatherForClubProvider(widget.terrain.type).future);
      setState(() {
        _weather = computed.context.snapshot;
        _precip24h = computed.context.precipitationLast24h;
        _frozen = computed.frozen;
        _unplayable = computed.unplayable;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur météo: $e')),
      );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_type.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un type de maintenance')),
      );
      return;
    }

    // Save form fields not needed for standard widgets, but good practice
    _formKey.currentState!.save();

    final maintenance = Maintenance(
      id: widget.maintenance?.id,
      terrainId: widget.terrain.id,
      type: _type.trim(),
      commentaire: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
      date: _date.millisecondsSinceEpoch,
      sacsMantoUtilises: _sacsManto,
      sacsSottomantoUtilises: _sacsSottomanto,
      sacsSiliceUtilises: _sacsSilice,
      weather: _weather,
      terrainGele: _frozen,
      terrainImpraticable: _unplayable,
    );

    try {
      final notifier = ref.read(maintenanceNotifierProvider.notifier);
      if (widget.maintenance != null) {
        await notifier.updateMaintenance(maintenance);
      } else {
        await notifier.addMaintenance(maintenance);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTerreBattue = widget.terrain.type == TerrainType.terreBattue;
    final isSynthetique = widget.terrain.type == TerrainType.synthetique;
    final isDur = widget.terrain.type == TerrainType.dur;
    final types = allowedTypesFor(widget.terrain.type);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.maintenance != null
                            ? 'Modifier la maintenance'
                            : 'Nouvelle maintenance',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              const Divider(),

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Type Selector
                        Text(
                          'Type d\'intervention',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 12),
                        MaintenanceTypeSelector(
                          selectedType: _type.isEmpty ? null : _type,
                          types: types,
                          onSelected: (val) => setState(() => _type = val),
                        ),

                        const SizedBox(height: 24),

                        // Date Picker Row
                        PremiumCard(
                           padding: const EdgeInsets.all(4),
                           child: InkWell(
                            onTap: _pickDate,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_month, color: Colors.blueGrey),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Date de l\'intervention',
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                              color: Colors.grey.shade600,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _dateFormat.format(_date),
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Weather Section
                        if (_weather == null)
                          WeatherCard(
                            weather: null,
                            precip24h: null,
                            frozen: null,
                            unplayable: null,
                            onRefresh: _loadWeather,
                          )
                        else
                          WeatherCard(
                            weather: _weather,
                            precip24h: _precip24h,
                            frozen: _frozen,
                            unplayable: _unplayable,
                            onRefresh: _loadWeather,
                          ),

                        const SizedBox(height: 24),

                        // Materials Section (Conditionals)
                        if (!isDur) ...[
                          Text(
                            'Matériaux utilisés',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        if (isTerreBattue) ...[
                          QuantitySelector(
                            label: 'Manto',
                            value: _sacsManto,
                            onChanged: (val) => setState(() => _sacsManto = val),
                          ),
                          const SizedBox(height: 12),
                          QuantitySelector(
                            label: 'Sottomanto',
                            value: _sacsSottomanto,
                            onChanged: (val) => setState(() => _sacsSottomanto = val),
                          ),
                        ] else if (isSynthetique) ...[
                          QuantitySelector(
                            label: 'Silice',
                            value: _sacsSilice,
                            onChanged: (val) => setState(() => _sacsSilice = val),
                          ),
                        ],

                        if (isDur)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blueGrey.shade100),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.blueGrey.shade700),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Aucun matériau n\'est requis pour ce type de terrain.',
                                    style: TextStyle(color: Colors.blueGrey.shade800),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 24),

                        // Commentaire
                        PremiumTextFormField(
                          label: 'Notes & Commentaires',
                          controller: _commentController,
                          hint: 'Ajouter un commentaire...',
                        ),
                      ],
                    ),
                  ),
                ),
              ),

               Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: double.infinity,
                  child: PremiumButton(
                    label: 'Enregistrer',
                    onPressed: _save,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<String> allowedTypesFor(TerrainType t) {
    switch (t) {
      case TerrainType.terreBattue:
        return [
          'Arrosage',
          'Brossage',
          'Décompactage',
          'Recharge',
          'Travail de ligne',
          'Nivelage',
        ];
      case TerrainType.synthetique:
        return [
          'Brossage',
          'Répartition silice',
          'Aspiration',
          'Réparation couture',
        ];
      case TerrainType.dur:
        return ['Nettoyage', 'Balayage', 'Démoussage', 'Peinture'];
    }
  }
}
