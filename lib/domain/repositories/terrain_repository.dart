import '../entities/terrain.dart';

abstract class TerrainRepository {
  Future<void> addTerrain(Terrain terrain);
  Future<void> updateTerrain(Terrain terrain);
  Future<void> deleteTerrain(String firebaseId);
  Future<List<Terrain>> getAllTerrains();
  Future<Terrain?> getTerrainById(int id);
}
