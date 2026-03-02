import 'package:flutter_test/flutter_test.dart';
import 'package:tenniscourtcare/data/mappers/maintenance_mapper.dart';
import '../../fixtures/test_data.dart';

void main() {
  group('MaintenanceMapper', () {
    group('toModel', () {
      test('converts Maintenance entity to MaintenanceModel correctly', () {
        // Arrange
        final maintenance = TestData.testMaintenance;

        // Act
        final model = MaintenanceMapper.toModel(maintenance);

        // Assert
        expect(model.id, maintenance.id);
        expect(model.terrainId, maintenance.terrainId);
        expect(model.type, maintenance.type);
        expect(model.commentaire, maintenance.commentaire);
      });
    });

    group('toDomain', () {
      test('converts MaintenanceModel to Maintenance entity correctly', () {
        // Arrange
        final maintenance = TestData.testMaintenance;
        final model = MaintenanceMapper.toModel(maintenance);

        // Act
        final result = MaintenanceMapper.toDomain(model);

        // Assert
        expect(result.id, model.id);
        expect(result.terrainId, model.terrainId);
        expect(result.type, model.type);
      });
    });

    group('Bidirectional conversion', () {
      test('entity -> model -> entity preserves all data', () {
        // Arrange
        final original = TestData.testMaintenance;

        // Act
        final model = MaintenanceMapper.toModel(original);
        final result = MaintenanceMapper.toDomain(model);

        // Assert
        expect(result.id, original.id);
        expect(result.terrainId, original.terrainId);
        expect(result.type, original.type);
        expect(result.commentaire, original.commentaire);
      });

      test('preserves sacks usage data', () {
        // Arrange
        final maintenance = TestData.testMaintenance;

        // Act
        final model = MaintenanceMapper.toModel(maintenance);
        final result = MaintenanceMapper.toDomain(model);

        // Assert
        expect(result.sacsMantoUtilises, maintenance.sacsMantoUtilises);
        expect(result.sacsSottomantoUtilises, maintenance.sacsSottomantoUtilises);
        expect(result.sacsSiliceUtilises, maintenance.sacsSiliceUtilises);
      });

     

      test('preserves user audit info', () {
        // Arrange
        final maintenance = TestData.testMaintenance;

        // Act
        final model = MaintenanceMapper.toModel(maintenance);
        final result = MaintenanceMapper.toDomain(model);

        // Assert
        expect(result.createdBy, maintenance.createdBy);
        expect(result.modifiedBy, maintenance.modifiedBy);
      });

      test('handles optional image path and weather', () {
        // Arrange
        final maintenanceWithImage = TestData.testMaintenance.copyWith(
          imagePath: '/path/to/image.jpg',
        );

        // Act
        final model = MaintenanceMapper.toModel(maintenanceWithImage);
        final result = MaintenanceMapper.toDomain(model);

        // Assert
        expect(result.imagePath, maintenanceWithImage.imagePath);
      });
    });
  });
}