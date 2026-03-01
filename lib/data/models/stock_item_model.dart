// filepath: lib/data/models/stock_item_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tenniscourtcare/domain/entities/stock_item.dart';
import 'package:tenniscourtcare/domain/entities/sync_status.dart';

class StockItemModel {
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
  final String syncStatus;
  final String createdAt;
  final String updatedAt;
  final String? firebaseId;
  final String? createdBy;
  final String? modifiedBy;

  const StockItemModel({
    this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    this.comment,
    required this.isCustom,
    this.minThreshold,
    this.category,
    required this.sortOrder,
    required this.syncStatus,
    required this.createdAt,
    required this.updatedAt,
    this.firebaseId,
    this.createdBy,
    this.modifiedBy,
  });

  /// Firestore → Model
  factory StockItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = 0; // Local ID
    data['firebaseId'] = doc.id;
    return StockItemModel.fromJson(data);
  }

  /// JSON → Model
  factory StockItemModel.fromJson(Map<String, dynamic> json) {
    return StockItemModel(
      id: json['id'] as int?,
      name: json['name'] as String,
      quantity: json['quantity'] as int,
      unit: json['unit'] as String,
      comment: json['comment'] as String?,
      isCustom: json['isCustom'] as bool,
      minThreshold: json['minThreshold'] as int?,
      category: json['category'] as String?,
      sortOrder: json['sortOrder'] as int? ?? 0,
      syncStatus: json['syncStatus'] as String? ?? 'LOCAL',
      createdAt:
          json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt:
          json['updatedAt'] as String? ?? DateTime.now().toIso8601String(),
      firebaseId: json['firebaseId'] as String?,
      createdBy: json['createdBy'] as String?,
      modifiedBy: json['modifiedBy'] as String?,
    );
  }

  /// Model → JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'comment': comment,
      'isCustom': isCustom,
      'minThreshold': minThreshold,
      'category': category,
      'sortOrder': sortOrder,
      'syncStatus': syncStatus,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'firebaseId': firebaseId,
      'createdBy': createdBy,
      'modifiedBy': modifiedBy,
    };
  }

  /// Model → Domain Entity
  StockItem toDomain() {
    return StockItem(
      id: id,
      name: name,
      quantity: quantity,
      unit: unit,
      comment: comment,
      isCustom: isCustom,
      minThreshold: minThreshold,
      category: category,
      sortOrder: sortOrder,
      syncStatus: SyncStatus.fromString(syncStatus),
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
      firebaseId: firebaseId,
      createdBy: createdBy,
      modifiedBy: modifiedBy,
    );
  }

  /// Domain Entity → Model
  factory StockItemModel.fromDomain(StockItem stockItem) {
    return StockItemModel(
      id: stockItem.id,
      name: stockItem.name,
      quantity: stockItem.quantity,
      unit: stockItem.unit,
      comment: stockItem.comment,
      isCustom: stockItem.isCustom,
      minThreshold: stockItem.minThreshold,
      category: stockItem.category,
      sortOrder: stockItem.sortOrder,
      syncStatus: stockItem.syncStatus.name,
      createdAt: stockItem.createdAt.toIso8601String(),
      updatedAt: stockItem.updatedAt.toIso8601String(),
      firebaseId: stockItem.firebaseId,
      createdBy: stockItem.createdBy,
      modifiedBy: stockItem.modifiedBy,
    );
  }
}
