
import 'package:flutter/foundation.dart';

@immutable
class StockItem {
  final int? id;
  final String name;
  final int quantity;
  final String unit;
  final String? comment;
  final bool isCustom;
  final int? minThreshold;
  final DateTime updatedAt;
  final String? category;
  final int sortOrder;

  const StockItem({
    this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    this.comment,
    required this.isCustom,
    this.minThreshold,
    required this.updatedAt,
    this.category,
    this.sortOrder = 0,
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
    DateTime? updatedAt,
    String? category,
    int? sortOrder,
  }) {
    return StockItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      comment: comment ?? this.comment,
      isCustom: isCustom ?? this.isCustom,
      minThreshold: minThreshold ?? this.minThreshold,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
      sortOrder: sortOrder ?? this.sortOrder,
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
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      quantity.hashCode ^
      unit.hashCode ^
      comment.hashCode ^
      isCustom.hashCode ^
      minThreshold.hashCode ^
      updatedAt.hashCode;

  @override
  String toString() {
    return 'StockItem{id: $id, name: $name, quantity: $quantity, unit: $unit, isCustom: $isCustom, isLow: $isLowOnStock}';
  }
}
