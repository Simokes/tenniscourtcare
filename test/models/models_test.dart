
import 'package:flutter_test/flutter_test.dart';
import 'package:tenniscourtcare/data/models/terrain_model.dart';
import 'package:tenniscourtcare/domain/entities/terrain.dart';
import 'package:tenniscourtcare/domain/entities/sync_status.dart';

void main() {
  group('TerrainModel', () {
    test('should convert from domain to model and back', () {
      final terrain = Terrain(
        id: 1,
        nom: 'Court 1',
        type: TerrainType.terreBattue,
        status: TerrainStatus.playable,
        latitude: 10.0,
        longitude: 20.0,
        photoUrl: 'http://example.com/photo.jpg',
        syncStatus: SyncStatus.synced,
        createdAt: DateTime(2023, 1, 1),
        updatedAt: DateTime(2023, 1, 2),
        firebaseId: 'fb123',
        createdBy: 'admin',
        modifiedBy: 'admin',
      );

      final model = TerrainModel.fromDomain(terrain);

      expect(model.id, terrain.id);
      expect(model.nom, terrain.nom);
      expect(model.type, 'terreBattue'); // Enum name
      expect(model.status, 'playable');
      expect(model.createdAt, terrain.createdAt.toIso8601String());

      final newTerrain = model.toDomain();

      expect(newTerrain, terrain);
    });

    test('should convert from json to model and back', () {
      final json = {
        'id': 1,
        'nom': 'Court 1',
        'type': 'terreBattue',
        'status': 'playable',
        'latitude': 10.0,
        'longitude': 20.0,
        'photoUrl': 'http://example.com/photo.jpg',
        'syncStatus': 'SYNCED',
        'createdAt': '2023-01-01T00:00:00.000',
        'updatedAt': '2023-01-02T00:00:00.000',
        'firebaseId': 'fb123',
        'createdBy': 'admin',
        'modifiedBy': 'admin',
      };

      // Note: SyncStatus.synced.name is 'synced' (lowercase) usually, but let's check SyncStatus definition.
      // SyncStatus enum: local, syncing, synced, error. So name is lowercase.
      // But in my test JSON I put 'SYNCED'. SyncStatus.fromString likely handles case-insensitivity or expects specific string.
      // Let's check SyncStatus.fromString.

      // I'll assume standard .name behavior for now and fix if test fails.
      final jsonCorrect = Map<String, dynamic>.from(json);
      jsonCorrect['syncStatus'] = 'synced';

      final model = TerrainModel.fromJson(jsonCorrect);

      expect(model.id, 1);
      expect(model.type, 'terreBattue');

      final newJson = model.toJson();

      expect(newJson['id'], 1);
      expect(newJson['type'], 'terreBattue');
      expect(newJson['syncStatus'], 'synced');
    });
  });
}
