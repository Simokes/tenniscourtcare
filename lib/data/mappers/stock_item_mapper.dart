// filepath: lib/data/mappers/stock_item_mapper.dart

import 'package:drift/drift.dart';
import 'package:tenniscourtcare/data/database/app_database.dart' as db;
import 'package:tenniscourtcare/data/models/stock_item_model.dart';
import 'package:tenniscourtcare/domain/entities/stock_item.dart' as domain;
import 'package:tenniscourtcare/domain/entities/sync_status.dart';

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
      syncStatus: SyncStatus.fromString(model.syncStatus),
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
      syncStatus: domainItem.syncStatus.name,
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
      syncStatus: SyncStatus.fromString(driftEntity.syncStatus),
      createdAt: driftEntity.createdAt,
      updatedAt: driftEntity.updatedAt,
      firebaseId: driftEntity.firebaseId ?? driftEntity.remoteId, // Fallback to remoteId
      createdBy: driftEntity.createdBy,
      modifiedBy: driftEntity.modifiedBy ?? driftEntity.lastModifiedBy, // Fallback to lastModifiedBy
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
extension StockItemDomainX on domain.StockItem {
  db.StockItemsCompanion toCompanion() => db.StockItemsCompanion(
        id: id == null ? const Value.absent() : Value(id!),
        name: Value(name),
        quantity: Value(quantity),
        unit: Value(unit),
        comment: Value(comment),
        isCustom: Value(isCustom),
        minThreshold: Value(minThreshold),
        category: Value(category),
        sortOrder: Value(sortOrder),
        // Sync mappings
        syncStatus: Value(syncStatus.name),
        createdAt: Value(createdAt),
        updatedAt: Value(updatedAt),
        firebaseId: Value(firebaseId),
        remoteId: Value(firebaseId), // Fallback/Legacy
        createdBy: Value(createdBy),
        modifiedBy: Value(modifiedBy),
        lastModifiedBy: Value(modifiedBy), // Fallback/Legacy
        // Maintain isSyncPending logic for backward compatibility
        isSyncPending: Value(syncStatus != SyncStatus.synced),
      );
}
