import '../database/app_database.dart';
import '../../domain/entities/stock_item.dart' as domain;
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
      );
}
