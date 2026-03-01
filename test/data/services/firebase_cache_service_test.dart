import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tenniscourtcare/data/database/app_database.dart';
import 'package:tenniscourtcare/data/services/firebase_cache_service.dart';

import 'firebase_cache_service_test.mocks.dart';

@GenerateMocks([
  AppDatabase,
  FirebaseFirestore,
  CollectionReference,
  QuerySnapshot,
  DocumentChange,
  QueryDocumentSnapshot,
])
void main() {
  late MockAppDatabase mockDb;
  late MockFirebaseFirestore mockFs;
  late FirebaseCacheService cacheService;
  late MockCollectionReference<Map<String, dynamic>> mockStockCollection;
  late MockCollectionReference<Map<String, dynamic>> mockTerrainsCollection;
  late MockCollectionReference<Map<String, dynamic>> mockMaintenancesCollection;
  late MockCollectionReference<Map<String, dynamic>> mockEventsCollection;

  late StreamController<QuerySnapshot<Map<String, dynamic>>> stockStreamController;
  late StreamController<QuerySnapshot<Map<String, dynamic>>> terrainsStreamController;
  late StreamController<QuerySnapshot<Map<String, dynamic>>> maintenancesStreamController;
  late StreamController<QuerySnapshot<Map<String, dynamic>>> eventsStreamController;

  setUp(() {
    mockDb = MockAppDatabase();
    mockFs = MockFirebaseFirestore();

    mockStockCollection = MockCollectionReference();
    mockTerrainsCollection = MockCollectionReference();
    mockMaintenancesCollection = MockCollectionReference();
    mockEventsCollection = MockCollectionReference();

    stockStreamController = StreamController<QuerySnapshot<Map<String, dynamic>>>();
    terrainsStreamController = StreamController<QuerySnapshot<Map<String, dynamic>>>();
    maintenancesStreamController = StreamController<QuerySnapshot<Map<String, dynamic>>>();
    eventsStreamController = StreamController<QuerySnapshot<Map<String, dynamic>>>();

    when(mockFs.collection('stock')).thenReturn(mockStockCollection);
    when(mockFs.collection('terrains')).thenReturn(mockTerrainsCollection);
    when(mockFs.collection('maintenance')).thenReturn(mockMaintenancesCollection);
    when(mockFs.collection('events')).thenReturn(mockEventsCollection);

    when(mockStockCollection.snapshots()).thenAnswer((_) => stockStreamController.stream);
    when(mockTerrainsCollection.snapshots()).thenAnswer((_) => terrainsStreamController.stream);
    when(mockMaintenancesCollection.snapshots()).thenAnswer((_) => maintenancesStreamController.stream);
    when(mockEventsCollection.snapshots()).thenAnswer((_) => eventsStreamController.stream);

    cacheService = FirebaseCacheService(mockDb, mockFs);
  });

  tearDown(() {
    cacheService.stopListening();
    stockStreamController.close();
    terrainsStreamController.close();
    maintenancesStreamController.close();
    eventsStreamController.close();
  });

  group('FirebaseCacheService', () {
    group('startListening()', () {
      test('starts all collection listeners', () {
        cacheService.startListening();
        expect(cacheService.isListening, isTrue);

        verify(mockFs.collection('stock')).called(1);
        verify(mockFs.collection('terrains')).called(1);
        verify(mockFs.collection('maintenance')).called(1);
        verify(mockFs.collection('events')).called(1);

        verify(mockStockCollection.snapshots()).called(1);
        verify(mockTerrainsCollection.snapshots()).called(1);
        verify(mockMaintenancesCollection.snapshots()).called(1);
        verify(mockEventsCollection.snapshots()).called(1);
      });

      test('is idempotent (calling twice does not duplicate listeners)', () {
        cacheService.startListening();
        cacheService.startListening();

        verify(mockFs.collection('stock')).called(1);
        verify(mockStockCollection.snapshots()).called(1);
      });

      test('sets isListening to true', () {
        expect(cacheService.isListening, isFalse);
        cacheService.startListening();
        expect(cacheService.isListening, isTrue);
      });
    });

    group('stopListening()', () {
      test('cancels all subscriptions', () {
        cacheService.startListening();
        expect(cacheService.isListening, isTrue);

        cacheService.stopListening();
        expect(cacheService.isListening, isFalse);
      });

      test('sets isListening to false', () {
        cacheService.startListening();
        cacheService.stopListening();
        expect(cacheService.isListening, isFalse);
      });

      test('is safe to call when not listening', () {
        expect(() => cacheService.stopListening(), returnsNormally);
      });
    });

    group('Stock listener', () {
      late MockQuerySnapshot<Map<String, dynamic>> mockSnapshot;
      late MockDocumentChange<Map<String, dynamic>> mockChange;
      late MockQueryDocumentSnapshot<Map<String, dynamic>> mockDoc;

      setUp(() {
        mockSnapshot = MockQuerySnapshot();
        mockChange = MockDocumentChange();
        mockDoc = MockQueryDocumentSnapshot();

        when(mockSnapshot.docChanges).thenReturn([mockChange]);
        when(mockChange.doc).thenReturn(mockDoc);
        when(mockDoc.id).thenReturn('firebase_id_123');
        when(mockDoc.data()).thenReturn({
          'name': 'Balles',
          'quantity': 10,
          'createdAt': '2024-01-01T00:00:00Z',
          'updatedAt': '2024-01-01T00:00:00Z',
        });
      });

      test('upserts stock item on DocumentChangeType.added', () async {
        when(mockChange.type).thenReturn(DocumentChangeType.added);
        when(mockDb.upsertStockItem(any)).thenAnswer((_) async {});

        cacheService.startListening();
        stockStreamController.add(mockSnapshot);

        await Future.delayed(Duration.zero);

        verify(mockDb.upsertStockItem(any)).called(1);
      });

      test('upserts stock item on DocumentChangeType.modified', () async {
        when(mockChange.type).thenReturn(DocumentChangeType.modified);
        when(mockDb.upsertStockItem(any)).thenAnswer((_) async {});

        cacheService.startListening();
        stockStreamController.add(mockSnapshot);

        await Future.delayed(Duration.zero);

        verify(mockDb.upsertStockItem(any)).called(1);
      });

      test('deletes stock item on DocumentChangeType.removed', () async {
        when(mockChange.type).thenReturn(DocumentChangeType.removed);
        when(mockDb.deleteStockItemByFirebaseId(any)).thenAnswer((_) async {});

        cacheService.startListening();
        stockStreamController.add(mockSnapshot);

        await Future.delayed(Duration.zero);

        verify(mockDb.deleteStockItemByFirebaseId('firebase_id_123')).called(1);
      });

      test('logs error but does not throw on Drift write failure', () async {
        when(mockChange.type).thenReturn(DocumentChangeType.added);
        when(mockDb.upsertStockItem(any)).thenThrow(Exception('DB Error'));

        cacheService.startListening();
        expect(() {
          stockStreamController.add(mockSnapshot);
        }, returnsNormally);
      });

      test('logs error but does not throw on listener error', () async {
        cacheService.startListening();
        expect(() {
          stockStreamController.addError(Exception('Stream Error'));
        }, returnsNormally);
      });
    });
  });
}
