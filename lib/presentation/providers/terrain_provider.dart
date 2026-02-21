import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/terrain.dart';
import 'database_provider.dart';

/// Provider pour la liste de tous les terrains
final terrainsProvider = FutureProvider<List<Terrain>>((ref) {
  final database = ref.watch(databaseProvider);
  return database.getAllTerrains();
});

/// Provider pour un terrain spécifique
final terrainProvider = FutureProvider.family<Terrain?, int>((ref, terrainId) {
  final database = ref.watch(databaseProvider);
  return database.getTerrainById(terrainId);
});

/// Action d’ajout : écrit via la base, puis invalide les caches de lecture
final addTerrainProvider = Provider<Future<void> Function(Terrain)>((ref) {
  return (Terrain newTerrain) async {
    final db = ref.read(databaseProvider);
    await db.insertTerrain(newTerrain);
    ref.invalidate(terrainsProvider);
  };
});

/// Action d’update : écrit via la base, puis invalide les caches de lecture
final updateTerrainProvider = Provider<Future<void> Function(Terrain)>((ref) {
  return (Terrain updated) async {
    final db = ref.read(databaseProvider);

    await db.updateTerrain(updated); // <-- appelle ta méthode DB existante

    // Ré-invalide la liste de tous les terrains
    ref.invalidate(terrainsProvider);
    // Ré-invalide aussi le terrain individuel correspondant
    ref.invalidate(terrainProvider(updated.id));
  };
});

/// Action de suppression : écrit via la base, puis invalide les caches de lecture
final deleteTerrainProvider = Provider<Future<void> Function(int)>((ref) {
  return (int id) async {
    final db = ref.read(databaseProvider);
    await db.deleteTerrain(id);
    ref.invalidate(terrainsProvider);
    ref.invalidate(terrainProvider(id));
  };
});
