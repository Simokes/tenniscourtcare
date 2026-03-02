import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/terrain_repository_impl.dart';
import '../../domain/entities/terrain.dart';
import '../../domain/repositories/terrain_repository.dart';
import 'database_provider.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

// Repository Provider
final terrainRepositoryProvider = Provider<TerrainRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return TerrainRepositoryImpl(db: db, fs: FirebaseFirestore.instance);
});

final terrainsProvider = StreamProvider<List<Terrain>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllTerrains();
});

final terrainProvider = FutureProvider.family<Terrain?, int>((ref, id) async {
  final terrains = await ref.watch(terrainsProvider.future);
  try {
    return terrains.firstWhere((t) => t.id == id);
  } catch (e) {
    return null;
  }
});

/// Calculer le nombre de terrains jouables
final playableTerrainCountProvider = FutureProvider<int>((ref) async {
  final terrains = await ref.watch(terrainsProvider.future);
  return terrains.where((t) => t.status == TerrainStatus.playable).length;
});

/// Calculer le nombre de terrains en maintenance
final maintenanceTerrainCountProvider = FutureProvider<int>((ref) async {
  final terrains = await ref.watch(terrainsProvider.future);
  return terrains.where((t) => t.status == TerrainStatus.maintenance).length;
});

/// Provider pour mettre à jour le status d'un terrain
final updateTerrainStatusProvider =
    FutureProvider.family<void, (int, TerrainStatus)>((ref, params) async {
      final (terrainId, newStatus) = params;
      final repo = ref.read(terrainRepositoryProvider);
      final currentTerrain = await ref.read(terrainProvider(terrainId).future);

      if (currentTerrain != null) {
        final updated = currentTerrain.copyWith(
          status: newStatus,
          updatedAt: DateTime.now(),
        );
        await repo.updateTerrain(updated);
        ref.invalidate(terrainsProvider);
      }
    });

// CREATE (avec sync auto)
final addTerrainProvider = Provider<Future<void> Function(String, TerrainType)>(
  (ref) {
    return (String name, TerrainType type) async {
      final repo = ref.read(terrainRepositoryProvider);

      final newTerrain = Terrain(
        id: 0, // Auto-increment handled by Drift
        nom: name,
        type: type,
        status: TerrainStatus.playable,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.addTerrain(newTerrain);
      ref.invalidate(terrainsProvider);
    };
  },
);

// UPDATE (avec sync auto)
final updateTerrainProvider = Provider<Future<void> Function(Terrain)>((ref) {
  return (Terrain updated) async {
    final repo = ref.read(terrainRepositoryProvider);
    await repo.updateTerrain(updated);
    ref.invalidate(terrainsProvider);
  };
});

