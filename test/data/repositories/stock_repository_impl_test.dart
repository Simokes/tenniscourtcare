// filepath: test/data/repositories/stock_repository_impl_test.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tenniscourtcare/data/database/app_database.dart';
import 'package:tenniscourtcare/data/repositories/stock_repository_impl.dart';
import 'package:tenniscourtcare/domain/entities/stock_item.dart';
import 'package:tenniscourtcare/domain/models/repository_exception.dart';
import '../../fixtures/test_data.dart';
import 'dart:async';

class MockAppDatabase extends Mock implements AppDatabase {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}

void main() {
  late MockAppDatabase mockDb;
  late MockFirebaseFirestore mockFs;
  late MockCollectionReference mockCollection;
  late MockDocumentReference mockDoc;
  late StockRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(TestData.testStockItem);
  });

  setUp(() {
    mockDb = MockAppDatabase();
    mockFs = MockFirebaseFirestore();
    mockCollection = MockCollectionReference();
    mockDoc = MockDocumentReference();

    when(() => mockFs.collection('stock_items')).thenReturn(mockCollection);
    when(() => mockCollection.doc(any())).thenReturn(mockDoc);

    repository = StockRepositoryImpl(db: mockDb, fs: mockFs);
  });

  group('StockRepositoryImpl', () {
    group('getAllStockItems', () {
      test('returns list of stock items from stream', () async {
        // Arrange
        when(() => mockDb.watchAllStockItems()).thenAnswer(
          (_) => Stream.value(TestData.testStockItems),
        );

        // Act
        final result = await repository.getAllStockItems();

        // Assert
        expect(result, TestData.testStockItems);
        verify(() => mockDb.watchAllStockItems()).called(1);
      });
    });

    group('addStockItem', () {
      test('writes to Firestore only', () async {
        // Arrange
        when(() => mockCollection.add(any())).thenAnswer((_) async => mockDoc);

        // Act
        await repository.addStockItem(TestData.testStockItem);

        // Assert
        verify(() => mockCollection.add(any())).called(1);
        verifyNever(() => mockDb.insertStockItem(any()));
      });

      test('throws RepositoryException on FirebaseException', () async {
        // Arrange
        when(() => mockCollection.add(any()))
            .thenThrow(FirebaseException(plugin: 'firestore', code: 'unavailable'));

        // Act & Assert
        await expectLater(
          () => repository.addStockItem(TestData.testStockItem),
          throwsA(isA<RepositoryException>()),
        );
      });
    });

    group('updateStockItem', () {
      test('writes to Firestore only', () async {
        // Arrange
        when(() => mockDoc.update(any())).thenAnswer((_) async {});

        final testStockItemWithId = TestData.testStockItem.copyWith(firebaseId: 'test_id');

        // Act
        await repository.updateStockItem(testStockItemWithId);

        // Assert
        verify(() => mockCollection.doc('test_id')).called(1);
        verify(() => mockDoc.update(any())).called(1);
        verifyNever(() => mockDb.updateStockItem(any()));
      });

      test('throws RepositoryException if firebaseId is null', () async {
        // Arrange
        final testStockItemWithoutId = TestData.testStockItem.copyWith(firebaseId: null);

        // Ensure firebaseId is truly null
        final itemWithoutId = StockItem(
          id: testStockItemWithoutId.id,
          name: testStockItemWithoutId.name,
          quantity: testStockItemWithoutId.quantity,
          unit: testStockItemWithoutId.unit,
          category: testStockItemWithoutId.category,
          sortOrder: testStockItemWithoutId.sortOrder,
          minThreshold: testStockItemWithoutId.minThreshold,
          isCustom: testStockItemWithoutId.isCustom,
          createdAt: testStockItemWithoutId.createdAt,
          updatedAt: testStockItemWithoutId.updatedAt,
          firebaseId: null,
        );

        // Act & Assert
        await expectLater(
          () => repository.updateStockItem(itemWithoutId),
          throwsA(isA<RepositoryException>()),
        );
      });
    });

    group('deleteStockItem', () {
      test('writes to Firestore only', () async {
        // Arrange
        when(() => mockDoc.delete()).thenAnswer((_) async {});

        // Act
        await repository.deleteStockItem('test_id');

        // Assert
        verify(() => mockCollection.doc('test_id')).called(1);
        verify(() => mockDoc.delete()).called(1);
        verifyNever(() => mockDb.deleteStockItem(any()));
      });
    });
  });
}
