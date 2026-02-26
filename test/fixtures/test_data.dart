import 'package:tenniscourtcare/domain/entities/terrain.dart';
import 'package:tenniscourtcare/domain/entities/stock_item.dart';
import 'package:tenniscourtcare/domain/entities/maintenance.dart';
import 'package:tenniscourtcare/domain/entities/sync_status.dart';

class TestData {
  // Terrains
  static final testTerrain = Terrain(
    id: 1,
    nom: 'Court 1',
    type: TerrainType.terreBattue,
    status: TerrainStatus.playable,
    latitude: 45.0,
    longitude: 5.0,
    syncStatus: SyncStatus.local,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  static final testTerrains = [testTerrain];

  // Stock Items
  static final testStockItem = StockItem(
    id: 1,
    name: 'Tennis Ball',
    category: 'Balls',
    quantity: 50,
    minThreshold: 20,
    unit: 'Box',
    isCustom: false,
    sortOrder: 0,
    syncStatus: SyncStatus.local,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  static final testStockItems = [testStockItem];

  // Maintenance
  static final testMaintenance = Maintenance(
    id: 1,
    terrainId: 1,
    type: 'Cleaning',
    commentaire: 'Court cleaning',
    date: DateTime.now().millisecondsSinceEpoch,
    sacsMantoUtilises: 0,
    sacsSottomantoUtilises: 0,
    sacsSiliceUtilises: 0,
    syncStatus: SyncStatus.local,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  static final testMaintenances = [testMaintenance];
}
