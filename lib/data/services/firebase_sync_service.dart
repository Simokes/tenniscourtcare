import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/sync_status.dart';
import '../../domain/entities/terrain.dart';
import '../../domain/entities/maintenance.dart';
import '../../domain/entities/stock_item.dart';
import '../../domain/entities/app_event.dart';

class FirebaseSyncService {
  final FirebaseFirestore _firestore;
  late final FirebaseTerrainService terrainService;
  late final FirebaseMaintenanceService maintenanceService;
  late final FirebaseStockService stockService;
  late final FirebaseEventService eventService;

  FirebaseSyncService(this._firestore) {
    terrainService = FirebaseTerrainService(_firestore);
    maintenanceService = FirebaseMaintenanceService(_firestore);
    stockService = FirebaseStockService(_firestore);
    eventService = FirebaseEventService(_firestore);
  }

  /// Sync TOUS les données
  Future<void> syncAll() async {
    try {
      await Future.wait([
        syncTerrains(),
        syncMaintenances(),
        syncStock(),
        syncEvents(),
      ]);
    } catch (e) {
      print('Error syncing all: $e');
      rethrow;
    }
  }

  /// Sync terrains
  Future<void> syncTerrains() => terrainService.syncAll();

  /// Sync maintenances
  Future<void> syncMaintenances() => maintenanceService.syncAll();

  /// Sync stock
  Future<void> syncStock() => stockService.syncAll();

  /// Sync events
  Future<void> syncEvents() => eventService.syncAll();

  Stream<SyncStatus> watchSyncStatus() {
    // Placeholder for actual sync status stream logic
    // Currently returning 'synced' but could be enhanced with connectivity check
    // or pending upload count.
    return Stream.value(SyncStatus.synced);
  }
}

class FirebaseTerrainService {
  final FirebaseFirestore _firestore;
  FirebaseTerrainService(this._firestore);

  Future<void> uploadTerrainToFirestore(Terrain terrain) async {
    // Logic to upload terrain to 'terrains' collection
    // Mapping domain entity to Firestore JSON
    final data = {
      'nom': terrain.nom,
      'type': terrain.type.name,
      'status': terrain.status.name,
      'updatedAt': FieldValue.serverTimestamp(),
      // Add other fields as necessary
    };

    // If firebaseId is null, we might create a new doc, or use local ID if strategy permits
    // Usually we use a consistent ID or auto-gen.
    // Assuming simple set/add for now.
    if (terrain.firebaseId != null) {
      await _firestore.collection('terrains').doc(terrain.firebaseId).set(data, SetOptions(merge: true));
    } else {
      // If no firebaseId, we might create one and return it, but this method returns void.
      // Ideally the sync service handles ID mapping.
      // For this task, we follow "Fire and Forget" upload.
       await _firestore.collection('terrains').add(data);
    }
  }

  Stream<List<Terrain>> watchTerrains() {
    return _firestore.collection('terrains').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Terrain(
          id: 0, // Remote items might not have local ID initially, or need mapping
          nom: data['nom'] ?? '',
          type: TerrainType.values.firstWhere((e) => e.name == data['type'], orElse: () => TerrainType.terreBattue),
          status: TerrainStatus.values.firstWhere((e) => e.name == data['status'], orElse: () => TerrainStatus.playable),
          firebaseId: doc.id,
          updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          // Map other fields
        );
      }).toList();
    });
  }

  Future<void> syncAll() async {
    // Implementation for full sync if needed
  }
}

class FirebaseMaintenanceService {
  final FirebaseFirestore _firestore;
  FirebaseMaintenanceService(this._firestore);

  Future<void> uploadMaintenanceToFirestore(Maintenance maintenance) async {
    final data = {
      'terrainId': maintenance.terrainId,
      'type': maintenance.type,
      'updatedAt': FieldValue.serverTimestamp(),
      // other fields
    };
     if (maintenance.firebaseId != null) {
      await _firestore.collection('maintenances').doc(maintenance.firebaseId).set(data, SetOptions(merge: true));
    } else {
       await _firestore.collection('maintenances').add(data);
    }
  }

  Stream<List<Maintenance>> watchMaintenances() {
     return _firestore.collection('maintenances').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Maintenance(
          terrainId: data['terrainId'] ?? 0,
          type: data['type'] ?? '',
          date: 0, // Placeholder
          sacsMantoUtilises: 0,
          sacsSottomantoUtilises: 0,
          sacsSiliceUtilises: 0,
          firebaseId: doc.id,
          updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    });
  }

  Future<void> syncAll() async {}
}

class FirebaseStockService {
  final FirebaseFirestore _firestore;
  FirebaseStockService(this._firestore);

  Future<void> uploadStockToFirestore(StockItem item) async {
      final data = {
      'name': item.name,
      'quantity': item.quantity,
      'unit': item.unit,
      'comment': item.comment,
      'isCustom': item.isCustom,
      'minThreshold': item.minThreshold,
      'category': item.category,
      'sortOrder': item.sortOrder,
      'syncStatus': item.syncStatus.name,
      'createdAt': item.createdAt.toIso8601String(), // Or Timestamp
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': item.createdBy,
      'modifiedBy': item.modifiedBy,
    };
     if (item.firebaseId != null) {
      await _firestore.collection('stock').doc(item.firebaseId).set(data, SetOptions(merge: true));
    } else {
       await _firestore.collection('stock').add(data);
    }
  }

  Stream<List<StockItem>> watchStock() {
    return _firestore.collection('stock').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return StockItem(
          name: data['name'] as String? ?? '',
          quantity: (data['quantity'] as num?)?.toInt() ?? 0,
          unit: data['unit'] as String? ?? 'unit',
          comment: data['comment'] as String?,
          isCustom: data['isCustom'] as bool? ?? false,
          minThreshold: (data['minThreshold'] as num?)?.toInt(),
          category: data['category'] as String?,
          sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
          syncStatus: SyncStatus.fromString(data['syncStatus'] as String? ?? 'LOCAL'),
          createdAt: data['createdAt'] != null ? DateTime.tryParse(data['createdAt'] as String) ?? DateTime.now() : DateTime.now(),
          updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          firebaseId: doc.id,
          createdBy: data['createdBy'] as String?,
          modifiedBy: data['modifiedBy'] as String?,
        );
      }).toList();
    });
  }

  Future<void> syncAll() async {}
}

class FirebaseEventService {
  final FirebaseFirestore _firestore;
  FirebaseEventService(this._firestore);

  Future<void> uploadEventToFirestore(AppEvent event) async {
     final data = {
      'title': event.title,
      'startTime': Timestamp.fromDate(event.startTime),
      'endTime': Timestamp.fromDate(event.endTime),
      'updatedAt': FieldValue.serverTimestamp(),
    };
     if (event.firebaseId != null) {
      await _firestore.collection('events').doc(event.firebaseId).set(data, SetOptions(merge: true));
    } else {
       await _firestore.collection('events').add(data);
    }
  }

  Stream<List<AppEvent>> watchEvents() {
     return _firestore.collection('events').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return AppEvent(
          title: data['title'] ?? '',
          startTime: (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
          endTime: (data['endTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
          color: 0,
          terrainIds: [],
          firebaseId: doc.id,
          updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    });
  }

  Future<void> syncAll() async {}
}
