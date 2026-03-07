import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../domain/entities/terrain.dart';
import '../../../../domain/entities/maintenance.dart';
import '../../providers/maintenance_provider.dart';
import '../../../../domain/entities/weather_snapshot.dart';
import '../../../weather/providers/weather_for_club_provider.dart';
import './maintenance_type_selector.dart';
import '../../../../shared/widgets/common/quantity_selector.dart';
import '../../../weather/presentation/widgets/weather_card.dart';
import '../../../../shared/widgets/premium/premium_card.dart';
import '../../../../shared/widgets/premium/premium_button.dart';
import 'dart:io';
import '../../../../shared/widgets/premium/premium_text_form_field.dart';
import '../../providers/refill_recommendation_provider.dart';
import './refill_recommendation_card.dart';
import '../../../../shared/services/image_picker_service.dart';
import '../../../../shared/widgets/common/image_viewer_dialog.dart';
import '../../../../domain/enums/maintenance_duration.dart';
import '../../../admin/providers/club_info_provider.dart';
import '../../../terrain/providers/terrain_provider.dart';

class AddMaintenanceSheet extends ConsumerStatefulWidget {
  final Terrain? terrain;
  final Maintenance? existingMaintenance;
  final bool forceCompleteMode;
  final bool rescheduleMode;
  final bool urgentMode;

  const AddMaintenanceSheet({
    super.key,
    this.terrain,
    this.existingMaintenance,
    this.forceCompleteMode = false,
    this.rescheduleMode = false,
    this.urgentMode = false,
  });

  @override
  ConsumerState<AddMaintenanceSheet> createState() =>
      _AddMaintenanceSheetState();
}

