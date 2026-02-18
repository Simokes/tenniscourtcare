import '../database/app_database.dart';
import '../../domain/entities/terrain.dart';

/// Seed les données de développement avec les terrains demandés
/// À utiliser uniquement en mode debug
Future<void> seedDevData(AppDatabase database) async {
  // Vérifier si des terrains existent déjà
  final existingTerrains = await database.getAllTerrains();
  if (existingTerrains.isNotEmpty) {
    // Ne pas seed si des terrains existent déjà
    return;
  }

  // 6 terrains en terre battue
  for (int i = 1; i <= 6; i++) {
    await database.insertTerrain(
      Terrain(
        id: 0,
        nom: 'Court Terre Battue $i',
        type: TerrainType.terreBattue,
      ),
    );
  }

  // 2 terrains synthétiques
  for (int i = 1; i <= 2; i++) {
    await database.insertTerrain(
      Terrain(
        id: 0,
        nom: 'Court Synthétique $i',
        type: TerrainType.synthetique,
      ),
    );
  }

  // 3 terrains durs
  for (int i = 1; i <= 3; i++) {
    await database.insertTerrain(
      Terrain(
        id: 0,
        nom: 'Court Dur $i',
        type: TerrainType.dur,
      ),
    );
  }
}
