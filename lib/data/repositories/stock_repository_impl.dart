// filepath: lib/data/repositories/stock_repository_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:tenniscourtcare/data/database/app_database.dart';
import 'package:tenniscourtcare/data/mappers/stock_item_mapper.dart';
import 'package:tenniscourtcare/domain/entities/stock_item.dart';
import 'package:tenniscourtcare/domain/models/repository_exception.dart';
import 'package:tenniscourtcare/domain/repositories/stock_repository.dart';

class StockRepositoryImpl implements StockRepository {
  const StockRepositoryImpl({
    required AppDatabase db,
    required FirebaseFirestore fs,
  })  : _db = db,
        _fs = fs;

  final AppDatabase _db;
  final FirebaseFirestore _fs;

  @override
  Future<void> addStockItem(StockItem item) async {
    try {
      await _fs
          .collection('stocks')
          .add(StockItemMapper.toFirestore(item));
    } on FirebaseException catch (e) {
      debugPrint('❌ StockRepository: Failed to add stock item: ${e.message}');
      throw RepositoryException('Failed to add stock item: ${e.message}', cause: e);
    }
  }

  @override
  Future<void> updateStockItem(StockItem item) async {
    if (item.firebaseId == null) {
      throw const RepositoryException('Cannot update stock item without a firebaseId');
    }

    try {
      await _fs
          .collection('stocks')
          .doc(item.firebaseId)
          .update(StockItemMapper.toFirestore(item));
    } on FirebaseException catch (e) {
      debugPrint('❌ StockRepository: Failed to update stock item: ${e.message}');
      throw RepositoryException('Failed to update stock item: ${e.message}', cause: e);
    }
  }

  @override
  Future<void> deleteStockItem(String firebaseId) async {
    try {
      await _fs.collection('stocks').doc(firebaseId).delete();
    } on FirebaseException catch (e) {
      debugPrint('❌ StockRepository: Failed to delete stock item: ${e.message}');
      throw RepositoryException('Failed to delete stock item: ${e.message}', cause: e);
    }
  }

  @override
  Future<List<StockItem>> getAllStockItems() async {
    return _db.watchAllStockItems().first;
  }

  @override
  Future<StockItem?> getStockItemById(int id) async {
    final items = await _db.watchAllStockItems().first;
    return items.firstWhereOrNull((item) => item.id == id);
  }
}
