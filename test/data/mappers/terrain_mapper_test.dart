import 'package:flutter_test/flutter_test.dart';
import 'package:tenniscourtcare/data/mappers/terrain_mapper.dart';
import 'package:tenniscourtcare/domain/entities/terrain.dart';
import '../../fixtures/test_data.dart';

void main() {
  group('TerrainMapper', () {
    group('toModel', () {
      test('converts Terrain entity to TerrainModel correctly', () {
        // Arrange
        final terrain = TestData.testTerrain;

        // Act
        final model = TerrainMapper.toModel(terrain);

        // Assert
        expect(model.id, terrain.id);
        expect(model.nom, terrain.nom);
        expect(model.type, terrain.type.name);
        expect(model.status, terrain.status.name);
      });
    });

    group('toDomain', () {
      test('converts TerrainModel to Terrain entity correctly', () {
        // Arrange
        final terrain = TestData.testTerrain;
        final model = TerrainMapper.toModel(terrain);

        // Act
        final result = TerrainMapper.toDomain(model);

        // Assert
        expect(result.id, model.id);
        expect(result.nom, model.nom);
        expect(result.type.name, model.type);
        expect(result.status.name, model.status);
      });
    });

    group('Bidirectional conversion', () {
      test('entity -> model -> entity preserves all data', () {
        // Arrange
        final original = TestData.testTerrain;

        // Act
        final model = TerrainMapper.toModel(original);
        final result = TerrainMapper.toDomain(model);

        // Assert
        expect(result.id, original.id);
        expect(result.nom, original.nom);
        expect(result.type, original.type);
        expect(result.status, original.status);
        expect(result.createdBy, original.createdBy);
        expect(result.modifiedBy, original.modifiedBy);
      });

      test('handles different terrain types', () {
        // Arrange
        final terreBattueCourt = TestData.testTerrain.copyWith(
          type: TerrainType.terreBattue,
        );

        // Act
        final model = TerrainMapper.toModel(terreBattueCourt);
        final result = TerrainMapper.toDomain(model);

        // Assert
        expect(result.type, TerrainType.terreBattue);
      });

      test('handles different terrain status - maintenance', () {
        // Arrange - CHANGE 'closed' à 'maintenance'
        final maintenanceCourt = TestData.testTerrain.copyWith(
          status: TerrainStatus.maintenance,
        );

        // Act
        final model = TerrainMapper.toModel(maintenanceCourt);
        final result = TerrainMapper.toDomain(model);

        // Assert
        expect(result.status, TerrainStatus.maintenance);
      });

      test('preserves firebase sync data', () {
        // Arrange
        final terrain = TestData.testTerrain;

        // Act
        final model = TerrainMapper.toModel(terrain);
        final result = TerrainMapper.toDomain(model);

        // Assert
        expect(result.firebaseId, terrain.firebaseId);
        expect(result.syncStatus, terrain.syncStatus);
      });

      test('handles optional GPS coordinates', () {
        // Arrange
        final gpsTerrains = [
          TestData.testTerrain.copyWith(latitude: 48.8, longitude: 2.3),
          TestData.testTerrain.copyWith(latitude: null, longitude: null),
        ];

        for (final terrain in gpsTerrains) {
          // Act
          final model = TerrainMapper.toModel(terrain);
          final result = TerrainMapper.toDomain(model);

          // Assert
          expect(result.latitude, terrain.latitude);
          expect(result.longitude, terrain.longitude);
        }
      });
    });
  });
}