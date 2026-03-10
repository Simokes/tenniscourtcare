import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tenniscourtcare/domain/entities/terrain.dart';
import 'package:tenniscourtcare/features/terrain/providers/terrain_provider.dart';

/// Bottom sheet pour fermer un terrain avec raison et duree estimee.
class TerrainClosureSheet extends ConsumerStatefulWidget {
  const TerrainClosureSheet({super.key, required this.terrain});

  final Terrain terrain;

  @override
  ConsumerState<TerrainClosureSheet> createState() =>
      _TerrainClosureSheetState();
}

class _TerrainClosureSheetState extends ConsumerState<TerrainClosureSheet> {
  TerrainClosureReason? _selectedReason;
  _ClosureDuration _selectedDuration = _ClosureDuration.indefinite;
  bool _isSaving = false;

  DateTime? get _computedClosureUntil {
    final now = DateTime.now();
    return switch (_selectedDuration) {
      _ClosureDuration.oneHour => now.add(const Duration(hours: 1)),
      _ClosureDuration.twoHours => now.add(const Duration(hours: 2)),
      _ClosureDuration.morning =>
        DateTime(now.year, now.month, now.day, 12, 0),
      _ClosureDuration.afternoon =>
        DateTime(now.year, now.month, now.day, 17, 0),
      _ClosureDuration.fullDay =>
        DateTime(now.year, now.month, now.day, 23, 59),
      _ClosureDuration.indefinite => null,
    };
  }

  Future<void> _confirm() async {
    if (_selectedReason == null) return;
    setState(() => _isSaving = true);
    try {
      await ref.read(terrainNotifierProvider.notifier).closeTerrain(
            terrain: widget.terrain,
            reason: _selectedReason!,
            closureUntil: _computedClosureUntil,
          );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Material(
      color: cs.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Fermer ${widget.terrain.nom}',
              style: tt.titleMedium,
            ),
            const SizedBox(height: 20),
            Text(
              'Raison',
              style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: TerrainClosureReason.values.map((r) {
                final selected = _selectedReason == r;
                return ChoiceChip(
                  avatar: Icon(r.icon, size: 16),
                  label: Text(r.displayName),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedReason = r),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text(
              'Duree estimee',
              style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _ClosureDuration.values.map((d) {
                final selected = _selectedDuration == d;
                return ChoiceChip(
                  label: Text(d.label),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedDuration = d),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _selectedReason == null || _isSaving ? null : _confirm,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Fermer le terrain'),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

enum _ClosureDuration {
  oneHour,
  twoHours,
  morning,
  afternoon,
  fullDay,
  indefinite;

  String get label => switch (this) {
        _ClosureDuration.oneHour => '1h',
        _ClosureDuration.twoHours => '2h',
        _ClosureDuration.morning => 'Matinee',
        _ClosureDuration.afternoon => 'Apres-midi',
        _ClosureDuration.fullDay => 'Journee',
        _ClosureDuration.indefinite => 'Indefinie',
      };
}
