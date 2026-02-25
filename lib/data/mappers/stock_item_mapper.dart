import '../database/app_database.dart';
import '../../domain/entities/stock_item.dart' as domain;
import '../../domain/entities/sync_status.dart';
import 'package:drift/drift.dart';

extension StockItemRowMapper on StockItemRow {
  domain.StockItem toDomain() => domain.StockItem(
        id: id,
        name: name,
        quantity: quantity,
        unit: unit,
        comment: comment,
        isCustom: isCustom,
        minThreshold: minThreshold,
        updatedAt: updatedAt,
        category: category,
        sortOrder: sortOrder,
        // Sync mappings
        createdAt: createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
        firebaseId: remoteId,
        modifiedBy: lastModifiedBy,
        syncStatus: remoteId != null ? SyncStatus.synced : SyncStatus.local,
      );
}

extension StockItemDomainMapper on domain.StockItem {
  StockItemsCompanion toCompanion() => StockItemsCompanion(
        id: id == null ? const Value.absent() : Value(id!),
        name: Value(name),
        quantity: Value(quantity),
        unit: Value(unit),
        comment: Value(comment),
        isCustom: Value(isCustom),
        minThreshold: Value(minThreshold),
        updatedAt: Value(updatedAt),
        category: Value(category),
        sortOrder: Value(sortOrder),
        // Sync mappings
        createdAt: Value(createdAt),
        remoteId: Value(firebaseId),
        lastModifiedBy: Value(modifiedBy),
        // We set isSyncPending to true if status is not synced (simple logic for now)
        isSyncPending: Value(syncStatus != SyncStatus.synced),
      );
}
