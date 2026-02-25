import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/terrain_repository_impl.dart';
import '../../data/services/firebase_sync_service.dart';
import '../../domain/entities/terrain.dart';
import '../../domain/repositories/terrain_repository.dart';
import 'database_provider.dart';

// Service Provider
final firebaseSyncServiceProvider = Provider<FirebaseSyncService>((ref) {
  // We use direct instance or could create a provider for Firestore instance
  return FirebaseSyncService(FirebaseFirestore.instance);
});

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
  final remoteStream = ref.watch(firestoreTerrainsProvider.future); // Use .future for first value or create broadcast

  // Ideally, combineLatest but simple async* works if we listen to stream properly
  // For StreamProvider, we can just yield* ref.watch(firestoreTerrainsProvider.stream) combined
  // But here we need to mix with local future.

  // Better pattern:
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
final updateTerrainStatusProvider = FutureProvider.family<void, (int, TerrainStatus)>((ref, params) async {
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

// Alias for compatibility if needed, or replace usages of 'terrainsProvider' with 'allTerrainsProvider'
// But since the original file exported 'terrainsProvider', we keep it as the main merged provider.

// CREATE (avec sync auto)
final addTerrainProvider = Provider<Future<void> Function(String, TerrainType)>((ref) {
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
});

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
  // Note: Remote items might not have local ID mapped yet.
  // Real implementation needs robust ID mapping (e.g. via firebaseId column in local DB).
  // Here we assume simple merge logic as requested.
  for (final t in remote) {
    // Try to find local match by firebaseId or ID
    // If remote has no local ID, it's tricky to map to 'int' key of map.
    // We skip complex reconciliation for this task and focus on the requested pattern.
    // If remote item has matching ID (which implies we synced it UP before), we merge.
    if (merged.containsKey(t.id)) {
      final existing = merged[t.id]!;
      merged[t.id] = existing.updatedAt.isAfter(t.updatedAt) ? existing : t;
    } else {
      // New from remote. We can't easily add to Map<int, Terrain> if ID is 0/null.
      // In a real app, we'd insert into local DB first, then yield the new full list.
      // For this stream provider, we might just append if we want to show it.
      // But since the map key is int, we can't add it without a valid local ID.
      // We will ignore remote-only items that are not in local DB for this specific "merge" function
      // unless we change the return type or logic.
      // HOWEVER, the user prompt says: "merged[t.id] = ... else merged[t.id] = t"
      // This implies remote items have valid IDs.
      if (t.id != 0) {
         merged[t.id] = t;
      }
    }
  }

  return merged.values.toList();
}
