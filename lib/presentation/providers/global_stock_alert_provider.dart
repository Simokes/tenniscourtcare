import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'stock_provider.dart';

/// Identifie tous les articles dont la quantité est <= minThreshold
final globalStockAlertProvider = FutureProvider<int>((ref) async {
  final items = await ref.watch(stockProvider.future);

  final lowStock = items.where((item) {
    final threshold = item.minThreshold;
    if (threshold == null) return false;
    return item.quantity < threshold;
  }).length;

  return lowStock;
});

/// Retourne le nombre d'articles en alerte
final globalStockAlertCountProvider = Provider<AsyncValue<int>>((ref) {
  final alertsAsync = ref.watch(globalStockAlertProvider);
  return alertsAsync;
});
