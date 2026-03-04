import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/database/app_database.dart';
import '../../data/repositories/terrain_repository_impl.dart';
import '../../domain/entities/terrain.dart';
import '../../domain/models/repository_exception.dart';
import '../../domain/repositories/terrain_repository.dart';
import '../../data/mappers/terrain_mapper.dart';
import 'core_providers.dart';

// Repository Provider
final terrainRepositoryProvider = Provider<TerrainRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return TerrainRepositoryImpl(db: db, fs: FirebaseFirestore.instance);
});

// Stream Provider watching Drift
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
final playableTerrainCountProvider = Provider<int>((ref) {
  final terrains = ref.watch(terrainsProvider).value ?? [];
  return terrains.where((t) => t.status == TerrainStatus.playable).length;
});

/// Calculer le nombre de terrains en maintenance
final maintenanceTerrainCountProvider = Provider<int>((ref) {
  final terrains = ref.watch(terrainsProvider).value ?? [];
  return terrains.where((t) => t.status == TerrainStatus.maintenance).length;
});

// Terrain Notifier
class TerrainNotifier extends AsyncNotifier<void> {
  late TerrainRepository _repo;
  late AppDatabase _db;

  @override
  FutureOr<void> build() {
    _repo = ref.watch(terrainRepositoryProvider);
    _db = ref.watch(databaseProvider);
  }

  Future<void> addTerrain(String name, TerrainType type) async {
    try {
      state = const AsyncValue.loading();

      final newTerrain = Terrain(
        id: 0,
        nom: name,
        type: type,
        status: TerrainStatus.playable,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final firebaseId = await _repo.addTerrain(newTerrain);

      // Persist immediately to Drift cache
      await _db.upsertTerrain(
        newTerrain.copyWith(firebaseId: firebaseId).toCompanion(),
      );

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateTerrain(Terrain terrain) async {
    try {
      if (terrain.firebaseId == null) {
        throw const RepositoryException('Cannot update terrain without a firebaseId');
      }

      state = const AsyncValue.loading();
      await _repo.updateTerrain(terrain);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteTerrain(String firebaseId) async {
    try {
      state = const AsyncValue.loading();
      await _repo.deleteTerrain(firebaseId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final terrainNotifierProvider = AsyncNotifierProvider<TerrainNotifier, void>(() {
  return TerrainNotifier();
});

/// Provider pour mettre à jour le status d'un terrain
final updateTerrainStatusProvider = Provider<Future<void> Function(int, TerrainStatus)>((ref) {
  return (int terrainId, TerrainStatus newStatus) async {
    final currentTerrain = await ref.read(terrainProvider(terrainId).future);
    if (currentTerrain != null) {
      final updated = currentTerrain.copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );
      await ref.read(terrainNotifierProvider.notifier).updateTerrain(updated);
    }
  };
});
