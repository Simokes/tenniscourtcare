import 'package:flutter_test/flutter_test.dart';
import 'package:tenniscourtcare/data/mappers/event_mapper.dart';
import '../../fixtures/test_data.dart';

void main() {
  group('EventMapper', () {
    group('toModel', () {
      test('converts AppEvent entity to AppEventModel correctly', () {
        // Arrange
        final event = TestData.testEvent;

        // Act
        final model = EventMapper.toModel(event);

        // Assert
        expect(model.id, event.id);
        expect(model.title, event.title);
        expect(model.description, event.description);
        expect(model.color, event.color);
      });
    });

    group('toDomain', () {
      test('converts AppEventModel to AppEvent entity correctly', () {
        // Arrange
        final event = TestData.testEvent;
        final model = EventMapper.toModel(event);

        // Act
        final result = EventMapper.toDomain(model);

        // Assert
        expect(result.id, model.id);
        expect(result.title, model.title);
        expect(result.description, model.description);
      });
    });

    group('Bidirectional conversion', () {
      test('entity -> model -> entity preserves all data', () {
        // Arrange
        final original = TestData.testEvent;

        // Act
        final model = EventMapper.toModel(original);
        final result = EventMapper.toDomain(model);

        // Assert
        expect(result.id, original.id);
        expect(result.title, original.title);
        expect(result.description, original.description);
        expect(result.color, original.color);
      });

      test('preserves date range', () {
        // Arrange
        final event = TestData.testEvent;

        // Act
        final model = EventMapper.toModel(event);
        final result = EventMapper.toDomain(model);

        // Assert
        expect(result.startTime, event.startTime);
        expect(result.endTime, event.endTime);
      });

      test('preserves sync and audit info', () {
        // Arrange
        final event = TestData.testEvent;

        // Act
        final model = EventMapper.toModel(event);
        final result = EventMapper.toDomain(model);

        // Assert
        expect(result.createdBy, event.createdBy);
        expect(result.modifiedBy, event.modifiedBy);
      });

      test('preserves terrain IDs', () {
        // Arrange
        final event = TestData.testEvent;

        // Act
        final model = EventMapper.toModel(event);
        final result = EventMapper.toDomain(model);

        // Assert
        expect(result.terrainIds, event.terrainIds);
      });
    });
  });
}