// lib/domain/entities/stock_item.dart

import 'package:flutter/foundation.dart';
import 'sync_status.dart';

@immutable
class StockItem {
  final int? id;
  final String name;
  final int quantity;
  final String unit;
  final String? comment;
  final bool isCustom;
  final int? minThreshold;
  final String? category;
  final int sortOrder;

  // Sync fields
  final SyncStatus syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? firebaseId;
  final String? createdBy;
  final String? modifiedBy;

  const StockItem({
    this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    this.comment,
    required this.isCustom,
    this.minThreshold,
    this.category,
    this.sortOrder = 0,
    this.syncStatus = SyncStatus.local,
    required this.createdAt,
    required this.updatedAt,
    this.firebaseId,
    this.createdBy,
    this.modifiedBy,
  });

  bool get isLowOnStock => minThreshold != null && quantity <= minThreshold!;

  StockItem copyWith({
    int? id,
    String? name,
    int? quantity,
    String? unit,
    String? comment,
    bool? isCustom,
    int? minThreshold,
    String? category,
    int? sortOrder,
    SyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? firebaseId,
    String? createdBy,
    String? modifiedBy,
  }) {
    return StockItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      comment: comment ?? this.comment,
      isCustom: isCustom ?? this.isCustom,
      minThreshold: minThreshold ?? this.minThreshold,
      category: category ?? this.category,
      sortOrder: sortOrder ?? this.sortOrder,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      firebaseId: firebaseId ?? this.firebaseId,
      createdBy: createdBy ?? this.createdBy,
      modifiedBy: modifiedBy ?? this.modifiedBy,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          quantity == other.quantity &&
          unit == other.unit &&
          comment == other.comment &&
          isCustom == other.isCustom &&
          minThreshold == other.minThreshold &&
          category == other.category &&
          sortOrder == other.sortOrder &&
          syncStatus == other.syncStatus &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          firebaseId == other.firebaseId &&
          createdBy == other.createdBy &&
          modifiedBy == other.modifiedBy;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      quantity.hashCode ^
      unit.hashCode ^
      comment.hashCode ^
      isCustom.hashCode ^
      minThreshold.hashCode ^
      category.hashCode ^
      sortOrder.hashCode ^
      syncStatus.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      firebaseId.hashCode ^
      createdBy.hashCode ^
      modifiedBy.hashCode;

  @override
  String toString() {
    return 'StockItem{id: $id, name: $name, quantity: $quantity, unit: $unit, isCustom: $isCustom, isLow: $isLowOnStock, syncStatus: $syncStatus, createdAt: $createdAt, updatedAt: $updatedAt}';
  }
}
