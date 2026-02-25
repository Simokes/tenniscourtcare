import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:tenniscourtcare/data/database/app_database.dart';
import 'package:tenniscourtcare/services/queue/queue_manager.dart';
import 'package:tenniscourtcare/services/sync/sync_service.dart';

// Manual Mock
class MockSyncService implements SyncService {
  final _calls = <Call>[];
  var _shouldFail = false;
  String _failMessage = 'Network Error';

  void setShouldFail(bool fail, {String msg = 'Network Error'}) {
    _shouldFail = fail;
    _failMessage = msg;
  }

  List<Call> get calls => _calls;

  @override
  Future<void> sendToCloud(
    String collection,
    String documentId,
    Map<String, dynamic> data,
    SyncAction action,
  ) async {
    _calls.add(Call(collection, documentId, data, action));
    if (_shouldFail) {
      throw Exception(_failMessage);
    }
  }

  // Stubs for other members to satisfy interface
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class Call {
  final String collection;
  final String documentId;
  final Map<String, dynamic> data;
  final SyncAction action;

  Call(this.collection, this.documentId, this.data, this.action);
}

void main() {
  late AppDatabase db;
  late MockSyncService mockSyncService;
  late QueueManager queueManager;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    mockSyncService = MockSyncService();
    queueManager = QueueManager(db, mockSyncService);
  });

  tearDown(() async {
    queueManager.dispose();
    await db.close();
  });

  test('queueChange adds item to database', () async {
    final data = {'name': 'Test'};
    await queueManager.queueChange(
      collection: 'test',
      action: 'create',
      documentId: 'doc1',
      data: data,
    );

    final items = await queueManager.getPendingItems();
    expect(items.length, 1);
    expect(items.first.collection, 'test');
    expect(items.first.documentId, 'doc1');
    expect(jsonDecode(items.first.data), data);
    expect(items.first.syncedAt, isNull);
  });

  test('flushQueue sends items to cloud and removes them on success', () async {
    // 1. Queue an item
    await queueManager.queueChange(
      collection: 'test',
      action: 'create',
      documentId: 'doc1',
      data: {'val': 1},
    );

    // 2. Flush (default mock succeeds)
    await queueManager.flushQueue();

    // 3. Verify call
    expect(mockSyncService.calls.length, 1);
    expect(mockSyncService.calls.first.collection, 'test');
    expect(mockSyncService.calls.first.documentId, 'doc1');
    expect(mockSyncService.calls.first.data, {'val': 1});
    expect(mockSyncService.calls.first.action, SyncAction.create);

    // 4. Verify DB empty
    final items = await queueManager.getPendingItems();
    expect(items.isEmpty, true);
  });

  test('flushQueue increments retryCount on failure', () async {
    // 1. Queue an item
    await queueManager.queueChange(
      collection: 'fail',
      action: 'update',
      documentId: 'doc2',
      data: {'val': 2},
    );

    // 2. Configure failure
    mockSyncService.setShouldFail(true);

    // 3. Flush
    await queueManager.flushQueue();

    // 4. Verify
    final items = await queueManager.getPendingItems();
    expect(items.length, 1);
    expect(items.first.retryCount, 1);
    expect(items.first.lastError, contains('Network Error'));
  });

  test('retryFailedItems resets retry count', () async {
    // 1. Manually insert a failed item
    await db.into(db.syncQueue).insert(
      SyncQueueCompanion.insert(
        uuid: 'failed-uuid',
        collection: 'test',
        action: 'create',
        documentId: 'doc3',
        data: '{}',
        timestamp: DateTime.now(),
        retryCount: const Value(3), // Max retries
        lastError: const Value('Old Error'),
      ),
    );

    // 2. Configure success
    mockSyncService.setShouldFail(false);

    // 3. Retry failed items
    await queueManager.retryFailedItems();

    // 4. Verify
    // Should have reset count (to 0) and then flushed (success -> deleted)
    final items = await queueManager.getPendingItems();
    expect(items.isEmpty, true);

    expect(mockSyncService.calls.length, 1);
  });

  test('clearQueue removes all pending items', () async {
    await queueManager.queueChange(collection: 'c1', action: 'create', documentId: 'd1', data: {});
    await queueManager.queueChange(collection: 'c2', action: 'create', documentId: 'd2', data: {});

    expect(await queueManager.getQueueSize(), 2);

    await queueManager.clearQueue(confirmed: true);

    expect(await queueManager.getQueueSize(), 0);
  });
}
