// filepath: test/data/repositories/terrain_repository_impl_test.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tenniscourtcare/data/database/app_database.dart';
import 'package:tenniscourtcare/data/repositories/terrain_repository_impl.dart';
import 'package:tenniscourtcare/domain/entities/terrain.dart';
import 'package:tenniscourtcare/domain/models/repository_exception.dart';
import '../../fixtures/test_data.dart';

class MockAppDatabase extends Mock implements AppDatabase {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}

void main() {
  late MockAppDatabase mockDb;
  late MockFirebaseFirestore mockFs;
  late MockCollectionReference mockCollection;
  late MockDocumentReference mockDoc;
  late TerrainRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(TestData.testTerrain);
  });

  setUp(() {
    mockDb = MockAppDatabase();
    mockFs = MockFirebaseFirestore();
    mockCollection = MockCollectionReference();
    mockDoc = MockDocumentReference();

    when(() => mockFs.collection('terrains')).thenReturn(mockCollection);
    when(() => mockCollection.doc(any())).thenReturn(mockDoc);

    repository = TerrainRepositoryImpl(db: mockDb, fs: mockFs);
  });

  group('TerrainRepositoryImpl', () {
    group('getAllTerrains', () {
      test('returns list of terrains on success', () async {
        // Arrange
        when(() => mockDb.getAllTerrains()).thenAnswer((_) async => TestData.testTerrains);

        // Act
        final result = await repository.getAllTerrains();

        // Assert
        expect(result, TestData.testTerrains);
        verify(() => mockDb.getAllTerrains()).called(1);
      });

      test('returns empty list when no terrains', () async {
        // Arrange
        when(() => mockDb.getAllTerrains()).thenAnswer((_) async => []);

        // Act
        final result = await repository.getAllTerrains();

        // Assert
        expect(result, []);
      });
    });

    group('addTerrain', () {
      test('writes to Firestore only', () async {
        // Arrange
        when(() => mockDoc.id).thenReturn('new_doc_id');
        when(() => mockCollection.add(any())).thenAnswer((_) async => mockDoc);

        // Act
        await repository.addTerrain(TestData.testTerrain);

        // Assert
        verify(() => mockCollection.add(any())).called(1);
        verifyNever(() => mockDb.insertTerrain(any()));
      });

      test('throws RepositoryException on FirebaseException', () async {
        // Arrange
        when(() => mockCollection.add(any()))
            .thenThrow(FirebaseException(plugin: 'firestore', code: 'unavailable'));

        // Act & Assert
        await expectLater(
          () => repository.addTerrain(TestData.testTerrain),
          throwsA(isA<RepositoryException>()),
        );
      });
    });

    group('updateTerrain', () {
      test('writes to Firestore only', () async {
        // Arrange
        when(() => mockDoc.update(any())).thenAnswer((_) async {});

        final testTerrainWithId = TestData.testTerrain.copyWith(firebaseId: 'test_id');

        // Act
        await repository.updateTerrain(testTerrainWithId);

        // Assert
        verify(() => mockCollection.doc('test_id')).called(1);
        verify(() => mockDoc.update(any())).called(1);
        verifyNever(() => mockDb.updateTerrain(any()));
      });

      test('throws RepositoryException if firebaseId is null', () async {
        // Arrange
        final testTerrainWithoutId = TestData.testTerrain.copyWith(
            // Provide a custom copyWith that actually clears the field if necessary,
            // but copyWith usually doesn't clear if null is passed. Let's do it manually.
        );

        final testTerrainWithoutId2 = Terrain(
          id: testTerrainWithoutId.id,
          nom: testTerrainWithoutId.nom,
          type: testTerrainWithoutId.type,
          status: testTerrainWithoutId.status,
          createdAt: testTerrainWithoutId.createdAt,
          updatedAt: testTerrainWithoutId.updatedAt,
          firebaseId: null,
        );

        // Act & Assert
        await expectLater(
          () => repository.updateTerrain(testTerrainWithoutId2),
          throwsA(isA<RepositoryException>()),
        );
      });
    });

    group('deleteTerrain', () {
      test('writes to Firestore only', () async {
        // Arrange
        when(() => mockDoc.delete()).thenAnswer((_) async {});

        // Act
        await repository.deleteTerrain('test_id');

        // Assert
        verify(() => mockCollection.doc('test_id')).called(1);
        verify(() => mockDoc.delete()).called(1);
        verifyNever(() => mockDb.deleteTerrain(any()));
      });
    });
  });
}
