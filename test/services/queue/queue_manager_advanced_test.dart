import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:tenniscourtcare/services/queue/queue_manager.dart';
import 'package:tenniscourtcare/data/database/app_database.dart';
import 'package:tenniscourtcare/services/sync/sync_service.dart';

// Manual Mock
class MockSyncService extends Mock implements SyncService {
  @override
  Future<void> sendToCloud(
    String? collection,
    String? documentId,
    Map<String, dynamic>? data,
    SyncAction? action,
  ) {
    return super.noSuchMethod(
      Invocation.method(#sendToCloud, [collection, documentId, data, action]),
      returnValue: Future<void>.value(),
      returnValueForMissingStub: Future<void>.value(),
    );
  }
}

void main() {
  late AppDatabase db;
  late MockSyncService syncService;
  late QueueManager queueManager;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    syncService = MockSyncService();
    queueManager = QueueManager(db, syncService);
  });

  tearDown(() async {
    await queueManager.dispose();
    await db.close();
  });

  group('QueueManager Advanced Features', () {
    test('processScheduledRetries respects nextRetryAt', () async {
      // 1. Queue an item
      await queueManager.queueChange(
        collection: 'test',
        action: 'create',
        documentId: 'doc1',
        data: {'test': true},
      );

      final items = await queueManager.getPendingItems();
      final item = items.first;

      // 2. Manually set nextRetryAt to future (10s later)
      final futureTime = DateTime.now().add(const Duration(seconds: 10));
      await (db.update(db.syncQueue)..where((t) => t.id.equals(item.id)))
        .write(SyncQueueCompanion(
          nextRetryAt: Value(futureTime),
          lastError: const Value('Error'),
          retryCount: const Value(1),
        ));

      // 3. Process retries
      await queueManager.processScheduledRetries();

      // 4. Verify SyncService NOT called
      verifyNever(syncService.sendToCloud(any, any, any, any));

      // 5. Update nextRetryAt to past
      final pastTime = DateTime.now().subtract(const Duration(seconds: 1));
      await (db.update(db.syncQueue)..where((t) => t.id.equals(item.id)))
        .write(SyncQueueCompanion(
          nextRetryAt: Value(pastTime),
        ));

      // 6. Process retries
      await queueManager.processScheduledRetries();

      // 7. Verify SyncService called
      verify(syncService.sendToCloud('test', 'doc1', any, any)).called(1);
    });

    test('Deduplication removes redundant items', () async {
      // 1. Create
      await queueManager.queueChange(collection: 'col', action: 'create', documentId: 'docA', data: {});
      // 2. Update
      await queueManager.queueChange(collection: 'col', action: 'update', documentId: 'docA', data: {'u': 1});
      // 3. Delete
      await queueManager.queueChange(collection: 'col', action: 'delete', documentId: 'docA', data: {});

      final items = await queueManager.getPendingItems();

      // Should only have the DELETE action
      expect(items.length, 1);
      expect(items.first.action, 'delete');
      expect(items.first.documentId, 'docA');
    });

    test('Conflict handling: Reservation cancellation', () async {
      // Mock sync service to return conflict error
      when(syncService.sendToCloud(any, any, any, any))
          .thenAnswer((_) async => throw Exception('Terrain not available'));


      // Create a reservation locally
      final resId = await db.into(db.reservations).insert(
        ReservationsCompanion.insert(
          userId: 1,
          terrainId: 1,
          startTime: '10:00',
          endTime: '11:00',
          status: 'pending',
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
          date: DateTime.now(),
        )
      );

      // Queue the creation
      await queueManager.queueChange(
        collection: 'reservations',
        action: 'create',
        documentId: resId.toString(),
        data: {}
      );

      // Flush
      await queueManager.flushQueue();

      // Verify reservation deleted locally
      final res = await (db.select(db.reservations)..where((r) => r.id.equals(resId))).getSingleOrNull();
      expect(res, isNull);

      // Verify queue item removed (handled)
      final items = await queueManager.getPendingItems();
      expect(items.isEmpty, true);
    });

    test('Warning streams', () async {
       // Insert 55 items
       for (int i = 0; i < 55; i++) {
         await db.into(db.syncQueue).insert(
            SyncQueueCompanion(
              uuid: Value('uuid-$i'),
              collection: const Value('col'),
              action: const Value('create'),
              documentId: Value('doc$i'),
              data: const Value('{}'),
              timestamp: Value(DateTime.now()),
            )
         );
       }

       bool warningReceived = false;
       final sub = queueManager.onQueueWarning.listen((count) {
         if (count >= 50) warningReceived = true;
       });

       // Trigger check by adding one more
       await queueManager.queueChange(collection: 'c', action: 'a', documentId: 'd', data: {});

       // Allow stream to propagate
       await Future.delayed(const Duration(milliseconds: 100));

       expect(warningReceived, true);
       await sub.cancel();
    });
  });
}
