import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/terrain_repository_impl.dart';
import '../../domain/entities/terrain.dart';
import '../../domain/repositories/terrain_repository.dart';
import 'database_provider.dart';
import 'sync_status_provider.dart';

// Repository Provider
final terrainRepositoryProvider = Provider<TerrainRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final firebaseService = ref.watch(firebaseSyncServiceProvider);
  return TerrainRepositoryImpl(db, firebaseService);
});

// LOCAL (SQLite)
final localTerrainsProvider = FutureProvider<List<Terrain>>((ref) async {
  final repo = ref.watch(terrainRepositoryProvider);
  return repo.getAllTerrains();
});

// FIRESTORE (stream temps réel)
final firestoreTerrainsProvider = StreamProvider<List<Terrain>>((ref) {
  final firebaseService = ref.watch(firebaseSyncServiceProvider);
  return firebaseService.terrainService.watchTerrains();
});

// FUSION LOCAL + FIRESTORE
final terrainsProvider = StreamProvider<List<Terrain>>((ref) async* {
  final localFuture = ref.watch(localTerrainsProvider.future);

  final local = await localFuture;
  yield local; // Yield local first for instant UI

  // Then listen to remote
  yield* ref.watch(firestoreTerrainsProvider.stream).map((remote) {
    return _mergeTerrains(local, remote);
  });
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

// Helper: Merge LOCAL + FIRESTORE
List<Terrain> _mergeTerrains(List<Terrain> local, List<Terrain> remote) {
  final merged = <int, Terrain>{};

  // Ajouter tous les locaux
  for (final t in local) {
    merged[t.id] = t;
  }

  // Fusionner avec les remotes (LAST-WRITE-WINS)
  for (final t in remote) {
    // Try to find local match by firebaseId or ID
    // Note: In a real scenario, we'd map by firebaseId.
    // Here we assume ID consistency or merge based on ID if present.
    // If ID is 0 or null from remote (unlikely if mapped correctly), we might skip or append.
    // For this implementation, we prioritize local ID match if available.

    // Check if we have a local item with same ID
    if (merged.containsKey(t.id)) {
      final existing = merged[t.id]!;
      // Use remote if it's newer
      if (t.updatedAt.isAfter(existing.updatedAt)) {
        merged[t.id] = t;
      }
    } else {
       // Remote only item. If ID > 0, include it.
       if (t.id != 0) {
         merged[t.id] = t;
       }
    }
  }

  return merged.values.toList();
}
