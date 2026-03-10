import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' show Value;
import 'package:mocktail/mocktail.dart';
import 'package:tenniscourtcare/data/database/app_database.dart';
import 'package:tenniscourtcare/data/services/firebase_cache_service.dart';

class MockAppDatabase extends Mock implements AppDatabase {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference<T extends Object?> extends Mock
    implements CollectionReference<T> {}

class MockQuerySnapshot<T extends Object?> extends Mock
    implements QuerySnapshot<T> {}

class MockDocumentChange<T extends Object?> extends Mock
    implements DocumentChange<T> {}

class MockQueryDocumentSnapshot<T extends Object?> extends Mock
    implements QueryDocumentSnapshot<T> {}

class MockSnapshotMetadata extends Mock implements SnapshotMetadata {}

class MockDocumentReference<T extends Object?> extends Mock
    implements DocumentReference<T> {}

void main() {
  late MockAppDatabase mockDb;
  late MockFirebaseFirestore mockFs;
  late FirebaseCacheService cacheService;
  late MockCollectionReference<Map<String, dynamic>> mockStockCollection;
  late MockCollectionReference<Map<String, dynamic>> mockTerrainsCollection;
  late MockCollectionReference<Map<String, dynamic>> mockMaintenancesCollection;
  late MockCollectionReference<Map<String, dynamic>> mockEventsCollection;
  late MockCollectionReference<Map<String, dynamic>> mockUsersCollection;

  setUpAll(() {
    registerFallbackValue(
      StockItemsCompanion.insert(
        name: '',
        quantity: const Value(0),
        minThreshold: const Value(0),
        unit: '',
        isCustom: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    registerFallbackValue(
      TerrainsCompanion.insert(
        nom: '',
        type: 0,
        status: const Value(''),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    registerFallbackValue(
      MaintenancesCompanion.insert(
        terrainId: 0,
        type: '',
        date: 0,
        sacsMantoUtilises: const Value(0),
        sacsSottomantoUtilises: const Value(0),
        sacsSiliceUtilises: const Value(0),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    registerFallbackValue(
      EventsCompanion.insert(
        title: '',
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        color: 0,
        terrainIds: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  });

  late StreamController<QuerySnapshot<Map<String, dynamic>>>
  stockStreamController;
  late StreamController<QuerySnapshot<Map<String, dynamic>>>
  terrainsStreamController;
  late StreamController<QuerySnapshot<Map<String, dynamic>>>
  maintenancesStreamController;
  late StreamController<QuerySnapshot<Map<String, dynamic>>>
  eventsStreamController;
  late StreamController<QuerySnapshot<Map<String, dynamic>>>
  usersStreamController;

  setUp(() {
    mockDb = MockAppDatabase();
    mockFs = MockFirebaseFirestore();

    mockStockCollection = MockCollectionReference();
    mockTerrainsCollection = MockCollectionReference();
    mockMaintenancesCollection = MockCollectionReference();
    mockEventsCollection = MockCollectionReference();
    mockUsersCollection = MockCollectionReference();

    stockStreamController =
        StreamController<QuerySnapshot<Map<String, dynamic>>>();
    terrainsStreamController =
        StreamController<QuerySnapshot<Map<String, dynamic>>>();
    maintenancesStreamController =
        StreamController<QuerySnapshot<Map<String, dynamic>>>();
    eventsStreamController =
        StreamController<QuerySnapshot<Map<String, dynamic>>>();
    usersStreamController =
        StreamController<QuerySnapshot<Map<String, dynamic>>>();

    when(() => mockFs.collection('stocks')).thenReturn(mockStockCollection);
    when(
      () => mockFs.collection('terrains'),
    ).thenReturn(mockTerrainsCollection);
    when(
      () => mockFs.collection('maintenance'),
    ).thenReturn(mockMaintenancesCollection);
    when(() => mockFs.collection('events')).thenReturn(mockEventsCollection);
    when(() => mockFs.collection('users')).thenReturn(mockUsersCollection);

    when(
      () => mockStockCollection.snapshots(),
    ).thenAnswer((_) => stockStreamController.stream);
    when(
      () => mockTerrainsCollection.snapshots(),
    ).thenAnswer((_) => terrainsStreamController.stream);
    when(
      () => mockMaintenancesCollection.snapshots(),
    ).thenAnswer((_) => maintenancesStreamController.stream);
    when(
      () => mockEventsCollection.snapshots(),
    ).thenAnswer((_) => eventsStreamController.stream);
    when(
      () => mockUsersCollection.snapshots(),
    ).thenAnswer((_) => usersStreamController.stream);

    cacheService = FirebaseCacheService(mockDb, mockFs);
  });

  tearDown(() {
    cacheService.stopListening();

    if (!stockStreamController.isClosed) stockStreamController.close();
    if (!terrainsStreamController.isClosed) terrainsStreamController.close();
    if (!maintenancesStreamController.isClosed) {
      maintenancesStreamController.close();
    }
    if (!eventsStreamController.isClosed) eventsStreamController.close();
    if (!usersStreamController.isClosed) usersStreamController.close();
  });

  group('FirebaseCacheService', () {
    group('startListening()', () {
      test('starts all collection listeners', () {
        cacheService.startListening();
        expect(cacheService.isListening, isTrue);

        verify(() => mockFs.collection('stocks')).called(1);
        verify(() => mockFs.collection('terrains')).called(1);
        verify(() => mockFs.collection('maintenance')).called(1);
        verify(() => mockFs.collection('events')).called(1);
        verify(() => mockFs.collection('users')).called(1);

        verify(() => mockStockCollection.snapshots()).called(1);
        verify(() => mockTerrainsCollection.snapshots()).called(1);
        verify(() => mockMaintenancesCollection.snapshots()).called(1);
        verify(() => mockEventsCollection.snapshots()).called(1);
        verify(() => mockUsersCollection.snapshots()).called(1);
      });

      test('is idempotent (calling twice does not duplicate listeners)', () {
        cacheService.startListening();
        cacheService.startListening();

        verify(() => mockFs.collection('stocks')).called(1);
        verify(() => mockStockCollection.snapshots()).called(1);
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
      late MockSnapshotMetadata mockMetadata;

      setUp(() {
        mockSnapshot = MockQuerySnapshot();
        mockChange = MockDocumentChange();
        mockDoc = MockQueryDocumentSnapshot();
        mockMetadata = MockSnapshotMetadata();

        when(() => mockMetadata.isFromCache).thenReturn(false);
        when(() => mockSnapshot.metadata).thenReturn(mockMetadata);
        when(() => mockSnapshot.docs).thenReturn([mockDoc]);
        when(() => mockSnapshot.docChanges).thenReturn([mockChange]);
        when(() => mockChange.doc).thenReturn(mockDoc);
        when(() => mockDoc.id).thenReturn('firebase_id_123');
        when(() => mockDoc.data()).thenReturn({
          'name': 'Balles',
          'quantity': 10,
          'unit': 'boîte',
          'isCustom': false,
          'createdAt': '2024-01-01T00:00:00Z',
          'updatedAt': '2024-01-01T00:00:00Z',
        });
      });

      test('upserts stock item on DocumentChangeType.added', () async {
        when(() => mockChange.type).thenReturn(DocumentChangeType.added);
        when(() => mockDb.upsertStockItem(any())).thenAnswer((_) async {});
        when(() => mockDb.deleteOrphanStockItems(any())).thenAnswer((_) async {});

        cacheService.startListening();
        stockStreamController.add(mockSnapshot);

        await Future.delayed(Duration.zero);

        verify(() => mockDb.upsertStockItem(any())).called(1);
        verify(() => mockDb.deleteOrphanStockItems(any())).called(1);
      });

      test('upserts stock item on DocumentChangeType.modified', () async {
        when(() => mockChange.type).thenReturn(DocumentChangeType.modified);
        when(() => mockDb.upsertStockItem(any())).thenAnswer((_) async {});
        when(() => mockDb.deleteOrphanStockItems(any())).thenAnswer((_) async {});

        cacheService.startListening();
        stockStreamController.add(mockSnapshot);

        await Future.delayed(Duration.zero);

        verify(() => mockDb.upsertStockItem(any())).called(1);
      });

      test('deletes stock item on DocumentChangeType.removed', () async {
        when(() => mockChange.type).thenReturn(DocumentChangeType.removed);
        when(
          () => mockDb.deleteStockItemByFirebaseId(any()),
        ).thenAnswer((_) async {});
        when(() => mockDb.deleteOrphanStockItems(any())).thenAnswer((_) async {});

        cacheService.startListening();
        stockStreamController.add(mockSnapshot);

        await Future.delayed(Duration.zero);

        verify(
          () => mockDb.deleteStockItemByFirebaseId('firebase_id_123'),
        ).called(1);
      });

      test('logs error but does not throw on Drift write failure', () async {
        when(() => mockChange.type).thenReturn(DocumentChangeType.added);
        when(
          () => mockDb.upsertStockItem(any()),
        ).thenThrow(Exception('DB Error'));
        when(() => mockDb.deleteOrphanStockItems(any())).thenAnswer((_) async {});

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

    group('_seedDefaultStockItems()', () {
      late MockQuerySnapshot<Map<String, dynamic>> mockSnapshot;
      late MockSnapshotMetadata mockMetadata;
      late MockDocumentReference<Map<String, dynamic>> mockDocRef;

      setUp(() {
        mockSnapshot = MockQuerySnapshot();
        mockMetadata = MockSnapshotMetadata();
        mockDocRef = MockDocumentReference();

        when(() => mockMetadata.isFromCache).thenReturn(false);
        when(() => mockSnapshot.metadata).thenReturn(mockMetadata);
        when(() => mockSnapshot.docChanges).thenReturn([]);
        when(() => mockSnapshot.docs).thenReturn([]);
        when(() => mockStockCollection.add(any())).thenAnswer((_) async => mockDocRef);
        when(() => mockDb.deleteOrphanStockItems(any())).thenAnswer((_) async {});
      });

      test('seed les 3 articles systeme si la collection est vide', () async {
        // Arrange
        cacheService.startListening();

        // Act
        stockStreamController.add(mockSnapshot);
        await Future.delayed(Duration.zero);

        // Assert
        verify(() => mockStockCollection.add(any())).called(3);
      });

      test('ne seed pas si la collection contient deja des documents', () async {
        // Arrange
        final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(() => mockDoc.id).thenReturn('existing_id');
        when(() => mockSnapshot.docs).thenReturn([mockDoc]);
        when(() => mockSnapshot.docChanges).thenReturn([]);
        cacheService.startListening();

        // Act
        stockStreamController.add(mockSnapshot);
        await Future.delayed(Duration.zero);

        // Assert
        verifyNever(() => mockStockCollection.add(any()));
      });

      test('ne seed pas sur un snapshot cache (isFromCache=true)', () async {
        // Arrange
        when(() => mockMetadata.isFromCache).thenReturn(true);
        cacheService.startListening();

        // Act
        stockStreamController.add(mockSnapshot);
        await Future.delayed(Duration.zero);

        // Assert
        verifyNever(() => mockStockCollection.add(any()));
      });
    });
  });
}
