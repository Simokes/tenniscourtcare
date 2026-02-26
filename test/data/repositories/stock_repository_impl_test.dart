// filepath: test/data/repositories/stock_repository_impl_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tenniscourtcare/data/database/app_database.dart';
import 'package:tenniscourtcare/data/repositories/stock_repository_impl.dart';
import '../../fixtures/test_data.dart';
import 'dart:async';

class MockAppDatabase extends Mock implements AppDatabase {}

void main() {
  late MockAppDatabase mockDb;
  late StockRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(TestData.testStockItem);
  });

  setUp(() {
    mockDb = MockAppDatabase();
    repository = StockRepositoryImpl(mockDb);
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
      test('adds stock item successfully', () async {
        // Arrange
        when(() => mockDb.insertStockItem(any())).thenAnswer((_) async => 1);

        // Act
        final result = await repository.addStockItem(TestData.testStockItem);

        // Assert
        expect(result, 1);
        verify(() => mockDb.insertStockItem(any())).called(1);
      });
    });

    group('updateStockItem', () {
      test('updates stock item successfully', () async {
        // Arrange
        when(() => mockDb.updateStockItem(any())).thenAnswer((_) async => true);

        // Act
        final result = await repository.updateStockItem(TestData.testStockItem);

        // Assert
        expect(result, true);
        verify(() => mockDb.updateStockItem(any())).called(1);
      });
    });

    group('deleteStockItem', () {
      test('deletes stock item successfully', () async {
        // Arrange
        when(() => mockDb.deleteStockItem(1)).thenAnswer((_) async => 1);

        // Act
        final result = await repository.deleteStockItem(1);

        // Assert
        expect(result, true);
        verify(() => mockDb.deleteStockItem(1)).called(1);
      });
    });
  });
}
