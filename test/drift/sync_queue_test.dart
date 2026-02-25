import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tenniscourtcare/data/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() {
    db.close();
  });

  test('SyncQueue insert and retrieve', () async {
    final item = SyncQueueCompanion.insert(
      uuid: 'uuid-123',
      collection: 'test_col',
      action: 'create',
      documentId: 'doc1',
      data: '{}',
      timestamp: DateTime.now(),
    );

    await db.into(db.syncQueue).insert(item);

    final result = await db.select(db.syncQueue).get();
    expect(result.length, 1);
    expect(result.first.collection, 'test_col');
    expect(result.first.syncedAt, isNull);
  });
}
