import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/event_providers.dart';
import '../../providers/terrain_provider.dart';
import '../../../domain/entities/app_event.dart';
import '../../widgets/premium/premium_card.dart';
import '../../widgets/premium/premium_text_form_field.dart';
import '../../widgets/premium/premium_button.dart';

class AddEditEventScreen extends ConsumerStatefulWidget {
  final AppEvent? eventToEdit;

  const AddEditEventScreen({super.key, this.eventToEdit});

  @override
  ConsumerState<AddEditEventScreen> createState() => _AddEditEventScreenState();
}

class _AddEditEventScreenState extends ConsumerState<AddEditEventScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descController;
  late DateTime _startTime;
  late DateTime _endTime;
  late int _selectedColor;
  final List<int> _selectedTerrainIds = [];

  final List<Color> _availableColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.amber,
  ];

  @override
  void initState() {
    super.initState();
    final event = widget.eventToEdit;

    _titleController = TextEditingController(text: event?.title ?? '');
    _descController = TextEditingController(text: event?.description ?? '');

    final now = DateTime.now();
    _startTime = event?.startTime ?? DateTime(now.year, now.month, now.day, 9, 0);
    _endTime = event?.endTime ?? _startTime.add(const Duration(hours: 1));

    // ignore: deprecated_member_use
    _selectedColor = event?.color ?? Colors.blue.value;

    if (event != null) {
      _selectedTerrainIds.addAll(event.terrainIds);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(bool isStart) async {
    final initialDate = isStart ? _startTime : _endTime;

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('fr', 'FR'),
    );

    if (date == null) return;
    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );

    if (time == null) return;
    if (!mounted) return;

    final newDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() {
      if (isStart) {
        _startTime = newDateTime;
        // Ensure end is after start if needed, but let's be flexible or enforce duration.
        // Enforcing end > start:
        if (_endTime.isBefore(_startTime)) {
          _endTime = _startTime.add(const Duration(hours: 1));
        }
      } else {
        _endTime = newDateTime;
        // Ensure start is before end
        if (_startTime.isAfter(_endTime)) {
          _startTime = _endTime.subtract(const Duration(hours: 1));
        }
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final event = AppEvent(
      id: widget.eventToEdit?.id,
      title: _titleController.text.trim(),
      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      startTime: _startTime,
      endTime: _endTime,
      color: _selectedColor,
      terrainIds: _selectedTerrainIds,
    );

    final repo = ref.read(eventRepositoryProvider);

    try {
      if (widget.eventToEdit == null) {
        await repo.addEvent(event);
      } else {
        await repo.updateEvent(event);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Événement enregistré')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _delete() async {
    if (widget.eventToEdit?.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: const Text('Voulez-vous vraiment supprimer cet événement ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(eventRepositoryProvider).deleteEvent(widget.eventToEdit!.id!);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Événement supprimé')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE d MMM yyyy', 'fr_FR');
    final timeFormat = DateFormat('HH:mm', 'fr_FR');
    final terrainsAsync = ref.watch(terrainsProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(widget.eventToEdit == null ? 'Nouvel Événement' : 'Modifier l\'Événement'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (widget.eventToEdit != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Details Section
              PremiumCard(
                child: Column(
                  children: [
                    PremiumTextFormField(
                      label: 'Titre',
                      hint: 'Tournoi, Match, Réunion...',
                      controller: _titleController,
                      validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                    ),
                    const SizedBox(height: 16),
                    PremiumTextFormField(
                      label: 'Description',
                      hint: 'Détails supplémentaires...',
                      controller: _descController,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Timing Section
              PremiumCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Horaires',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildDateTimeTile('Début', _startTime, dateFormat, timeFormat, () => _pickDateTime(true))),
                        const SizedBox(width: 12),
                        Icon(Icons.arrow_forward, color: Colors.grey.shade400),
                        const SizedBox(width: 12),
                        Expanded(child: _buildDateTimeTile('Fin', _endTime, dateFormat, timeFormat, () => _pickDateTime(false))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Options Section (Color & Terrains)
              PremiumCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Couleur',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _availableColors.map((color) {
                          // ignore: deprecated_member_use
                          final isSelected = _selectedColor == color.value;
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: InkWell(
                              // ignore: deprecated_member_use
                              onTap: () => setState(() => _selectedColor = color.value),
                              customBorder: const CircleBorder(),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: isSelected ? 48 : 36,
                                height: isSelected ? 48 : 36,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                                  boxShadow: isSelected ? [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    )
                                  ] : null,
                                ),
                                child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Terrains concernés',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 12),
                    terrainsAsync.when(
                      data: (terrains) {
                        if (terrains.isEmpty) return const Text('Aucun terrain configuré.', style: TextStyle(color: Colors.grey));
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: terrains.map((terrain) {
                            final isSelected = _selectedTerrainIds.contains(terrain.id);
                            return FilterChip(
                              label: Text(terrain.nom),
                              selected: isSelected,
                              selectedColor: Theme.of(context).colorScheme.primaryContainer,
                              checkmarkColor: Theme.of(context).colorScheme.primary,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedTerrainIds.add(terrain.id);
                                  } else {
                                    _selectedTerrainIds.remove(terrain.id);
                                  }
                                });
                              },
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected
                                    ? Colors.transparent
                                    : Colors.grey.shade300,
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (err, _) => Text('Erreur: $err'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: PremiumButton(
                  label: 'ENREGISTRER',
                  onPressed: _save,
                  icon: Icons.check,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimeTile(
    String label,
    DateTime dateTime,
    DateFormat dateFormat,
    DateFormat timeFormat,
    VoidCallback onTap
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              timeFormat.format(dateTime),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              dateFormat.format(dateTime),
              style: TextStyle(color: Colors.grey.shade800, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
