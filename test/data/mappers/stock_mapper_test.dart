import 'package:flutter_test/flutter_test.dart';
import 'package:tenniscourtcare/data/mappers/stock_item_mapper.dart';
import '../../fixtures/test_data.dart';

void main() {
  group('StockItemMapper', () {
    group('toModel', () {
      test('converts StockItem entity to StockItemModel correctly', () {
        // Arrange
        final stockItem = TestData.testStockItem;

        // Act
        final model = StockItemMapper.toModel(stockItem);

        // Assert
        expect(model.id, stockItem.id);
        expect(model.name, stockItem.name);
        expect(model.category, stockItem.category);
        expect(model.quantity, stockItem.quantity);
        expect(model.minThreshold, stockItem.minThreshold);
      });

      test('preserves custom item flag', () {
        // Arrange
        final stockItem = TestData.testStockItem;

        // Act
        final model = StockItemMapper.toModel(stockItem);

        // Assert
        expect(model.isCustom, stockItem.isCustom);
      });
    });

    group('toDomain', () {
      test('converts StockItemModel to StockItem entity correctly', () {
        // Arrange
        final stockItem = TestData.testStockItem;
        final model = StockItemMapper.toModel(stockItem);

        // Act
        final result = StockItemMapper.toDomain(model);

        // Assert
        expect(result.id, model.id);
        expect(result.name, model.name);
        expect(result.category, model.category);
        expect(result.quantity, model.quantity);
      });
    });

    group('Bidirectional conversion', () {
      test('entity -> model -> entity preserves all data', () {
        // Arrange
        final original = TestData.testStockItem;

        // Act
        final model = StockItemMapper.toModel(original);
        final result = StockItemMapper.toDomain(model);

        // Assert
        expect(result.id, original.id);
        expect(result.name, original.name);
        expect(result.category, original.category);
        expect(result.quantity, original.quantity);
        expect(result.minThreshold, original.minThreshold);
        expect(result.unit, original.unit);
      });

      test('preserves sync status', () {
        // Arrange
        final stockItem = TestData.testStockItem;

        // Act
        final model = StockItemMapper.toModel(stockItem);
        final result = StockItemMapper.toDomain(model);

        // Assert
        expect(result.syncStatus, stockItem.syncStatus);
      });

      test('handles low stock items', () {
        // Arrange
        final lowStockItem = TestData.testStockItem.copyWith(
          quantity: 5,
        );

        // Act
        final model = StockItemMapper.toModel(lowStockItem);
        final result = StockItemMapper.toDomain(model);

        // Assert
        expect(result.quantity, 5);
        expect(result.quantity < (result.minThreshold ?? 0), true);
      });

      test('preserves created/modified by info', () {
        // Arrange
        final stockItem = TestData.testStockItem;

        // Act
        final model = StockItemMapper.toModel(stockItem);
        final result = StockItemMapper.toDomain(model);

        // Assert
        expect(result.createdBy, stockItem.createdBy);
        expect(result.modifiedBy, stockItem.modifiedBy);
      });
    });
  });
}