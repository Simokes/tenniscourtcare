import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../domain/entities/maintenance.dart';
import '../../domain/entities/terrain.dart';
import '../../data/database/app_database.dart' as db;
import 'database_provider.dart';
import 'terrain_provider.dart';

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
/// Contient toute la logique métier de validation
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

  /// Valide les règles métier avant insertion/update
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
      // Interdire tous les matériaux
      if (maintenance.sacsMantoUtilises > 0 ||
          maintenance.sacsSottomantoUtilises > 0 ||
          maintenance.sacsSiliceUtilises > 0) {
        throw Exception(
          'Un terrain dur ne peut pas utiliser de matériaux (manto, sottomanto ou silice)',
        );
      }

      // Interdire certains types de maintenance
      if (_maintenanceTypesInterditsDur.contains(maintenance.type)) {
        throw Exception(
          'Le type de maintenance "${maintenance.type}" n\'est pas autorisé pour les terrains durs',
        );
      }
    }
  }

  /// Ajoute une nouvelle maintenance
  Future<void> addMaintenance(Maintenance maintenance) async {
    state = const AsyncValue.loading();

    try {
      // Récupérer le terrain pour validation
      final terrain = await _database.getTerrainById(maintenance.terrainId);
      if (terrain == null) {
        throw Exception('Terrain introuvable');
      }

      // Valider les règles métier
      await _validateMaintenance(maintenance, terrain);

      // Insérer en base
      await _database.insertMaintenance(maintenance);

      // Invalider les providers concernés pour mise à jour réactive
      _ref.invalidate(maintenancesByTerrainProvider(maintenance.terrainId));
      _ref.invalidate(maintenanceCountProvider(maintenance.terrainId));
      _ref.invalidate(terrainsProvider);

      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  /// Met à jour une maintenance existante
  Future<void> updateMaintenance(Maintenance maintenance) async {
    if (maintenance.id == null) {
      throw Exception('ID de maintenance requis pour la mise à jour');
    }

    state = const AsyncValue.loading();

    try {
      // Récupérer le terrain pour validation
      final terrain = await _database.getTerrainById(maintenance.terrainId);
      if (terrain == null) {
        throw Exception('Terrain introuvable');
      }

      // Valider les règles métier
      await _validateMaintenance(maintenance, terrain);

      // Mettre à jour en base
      await _database.updateMaintenance(
        db.MaintenancesCompanion(
          id: Value(maintenance.id!),
          terrainId: Value(maintenance.terrainId),
          type: Value(maintenance.type),
          commentaire: Value(maintenance.commentaire),
          date: Value(maintenance.date),
          sacsMantoUtilises: Value(maintenance.sacsMantoUtilises),
          sacsSottomantoUtilises: Value(maintenance.sacsSottomantoUtilises),
          sacsSiliceUtilises: Value(maintenance.sacsSiliceUtilises),
        ),
      );

      // Invalider les providers concernés
      _ref.invalidate(maintenancesByTerrainProvider(maintenance.terrainId));
      _ref.invalidate(maintenanceCountProvider(maintenance.terrainId));
      _ref.invalidate(terrainsProvider);

      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  /// Supprime une maintenance
  Future<void> deleteMaintenance(int maintenanceId, int terrainId) async {
    state = const AsyncValue.loading();

    try {
      await _database.deleteMaintenance(maintenanceId);

      // Invalider les providers concernés
      _ref.invalidate(maintenancesByTerrainProvider(terrainId));
      _ref.invalidate(maintenanceCountProvider(terrainId));
      _ref.invalidate(terrainsProvider);

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
