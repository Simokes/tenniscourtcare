import 'package:cloud_firestore/cloud_firestore.dart';
// filepath: lib/data/mappers/stock_item_mapper.dart

import 'package:drift/drift.dart' as drift;
import 'package:tenniscourtcare/data/database/app_database.dart' as db;

import 'package:tenniscourtcare/data/mappers/stock_item_model.dart';
import 'package:tenniscourtcare/domain/entities/stock_item.dart' as domain;
import 'package:tenniscourtcare/domain/entities/stock_item.dart';

class StockItemMapper {
  // Model → Domain Entity
  static domain.StockItem toDomain(StockItemModel model) {
    return domain.StockItem(
      id: model.id,
      name: model.name,
      quantity: model.quantity,
      unit: model.unit,
      comment: model.comment,
      isCustom: model.isCustom,
      minThreshold: model.minThreshold,
      category: model.category,
      sortOrder: model.sortOrder,
      createdAt: DateTime.parse(model.createdAt),
      updatedAt: DateTime.parse(model.updatedAt),
      firebaseId: model.firebaseId,
      createdBy: model.createdBy,
      modifiedBy: model.modifiedBy,
    );
  }

  // Domain Entity → Model
  static StockItemModel toModel(domain.StockItem domainItem) {
    return StockItemModel(
      id: domainItem.id,
      name: domainItem.name,
      quantity: domainItem.quantity,
      unit: domainItem.unit,
      comment: domainItem.comment,
      isCustom: domainItem.isCustom,
      minThreshold: domainItem.minThreshold,
      category: domainItem.category,
      sortOrder: domainItem.sortOrder,
      createdAt: domainItem.createdAt.toIso8601String(),
      updatedAt: domainItem.updatedAt.toIso8601String(),
      firebaseId: domainItem.firebaseId,
      createdBy: domainItem.createdBy,
      modifiedBy: domainItem.modifiedBy,
    );
  }

  // Drift Entity → Domain Entity
  static domain.StockItem fromDriftEntity(db.StockItemRow driftEntity) {
    return domain.StockItem(
      id: driftEntity.id,
      name: driftEntity.name,
      quantity: driftEntity.quantity,
      unit: driftEntity.unit,
      comment: driftEntity.comment,
      isCustom: driftEntity.isCustom,
      minThreshold: driftEntity.minThreshold,
      category: driftEntity.category,
      sortOrder: driftEntity.sortOrder,
      createdAt: driftEntity.createdAt,
      updatedAt: driftEntity.updatedAt,
      firebaseId:
          driftEntity.firebaseId ??
          driftEntity.remoteId, // Fallback to remoteId
      createdBy: driftEntity.createdBy,
      modifiedBy:
          driftEntity.modifiedBy ??
          driftEntity.lastModifiedBy, // Fallback to lastModifiedBy
    );
  }

  // Domain Entity → Firestore Map
  static Map<String, dynamic> toFirestore(domain.StockItem item) {
    return {
      'name': item.name,
      'quantity': item.quantity,
      'unit': item.unit,
      'comment': item.comment,
      'isCustom': item.isCustom,
      'minThreshold': item.minThreshold,
      'category': item.category,
      'sortOrder': item.sortOrder,
      'createdAt': item.createdAt.toIso8601String(),
      'updatedAt': item.updatedAt.toIso8601String(),
      'createdBy': item.createdBy,
      'modifiedBy': item.modifiedBy,
      'firebaseId': item.firebaseId,
    };
  }

  // Firestore Snapshot → Drift Companion
  static db.StockItemsCompanion toCompanion(
    String docId,
    Map<String, dynamic> data,
  ) {
    DateTime parseTimestamp(dynamic ts) {
      if (ts is Timestamp) return ts.toDate();
      if (ts is String) return DateTime.tryParse(ts) ?? DateTime.now();
      return DateTime.now();
    }

    return db.StockItemsCompanion(
      name: drift.Value(data['name'] as String? ?? ''),
      quantity: drift.Value((data['quantity'] as num?)?.toInt() ?? 0),
      unit: drift.Value(data['unit'] as String? ?? 'unité'),
      comment: data['comment'] != null
          ? drift.Value(data['comment'] as String)
          : const drift.Value.absent(),
      isCustom: drift.Value(data['isCustom'] as bool? ?? false),
      minThreshold: data['minThreshold'] != null
          ? drift.Value((data['minThreshold'] as num).toInt())
          : const drift.Value.absent(),
      category: data['category'] != null
          ? drift.Value(data['category'] as String)
          : const drift.Value.absent(),
      sortOrder: drift.Value(data['sortOrder'] as int? ?? 0),
      firebaseId: drift.Value(docId), // ✅ docId direct
      remoteId: drift.Value(docId), // ✅ docId direct
      createdAt: drift.Value(parseTimestamp(data['createdAt'])),
      updatedAt: drift.Value(parseTimestamp(data['updatedAt'])),
      createdBy: data['createdBy'] != null
          ? drift.Value(data['createdBy'] as String)
          : const drift.Value.absent(),
      modifiedBy: data['modifiedBy'] != null
          ? drift.Value(data['modifiedBy'] as String)
          : const drift.Value.absent(),
      lastModifiedBy: data['modifiedBy'] != null
          ? drift.Value(data['modifiedBy'] as String)
          : const drift.Value.absent(),
      isSyncPending: const drift.Value(false),
    );
  }
}

// Extensions for compatibility
extension StockItemModelX on StockItemModel {
  domain.StockItem toDomain() => StockItemMapper.toDomain(this);
}

extension StockItemDriftX on db.StockItemRow {
  domain.StockItem toDomain() => StockItemMapper.fromDriftEntity(this);
}

// Domain → Companion (Keeping for DB inserts)
extension StockItemMapperX on StockItem {
  db.StockItemsCompanion toCompanion() {
    return db.StockItemsCompanion(
      id: id == null ? const drift.Value.absent() : drift.Value(id!),
      name: drift.Value(name),
      quantity: drift.Value(quantity),
      unit: drift.Value(unit),
      comment: comment == null
          ? const drift.Value.absent()
          : drift.Value(comment),
      isCustom: drift.Value(isCustom),
      minThreshold: minThreshold == null
          ? const drift.Value.absent()
          : drift.Value(minThreshold),
      category: category == null
          ? const drift.Value.absent()
          : drift.Value(category),
      sortOrder: drift.Value(sortOrder),
      createdAt: drift.Value(createdAt),
      updatedAt: drift.Value(updatedAt),
      firebaseId: firebaseId == null
          ? const drift.Value.absent()
          : drift.Value(firebaseId),
      createdBy: createdBy == null
          ? const drift.Value.absent()
          : drift.Value(createdBy),
      modifiedBy: modifiedBy == null
          ? const drift.Value.absent()
          : drift.Value(modifiedBy),
      remoteId: firebaseId == null
          ? const drift.Value.absent()
          : drift.Value(firebaseId),
      lastModifiedBy: modifiedBy == null
          ? const drift.Value.absent()
          : drift.Value(modifiedBy),
      isSyncPending: const drift.Value(false), // Replaced SyncStatus dependency
    );
  }
}
