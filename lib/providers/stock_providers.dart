import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../presentation/providers/database_provider.dart';
import '../presentation/providers/auth_providers.dart';
import '../domain/entities/stock_item.dart' as dom;
import '../domain/enums/role.dart';
import '../data/mappers/stock_item_mapper.dart';
import '../services/listener_monitor.dart';

part 'stock_providers.g.dart';

@Riverpod(keepAlive: true)
Stream<List<dom.StockItem>> stockStream(StockStreamRef ref) {
  final monitor = ListenerMonitor();
  monitor.registerListener('stockStreamProvider');
  ref.onDispose(() => monitor.unregisterListener('stockStreamProvider'));

  final auth = ref.watch(currentUserProvider);
  if (auth == null || auth.role != Role.admin) {
    throw Exception('Unauthorized: Admin only');
  }

  final db = ref.watch(databaseProvider);

  return db.select(db.stockItems).watch().map((rows) {
    return rows.map((r) => r.toDomain()).where((item) {
      final min = item.minThreshold;
      if (min == null) return false; // Skip if no threshold set
      return item.quantity <= min;
    }).toList()..sort(
      (a, b) => a.quantity.compareTo(b.quantity),
    ); // ASC (most critical first)
  });
}

@Riverpod()
Stream<int> lowStockCount(LowStockCountRef ref) {
  final auth = ref.watch(currentUserProvider);
  if (auth == null || auth.role != Role.admin) {
    return Stream.value(0);
  }

  // We watch the stockStreamProvider which already filters low stock items
  // Note: If stockStreamProvider throws (e.g. auth issue), this might fail.
  // But we check auth here too.
  return ref.watch(stockStreamProvider.stream).map((items) => items.length);
}
