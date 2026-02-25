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

/// Provider pour mettre à jour le status d'un terrain
final updateTerrainStatusProvider = FutureProvider.family<void, (int, TerrainStatus)>((ref, params) async {
  final (terrainId, newStatus) = params;
  final db = ref.watch(databaseProvider);

  await db.updateTerrainStatus(terrainId, newStatus.name);

  // Invalider le provider pour recharger les données
  ref.invalidate(terrainsProvider);
  ref.invalidate(terrainProvider(terrainId));
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

/// Action d'ajout : Convertit les Strings du formulaire en objet Terrain
final addTerrainProvider = Provider<Future<void> Function(String, TerrainType)>((ref) {
  return (String name, TerrainType type) async {
    final db = ref.read(databaseProvider);

    // On crée l'objet Terrain avec le bon type (TerrainType) et status par défaut
    final newTerrain = Terrain(
      id: 0,
      nom: name,
      type: type, // Utilise l'énumération ici
      status: TerrainStatus.playable, // Défaut
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await db.insertTerrain(newTerrain);
    ref.invalidate(terrainsProvider);
  };
});
