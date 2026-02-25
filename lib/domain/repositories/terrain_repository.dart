import '../entities/terrain.dart';

abstract class TerrainRepository {
  Future<int> addTerrain(Terrain terrain);
  Future<bool> updateTerrain(Terrain terrain);
  Future<bool> deleteTerrain(int id);
  Future<List<Terrain>> getAllTerrains();
  Future<Terrain?> getTerrainById(int id);
}
