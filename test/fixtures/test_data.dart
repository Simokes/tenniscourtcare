import 'package:flutter/material.dart';
import 'package:tenniscourtcare/domain/entities/terrain.dart';
import 'package:tenniscourtcare/domain/entities/stock_item.dart';
import 'package:tenniscourtcare/domain/entities/maintenance.dart';
import 'package:tenniscourtcare/domain/entities/app_event.dart';

class TestData {
  // ============= TERRAIN TEST DATA =============
  static final testTerrain = Terrain(
    id: 1,
    nom: 'Court 1',
    type: TerrainType.dur,
    status: TerrainStatus.playable,
    latitude: 48.8566,
    longitude: 2.3522,
    photoUrl: null,
    createdAt: null,
    updatedAt: null,
    firebaseId: 'terrain_001',
    createdBy: 'admin',
    modifiedBy: 'admin',
  );

  static final testTerrains = [testTerrain];

  // ============= STOCK ITEM TEST DATA =============
  static final testStockItem = StockItem(
    id: 1,
    name: 'Tennis Ball',
    category: 'Balls',
    quantity: 50,
    minThreshold: 20,
    unit: 'Box',
    isCustom: false,
    sortOrder: 0,
    createdAt: null,
    updatedAt: null,
    firebaseId: 'stock_001',
    createdBy: 'admin',
    modifiedBy: 'admin',
  );

  static final testStockItems = [testStockItem];

  // ============= MAINTENANCE TEST DATA =============
  static final testMaintenance = Maintenance(
    id: 1,
    terrainId: 1,
    type: 'Regular',
    commentaire: 'Monthly maintenance',
    date: 1704067200000,
    sacsMantoUtilises: 2,
    sacsSottomantoUtilises: 1,
    sacsSiliceUtilises: 0,
    imagePath: null,
    weather: null,
    terrainGele: false,
    terrainImpraticable: false,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
    firebaseId: 'maint_001',
    createdBy: 'admin',
    modifiedBy: 'admin',
  );

  static final testMaintenances = [testMaintenance];

  // ============= APP EVENT TEST DATA =============
  static final testEvent = AppEvent(
    id: 1,
    title: 'Tournament',
    description: 'Annual tournament',
    startTime: DateTime(2025, 12, 20, 10, 0),
    endTime: DateTime(2025, 12, 20, 12, 0),
    color: const Color(0xFF3B82F6).toARGB32(),
    terrainIds: const [1],
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
    firebaseId: 'event_001',
    createdBy: 'admin',
    modifiedBy: 'admin',
  );

  static final testEvents = [testEvent];
}