class _AddMaintenanceSheetState extends ConsumerState<AddMaintenanceSheet> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();

  late String _type;
  late DateTime _date;
  late int _sacsManto;
  late int _sacsSottomanto;
  late int _sacsSilice;
  String? _imagePath;
  WeatherSnapshot? _weather;
  double? _precip24h;
  bool? _frozen;
  bool? _unplayable;
  late bool _isPlanned;

  Terrain? _selectedTerrain;
  MaintenanceDuration _duration = MaintenanceDuration.oneHour;
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);

  final _dateFormat = DateFormat('dd MMM yyyy', 'fr_FR');
  final _imagePickerService = ImagePickerService();

  @override
  void initState() {
    super.initState();
    _selectedTerrain = widget.terrain;
    final m = widget.existingMaintenance;
    if (m != null) {
      _type = m.type;
      _commentController.text = m.commentaire ?? '';
      _date = DateTime.fromMillisecondsSinceEpoch(m.date);
      _sacsManto = m.sacsMantoUtilises;
      _sacsSottomanto = m.sacsSottomantoUtilises;
      _sacsSilice = m.sacsSiliceUtilises;
      _imagePath = m.imagePath;
      _weather = m.weather;
      _frozen = m.terrainGele;
      _unplayable = m.terrainImpraticable;
      _isPlanned = widget.forceCompleteMode ? false : m.isPlanned;

      // Determine duration strategy based on stored values vs opening hours could be complex.
      // For editing, we'll default to oneHour and set time picker to match if it doesn't align cleanly.
      _duration = MaintenanceDuration.oneHour;
      _startTime = TimeOfDay(hour: m.startHour, minute: 0);
    } else {
      _type = '';
      _date = DateTime.now();
      _sacsManto = 0;
      _sacsSottomanto = 0;
      _sacsSilice = 0;
      _isPlanned = false;
    }

    if (widget.forceCompleteMode) {
      _date = DateTime.now();
    }

    if (widget.rescheduleMode) {
      _isPlanned = true;
    }

    if (widget.urgentMode) {
      _isPlanned = false;
      _date = DateTime.now();
    }
  }

  Future<void> _pickImage(bool fromCamera) async {
    try {
      final path = fromCamera
          ? await _imagePickerService.pickImageFromCamera()
          : await _imagePickerService.pickImageFromGallery();

      if (path != null) {
        setState(() => _imagePath = path);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection de l\'image: $e')),
      );
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadWeather() async {
    if (_selectedTerrain == null) return;
    try {
      final computed = await ref.read(
        weatherForClubProvider(_selectedTerrain!.type).future,
      );

      if (computed == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Définis d’abord les coordonnées du club dans Paramètres',
            ),
          ),
        );
        return;
      }

      setState(() {
        _weather = computed.context.snapshot;
        _precip24h = computed.context.precipitationLast24h;
        _frozen = computed.frozen;
        _unplayable = computed.unplayable;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur météo: $e')));
    }
  }

  Future<void> _delete() async {
    final firebaseId = widget.existingMaintenance?.firebaseId;
    if (firebaseId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: const Text(
          'Voulez-vous vraiment supprimer cette maintenance ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref
            .read(maintenanceNotifierProvider.notifier)
            .deleteMaintenance(firebaseId);
        if (mounted) Navigator.of(context).pop(true);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: _isPlanned || widget.rescheduleMode
          ? DateTime.now().add(const Duration(days: 365))
          : DateTime.now(),
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

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedTerrain == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un terrain')),
      );
      return;
    }

    if (!widget.rescheduleMode && _type.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un type de maintenance'),
        ),
      );
      return;
    }

    // Save form fields not needed for standard widgets, but good practice
    _formKey.currentState!.save();

    final clubInfo = ref.read(clubInfoProvider).valueOrNull;
    final openingHour = clubInfo?.openingHour ?? 8;
    final closingHour = clubInfo?.closingHour ?? 21;

    final computedStartHour = _duration == MaintenanceDuration.oneHour
        ? _startTime.hour
        : _duration.startHour(openingHour);

    final computedDurationMinutes = _duration == MaintenanceDuration.oneHour
        ? 60
        : _duration.durationMinutes(openingHour, closingHour);

    try {
      final notifier = ref.read(maintenanceNotifierProvider.notifier);

      if (widget.rescheduleMode && widget.existingMaintenance != null) {
        final updated = widget.existingMaintenance!.copyWith(
          date: _date.millisecondsSinceEpoch,
          startHour: computedStartHour,
          durationMinutes: computedDurationMinutes,
          updatedAt: DateTime.now(),
        );
        await notifier.updateMaintenance(updated);
      } else {
        final maintenance = Maintenance(
          id: widget.existingMaintenance?.id,
          terrainId: _selectedTerrain!.id,
          type: widget.forceCompleteMode
              ? widget.existingMaintenance?.type ?? _type.trim()
              : _type.trim(),
          commentaire: _commentController.text.trim().isEmpty
              ? null
              : _commentController.text.trim(),
          date: widget.forceCompleteMode
              ? DateTime.now().millisecondsSinceEpoch
              : _date.millisecondsSinceEpoch,
          sacsMantoUtilises: _sacsManto,
          sacsSottomantoUtilises: _sacsSottomanto,
          sacsSiliceUtilises: _sacsSilice,
          isPlanned: _isPlanned,
          startHour: computedStartHour,
          durationMinutes: computedDurationMinutes,
          imagePath: _imagePath,
          weather: _weather,
          terrainGele: _frozen,
          terrainImpraticable: _unplayable,
          createdAt: widget.existingMaintenance?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
          firebaseId: widget.existingMaintenance?.firebaseId,
        );

        if (widget.forceCompleteMode &&
            widget.existingMaintenance?.firebaseId != null) {
          await notifier.markAsCompleted(
            firebaseId: widget.existingMaintenance!.firebaseId!,
            completed: maintenance,
          );
        } else if (widget.existingMaintenance != null) {
          await notifier.updateMaintenance(maintenance);
        } else {
          await notifier.addMaintenance(maintenance);
        }
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
    // Determine current terrain properties based on selection
    final isTerreBattue = _selectedTerrain?.type == TerrainType.terreBattue;
    final isSynthetique = _selectedTerrain?.type == TerrainType.synthetique;
    final isDur = _selectedTerrain?.type == TerrainType.dur;
    final types = _selectedTerrain != null
        ? allowedTypesFor(_selectedTerrain!.type)
        : <String>[];

    final allTerrains = ref.watch(terrainsProvider).valueOrNull ?? [];

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.urgentMode
                            ? 'Signaler urgence'
                            : widget.forceCompleteMode
                            ? 'Effectuer maintenance'
                            : widget.existingMaintenance != null
                            ? 'Modifier la maintenance'
                            : 'Nouvelle maintenance',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (widget.existingMaintenance?.firebaseId != null &&
                        !widget.forceCompleteMode)
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: _delete,
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
                        if (widget.terrain == null) ...[
                          Text(
                            'Sélectionnez le terrain',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<Terrain>(
                            initialValue: _selectedTerrain,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: allTerrains.map((t) {
                              return DropdownMenuItem(
                                value: t,
                                child: Text(t.nom),
                              );
                            }).toList(),
                            onChanged: widget.existingMaintenance != null
                                ? null
                                : (val) {
                                    setState(() {
                                      _selectedTerrain = val;
                                      _type =
                                          ''; // Reset type as options change
                                    });
                                  },
                          ),
                          const SizedBox(height: 24),
                        ],

                        if (!widget.forceCompleteMode &&
                            !widget.rescheduleMode) ...[
                          Center(
                            child: SegmentedButton<bool>(
                              segments: const [
                                ButtonSegment(
                                  value: false,
                                  label: Text('Réalisée maintenant'),
                                  icon: Icon(Icons.check_circle_outline),
                                ),
                                ButtonSegment(
                                  value: true,
                                  label: Text('Planifier'),
                                  icon: Icon(Icons.schedule),
                                ),
                              ],
                              selected: {_isPlanned},
                              onSelectionChanged: (Set<bool> newSelection) {
                                setState(() {
                                  _isPlanned = newSelection.first;
                                  // Reset date appropriately
                                  if (!_isPlanned &&
                                      _date.isAfter(DateTime.now())) {
                                    _date = DateTime.now();
                                  }
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        if (_selectedTerrain != null && !widget.urgentMode) ...[
                          // Duration Selector
                          Text(
                            'Durée de l\'intervention',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SegmentedButton<MaintenanceDuration>(
                              segments: MaintenanceDuration.values.map((d) {
                                return ButtonSegment(
                                  value: d,
                                  label: Text(
                                    d.label,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              }).toList(),
                              selected: {_duration},
                              onSelectionChanged:
                                  (Set<MaintenanceDuration> newSelection) {
                                    setState(() {
                                      _duration = newSelection.first;
                                    });
                                  },
                            ),
                          ),
                          const SizedBox(height: 24),

                          if (_duration == MaintenanceDuration.oneHour) ...[
                            PremiumCard(
                              padding: const EdgeInsets.all(4),
                              child: InkWell(
                                onTap: _pickTime,
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time,
                                        color: Colors.blueGrey,
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Heure de début',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  color: Colors.grey.shade600,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _startTime.format(context),
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ],

                        if (!widget.rescheduleMode) ...[
                          // Type Selector
                          Text(
                            'Type d\'intervention',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          MaintenanceTypeSelector(
                            selectedType: _type.isEmpty ? null : _type,
                            types: types,
                            onSelected: (val) => setState(() => _type = val),
                          ),

                          const SizedBox(height: 24),
                        ],

                        // Date Picker Row
                        if (!widget.urgentMode) ...[
                          PremiumCard(
                            padding: const EdgeInsets.all(4),
                            child: InkWell(
                              onTap: _pickDate,
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_month,
                                      color: Colors.blueGrey,
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Date de l\'intervention',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color: Colors.grey.shade600,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _dateFormat.format(_date),
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),
                        ],

                        if (!_isPlanned) ...[
                          // Weather Section
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
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                          ],

                          if (isTerreBattue) ...[
                            // SMART REFILL RECOMMENDATION
                            if (_type == 'Recharge')
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: ref
                                    .watch(
                                      refillRecommendationProvider(
                                        _selectedTerrain!.id,
                                      ),
                                    )
                                    .when(
                                      data: (recommendation) =>
                                          RefillRecommendationCard(
                                            recommendation: recommendation,
                                          ),
                                      loading: () => const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                      error: (err, stack) =>
                                          const SizedBox.shrink(), // Silent error for cleaner UI
                                    ),
                              ),

                            QuantitySelector(
                              label: 'Manto',
                              value: _sacsManto,
                              onChanged: (val) =>
                                  setState(() => _sacsManto = val),
                            ),
                            const SizedBox(height: 12),
                            QuantitySelector(
                              label: 'Sottomanto',
                              value: _sacsSottomanto,
                              onChanged: (val) =>
                                  setState(() => _sacsSottomanto = val),
                            ),
                          ] else if (isSynthetique) ...[
                            QuantitySelector(
                              label: 'Silice',
                              value: _sacsSilice,
                              onChanged: (val) =>
                                  setState(() => _sacsSilice = val),
                            ),
                          ],

                          if (isDur)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outlineVariant,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Aucun matériau n\'est requis pour ce type de terrain.',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 24),

                          // Photo de preuve
                          Text(
                            'Photo de preuve',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          if (_imagePath != null)
                            Stack(
                              alignment: Alignment.topRight,
                              children: [
                                GestureDetector(
                                  onTap: () => showDialog(
                                    context: context,
                                    builder: (context) => ImageViewerDialog(
                                      imagePath: _imagePath!,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      File(_imagePath!),
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      setState(() => _imagePath = null),
                                  icon: Icon(
                                    Icons.remove_circle,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.surface,
                                  ),
                                ),
                              ],
                            )
                          else
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _pickImage(true),
                                    icon: const Icon(Icons.camera_alt),
                                    label: const Text('Caméra'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _pickImage(false),
                                    icon: const Icon(Icons.photo_library),
                                    label: const Text('Galerie'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],

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
                    label: _isPlanned ? 'Planifier' : 'Enregistrer',
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
