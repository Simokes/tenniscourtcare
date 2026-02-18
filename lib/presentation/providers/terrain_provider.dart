import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/terrain.dart';
import 'database_provider.dart';

/// Provider pour la liste de tous les terrains
final terrainsProvider = FutureProvider<List<Terrain>>((ref) {
  final database = ref.watch(databaseProvider);
  return database.getAllTerrains();
});

/// Provider pour un terrain spécifique
final terrainProvider =
    FutureProvider.family<Terrain?, int>((ref, terrainId) {
  final database = ref.watch(databaseProvider);
  return database.getTerrainById(terrainId);
});
