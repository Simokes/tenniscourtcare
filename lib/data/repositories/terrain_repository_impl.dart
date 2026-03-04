import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/terrain.dart';
import '../../domain/models/repository_exception.dart';
import '../../domain/repositories/terrain_repository.dart';
import '../database/app_database.dart';
import '../mappers/terrain_mapper.dart';

class TerrainRepositoryImpl implements TerrainRepository {
  const TerrainRepositoryImpl({
    required AppDatabase db,
    required FirebaseFirestore fs,
  })  : _db = db,
        _fs = fs;

  final AppDatabase _db;
  final FirebaseFirestore _fs;

  @override
  Future<String> addTerrain(Terrain terrain) async {
    try {
      final docRef = await _fs
          .collection('terrains')
          .add(TerrainMapper.toFirestore(terrain));
      return docRef.id;
    } on FirebaseException catch (e) {
      debugPrint('❌ TerrainRepository: Failed to add terrain: ${e.message}');
      throw RepositoryException('Failed to add terrain: ${e.message}', cause: e);
    }
  }

  @override
  Future<void> updateTerrain(Terrain terrain) async {
    if (terrain.firebaseId == null) {
      throw const RepositoryException('Cannot update terrain without a firebaseId');
    }

    try {
      await _fs
          .collection('terrains')
          .doc(terrain.firebaseId)
          .update(TerrainMapper.toFirestore(terrain));
    } on FirebaseException catch (e) {
      debugPrint('❌ TerrainRepository: Failed to update terrain: ${e.message}');
      throw RepositoryException('Failed to update terrain: ${e.message}', cause: e);
    }
  }

  @override
  Future<void> deleteTerrain(String firebaseId) async {
    try {
      await _fs.collection('terrains').doc(firebaseId).delete();
    } on FirebaseException catch (e) {
      debugPrint('❌ TerrainRepository: Failed to delete terrain: ${e.message}');
      throw RepositoryException('Failed to delete terrain: ${e.message}', cause: e);
    }
  }

  @override
  Future<List<Terrain>> getAllTerrains() async {
    return _db.getAllTerrains();
  }

  @override
  Future<Terrain?> getTerrainById(int id) async {
    return _db.getTerrainById(id);
  }
}
