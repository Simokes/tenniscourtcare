import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/stock_item.dart';
import 'stock_provider.dart';

/// Identifie tous les articles dont la quantité est <= minThreshold
final globalStockAlertProvider = Provider<AsyncValue<List<StockItem>>>((ref) {
  final stockItemsAsync = ref.watch(stockItemsProvider);

  return stockItemsAsync.whenData((items) {
    return items.where((item) {
      // On ne prend en compte que les items ayant un seuil défini
      if (item.minThreshold == null) return false;
      return item.quantity <= item.minThreshold!;
    }).toList();
  });
});

/// Retourne le nombre d'articles en alerte
final globalStockAlertCountProvider = Provider<AsyncValue<int>>((ref) {
  final alertsAsync = ref.watch(globalStockAlertProvider);
  return alertsAsync.whenData((items) => items.length);
});
