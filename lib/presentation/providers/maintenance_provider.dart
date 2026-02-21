import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../domain/entities/maintenance.dart';
import '../../domain/entities/terrain.dart';
import '../../data/database/app_database.dart' as db;
import 'database_provider.dart';
import 'terrain_provider.dart';
import 'stock_provider.dart'; // Pour invalider les stocks

/// Provider pour les maintenances d'un terrain
final maintenancesByTerrainProvider =
    FutureProvider.family<List<Maintenance>, int>((ref, terrainId) {
      final database = ref.watch(databaseProvider);
      return database.getMaintenancesForTerrain(terrainId);
    });

/// Provider pour le nombre de maintenances d'un terrain
final maintenanceCountProvider = FutureProvider.family<int, int>((
  ref,
  terrainId,
) {
  final database = ref.watch(databaseProvider);
  return database.getMaintenanceCount(terrainId);
});

/// Notifier pour gérer les opérations CRUD sur les maintenances
/// Contient toute la logique métier de validation et liaison stock
class MaintenanceNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  MaintenanceNotifier(this._ref) : super(const AsyncValue.data(null));

  db.AppDatabase get _database => _ref.read(databaseProvider);

  /// Types de maintenance interdits pour les terrains durs
  static const List<String> _maintenanceTypesInterditsDur = [
    'Recharge',
    'recharge',
    'Compactage',
    'compactage',
    'Décompactage',
    'décompactage',
    'Travail de ligne',
    'travail de ligne',
  ];

  /// Valide les règles métier de base
  Future<void> _validateMaintenance(
    Maintenance maintenance,
    Terrain terrain,
  ) async {
    // Règle métier : Terre battue → Manto + Sottomanto uniquement
    if (terrain.type == TerrainType.terreBattue) {
      if (maintenance.sacsSiliceUtilises > 0) {
        throw Exception(
          'Un terrain en terre battue ne peut pas utiliser de silice',
        );
      }
    }

    // Règle métier : Synthétique → Silice uniquement
    if (terrain.type == TerrainType.synthetique) {
      if (maintenance.sacsMantoUtilises > 0 ||
          maintenance.sacsSottomantoUtilises > 0) {
        throw Exception(
          'Un terrain synthétique ne peut utiliser que de la silice',
        );
      }
    }

    // Règle métier : Dur → Aucun matériau autorisé + certains types interdits
    if (terrain.type == TerrainType.dur) {
      if (maintenance.sacsMantoUtilises > 0 ||
          maintenance.sacsSottomantoUtilises > 0 ||
          maintenance.sacsSiliceUtilises > 0) {
        throw Exception(
          'Un terrain dur ne peut pas utiliser de matériaux',
        );
      }

      if (_maintenanceTypesInterditsDur.contains(maintenance.type.toLowerCase())) {
        throw Exception(
          'Le type de maintenance "${maintenance.type}" n\'est pas autorisé pour les terrains durs',
        );
      }
    }
  }

  /// Ajoute une nouvelle maintenance avec vérification de stock
  Future<void> addMaintenance(Maintenance maintenance) async {
    state = const AsyncValue.loading();

    try {
      final terrain = await _database.getTerrainById(maintenance.terrainId);
      if (terrain == null) throw Exception('Terrain introuvable');

      // 1. Validations métier classiques
      await _validateMaintenance(maintenance, terrain);

      // 2. Insertion transactionnelle avec déduction de stock
      await _database.insertMaintenanceWithStockCheck(maintenance);

      // 3. Invalidation des caches pour rafraîchir l'UI
      _ref.invalidate(maintenancesByTerrainProvider(maintenance.terrainId));
      _ref.invalidate(maintenanceCountProvider(maintenance.terrainId));
      _ref.invalidate(terrainsProvider);
      _ref.invalidate(stockItemsProvider); // 👈 Important : rafraîchir les stocks

      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  /// Met à jour une maintenance existante avec ajustement automatique du stock
  Future<void> updateMaintenance(Maintenance maintenance) async {
    if (maintenance.id == null) {
      throw Exception('ID de maintenance requis pour la mise à jour');
    }

    state = const AsyncValue.loading();

    try {
      final terrain = await _database.getTerrainById(maintenance.terrainId);
      if (terrain == null) throw Exception('Terrain introuvable');

      await _validateMaintenance(maintenance, terrain);

      // Mise à jour avec ajustement intelligent du stock
      await _database.updateMaintenanceWithStockAdjustment(maintenance);

      _ref.invalidate(maintenancesByTerrainProvider(maintenance.terrainId));
      _ref.invalidate(maintenanceCountProvider(maintenance.terrainId));
      _ref.invalidate(terrainsProvider);
      _ref.invalidate(stockItemsProvider); // Rafraîchir les stocks

      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  /// Supprime une maintenance avec restauration du stock
  Future<void> deleteMaintenance(int maintenanceId, int terrainId) async {
    state = const AsyncValue.loading();

    try {
      // Suppression avec restauration des quantités au stock
      await _database.deleteMaintenanceWithStockRestoration(maintenanceId);

      _ref.invalidate(maintenancesByTerrainProvider(terrainId));
      _ref.invalidate(maintenanceCountProvider(terrainId));
      _ref.invalidate(terrainsProvider);
      _ref.invalidate(stockItemsProvider); // Rafraîchir les stocks

      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }
}

final maintenanceNotifierProvider =
    StateNotifierProvider<MaintenanceNotifier, AsyncValue<void>>((ref) {
      return MaintenanceNotifier(ref);
    });
