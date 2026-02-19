import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/terrain.dart';
import '../../domain/entities/maintenance.dart';
import '../providers/maintenance_provider.dart';
import '../../domain/entities/weather_snapshot.dart';
import '../../domain/services/weather_rules.dart';
import '../providers/weather_providers.dart';
import '../widgets/weather_badge.dart';

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
  WeatherSnapshot? _weather;
  double? _precip24h;
  bool? _frozen;
  bool? _unplayable;

  final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    final m = widget.maintenance;
    if (m != null) {
      _type = m.type;
      _commentaire = m.commentaire;
      _date = DateTime.fromMillisecondsSinceEpoch(m.date);
      _sacsManto = m.sacsMantoUtilises;
      _sacsSottomanto = m.sacsSottomantoUtilises;
      _sacsSilice = m.sacsSiliceUtilises;
    } else {
      _type = '';
      _date = DateTime.now();
      _sacsManto = 0;
      _sacsSottomanto = 0;
      _sacsSilice = 0;
    }
  }

  Future<void> _loadWeather(WidgetRef ref) async {
    final lat = widget.terrain.latitude;
    final lon = widget.terrain.longitude;

    if (lat == null || lon == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coordonnées du terrain manquantes')),
      );
      return;
    }

    final computed = await ref.read(
      weatherForTerrainProvider((
        lat: lat,
        lon: lon,
        type: widget.terrain.type,
      )).future,
    );

    setState(() {
      _weather = computed.context.snapshot;
      _precip24h = computed.context.precipitationLast24h;
      _frozen = computed.frozen;
      _unplayable = computed.unplayable;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  String? _validateType(String? value, {required bool isDur}) {
    if (value == null || value.trim().isEmpty) {
      return 'Le type est requis';
    }
    if (isDur) {
      // liste simple (insensible à la casse)
      const interdits = <String>{
        'recharge',
        'compactage',
        'décompactage',
        'decompactage',
        'travail de ligne',
      };
      final v = value.toLowerCase().trim();
      if (interdits.contains(v)) {
        return 'Type non autorisé pour terrains durs';
      }
    }
    return null;
  }

  String? _validateRequiredInt(String? value) {
    if (value == null || value.isEmpty) return 'Requis';
    final n = int.tryParse(value);
    if (n == null || n < 0) return 'Nombre valide requis';
    return null;
  }

  Future<void> _save(WidgetRef ref) async {
    // ⛔️ Corrige le bug : ne PAS save si invalide
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final maintenance = Maintenance(
      id: widget.maintenance?.id,
      terrainId: widget.terrain.id,
      type: _type.trim(),
      commentaire: (_commentaire?.trim().isEmpty ?? true)
          ? null
          : _commentaire!.trim(),
      date: _date.millisecondsSinceEpoch,
      sacsMantoUtilises: _sacsManto,
      sacsSottomantoUtilises: _sacsSottomanto,
      sacsSiliceUtilises: _sacsSilice,
      weather: _weather, // ← snapshot météo (si présent)
      terrainGele: _frozen, // ← drapeau gel
      terrainImpraticable: _unplayable, // ← drapeau impraticable
    );

    try {
      final notifier = ref.read(maintenanceNotifierProvider.notifier);
      if (widget.maintenance != null) {
        await notifier.updateMaintenance(maintenance);
      } else {
        await notifier.addMaintenance(maintenance);
      }

      // 👉 renvoyer un succès au parent ; la snackbar sera affichée côté parent
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

    return Consumer(
      builder: (context, ref, _) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
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

                    // TYPE (texte libre pour l’instant ; cf. commentaire Dropdown plus bas)
                    DropdownButtonFormField<String>(
                      value: _type.isEmpty ? null : _type,
                      decoration: const InputDecoration(
                        labelText: 'Type de maintenance *',
                        border: OutlineInputBorder(),
                      ),
                      items: types
                          .map(
                            (t) => DropdownMenuItem(value: t, child: Text(t)),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => _type = value ?? '');
                      },
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Le type est requis'
                          : null,
                      onSaved: (value) => _type = value!,
                    ),

                    const SizedBox(height: 16),

                    // DATE (readOnly + picker)
                    TextFormField(
                      readOnly: true,
                      controller: TextEditingController(
                        text: _dateFormat.format(_date),
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Date *',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: _pickDate,
                    ),

                    const SizedBox(height: 16),

                    // COMMENTAIRE
                    TextFormField(
                      initialValue: _commentaire,
                      decoration: const InputDecoration(
                        labelText: 'Commentaire (optionnel)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      onSaved: (v) => _commentaire = v?.trim(),
                    ),

                    const SizedBox(height: 16),

                    // ... juste après le champ "Commentaire"
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Météo au moment de la maintenance',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _loadWeather(ref),
                          icon: const Icon(Icons.cloud_sync),
                          label: const Text('Récupérer'),
                        ),
                      ],
                    ),

                    if (_weather != null) ...[
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              WeatherBadge(
                                frozen: _frozen ?? false,
                                unplayable: _unplayable ?? false,
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                runSpacing: 6,
                                children: [
                                  _Info(
                                    'Température',
                                    '${_weather!.temperature.toStringAsFixed(1)} °C',
                                  ),
                                  _Info('Humidité', '${_weather!.humidity}%'),
                                  _Info(
                                    'Vent',
                                    '${_weather!.windSpeed.toStringAsFixed(1)} km/h',
                                  ),
                                  _Info(
                                    'Pluie (instant)',
                                    '${_weather!.precipitation.toStringAsFixed(2)} mm',
                                  ),
                                  if (_precip24h != null)
                                    _Info(
                                      'Pluie 24h',
                                      '${_precip24h!.toStringAsFixed(2)} mm',
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    // MATÉRIAUX SELON LE TYPE DE TERRAIN
                    if (isTerreBattue) ...[
                      TextFormField(
                        initialValue: _sacsManto.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Sacs Manto utilisés *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          signed: false,
                          decimal: false,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: _validateRequiredInt,
                        onSaved: (v) => _sacsManto = int.tryParse(v ?? '') ?? 0,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _sacsSottomanto.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Sacs Sottomanto utilisés *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          signed: false,
                          decimal: false,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: _validateRequiredInt,
                        onSaved: (v) =>
                            _sacsSottomanto = int.tryParse(v ?? '') ?? 0,
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Note: la silice n’est pas autorisée pour les terrains en terre battue',
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
                        keyboardType: const TextInputType.numberWithOptions(
                          signed: false,
                          decimal: false,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: _validateRequiredInt,
                        onSaved: (v) =>
                            _sacsSilice = int.tryParse(v ?? '') ?? 0,
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Note: manto et sottomanto ne sont pas autorisés pour les terrains synthétiques',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ] else if (isDur) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Note: sur terrain dur, aucun matériau (manto, sottomanto, silice) n’est autorisé.\n'
                        'Types interdits: Recharge, Compactage, Décompactage, Travail de ligne.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
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

class _Info extends StatelessWidget {
  final String k;
  final String v;
  const _Info(this.k, this.v);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$k: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(v),
        ],
      ),
    );
  }
}
