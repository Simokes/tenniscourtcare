import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/event_providers.dart';
import '../../providers/terrain_provider.dart';
import '../../../domain/entities/app_event.dart';

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

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );

    if (time == null) return;

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
        // Ensure end is after start
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
    final dateFormat = DateFormat('EEE d MMM yyyy HH:mm', 'fr_FR');
    final terrainsAsync = ref.watch(terrainsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.eventToEdit == null ? 'Nouvel Événement' : 'Modifier l\'Événement'),
        actions: [
          if (widget.eventToEdit != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titre',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Date Times
            ListTile(
              title: const Text('Début'),
              subtitle: Text(dateFormat.format(_startTime)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDateTime(true),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300)),
            ),
            const SizedBox(height: 12),
            ListTile(
              title: const Text('Fin'),
              subtitle: Text(dateFormat.format(_endTime)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDateTime(false),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300)),
            ),

            const SizedBox(height: 24),
            const Text('Couleur', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _availableColors.map((color) {
                  // ignore: deprecated_member_use
                  final isSelected = _selectedColor == color.value;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      // ignore: deprecated_member_use
                      onTap: () => setState(() => _selectedColor = color.value),
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: Colors.black, width: 3) : null,
                        ),
                        child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),
            const Text('Terrains concernés', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            terrainsAsync.when(
              data: (terrains) {
                if (terrains.isEmpty) return const Text('Aucun terrain configuré.');
                return Wrap(
                  spacing: 8,
                  children: terrains.map((terrain) {
                    final isSelected = _selectedTerrainIds.contains(terrain.id);
                    return FilterChip(
                      label: Text(terrain.nom),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedTerrainIds.add(terrain.id);
                          } else {
                            _selectedTerrainIds.remove(terrain.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (err, _) => Text('Erreur: $err'),
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('ENREGISTRER'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
