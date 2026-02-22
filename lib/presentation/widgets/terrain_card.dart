import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/terrain.dart';
import '../providers/maintenance_provider.dart';

class TerrainCard extends ConsumerWidget {
  final Terrain terrain;
  final VoidCallback onTap;
  final VoidCallback onAddMaintenance;

  const TerrainCard({
    super.key,
    required this.terrain,
    required this.onTap,
    required this.onAddMaintenance,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch provider family
    final lastMajorAsync = ref.watch(lastMajorMaintenanceProvider(terrain.id));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      // Look 'Premium': rounded corners, subtle shadow
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  _TerrainIcon(type: terrain.type),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          terrain.nom,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          terrain.type.displayName,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onAddMaintenance,
                    icon: const Icon(Icons.add_circle_outline, size: 32),
                    color: Theme.of(context).colorScheme.primary,
                    tooltip: 'Ajouter une maintenance',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Last Major Maintenance Section
              Text(
                'Dernière grosse intervention :',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 6),

              lastMajorAsync.when(
                data: (maintenance) {
                  if (maintenance == null) {
                    return Row(
                      children: [
                         Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Aucune enregistrée',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                    );
                  }
                  final date = DateTime.fromMillisecondsSinceEpoch(maintenance.date);
                  // Ensure date formatting is initialized in main or handle locale
                  // Assuming default locale or system
                  final formattedDate = DateFormat.yMMMd('fr_FR').format(date);

                  return Row(
                    children: [
                      Icon(
                        Icons.history,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$formattedDate - ${maintenance.type}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, __) => const Text('Erreur de chargement'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TerrainIcon extends StatelessWidget {
  final TerrainType type;

  const _TerrainIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    // Use Theme colors or a dedicated palette
    switch (type) {
      case TerrainType.terreBattue:
        icon = Icons.landscape;
        color = Colors.orange.shade800;
        break;
      case TerrainType.synthetique:
        icon = Icons.layers;
        color = Colors.blue.shade700;
        break;
      case TerrainType.dur:
        icon = Icons.sports_tennis;
        color = Colors.blueGrey.shade700;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }
}
