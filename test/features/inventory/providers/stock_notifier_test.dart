import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tenniscourtcare/domain/entities/stock_item.dart';
import 'package:tenniscourtcare/domain/repositories/stock_repository.dart';
import 'package:tenniscourtcare/features/inventory/providers/stock_provider.dart';

class MockStockRepository extends Mock implements StockRepository {}

StockItem _makeItem({required bool isCustom, String? firebaseId}) => StockItem(
      name: 'test',
      quantity: 10,
      unit: 'pcs',
      isCustom: isCustom,
      updatedAt: DateTime(2026),
      createdAt: DateTime(2026),
      firebaseId: firebaseId,
    );

void main() {
  group('StockNotifier.deleteItem', () {
    late MockStockRepository mockRepo;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockStockRepository();
      container = ProviderContainer(
        overrides: [
          stockRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('met le state en erreur pour un article systeme (isCustom=false)', () async {
      // Arrange
      final systemItem = _makeItem(isCustom: false, firebaseId: 'fb_123');

      // Act
      await container.read(stockNotifierProvider.notifier).deleteItem(systemItem);

      // Assert
      expect(container.read(stockNotifierProvider), isA<AsyncError>());
      verifyNever(() => mockRepo.deleteStockItem(any()));
    });

    test('supprime un article custom (isCustom=true) avec succes', () async {
      // Arrange
      final customItem = _makeItem(isCustom: true, firebaseId: 'fb_456');
      when(() => mockRepo.deleteStockItem('fb_456')).thenAnswer((_) async {});

      // Act
      await container
          .read(stockNotifierProvider.notifier)
          .deleteItem(customItem);

      // Assert
      verify(() => mockRepo.deleteStockItem('fb_456')).called(1);
    });

    test('met le state en erreur si firebaseId est null meme pour un article custom', () async {
      // Arrange
      final itemSansId = _makeItem(isCustom: true, firebaseId: null);

      // Act
      await container.read(stockNotifierProvider.notifier).deleteItem(itemSansId);

      // Assert
      expect(container.read(stockNotifierProvider), isA<AsyncError>());
      verifyNever(() => mockRepo.deleteStockItem(any()));
    });
  });
}