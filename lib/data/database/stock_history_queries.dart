import 'package:drift/drift.dart';
import 'app_database.dart';

class StockMovementWithDetails {
  final StockMovement movement;
  final String itemName;
  final String? userName;

  StockMovementWithDetails({
    required this.movement,
    required this.itemName,
    this.userName,
  });
}

extension StockMovementsQueries on AppDatabase {
  Stream<List<StockMovementWithDetails>> watchStockHistory({
    int? limit,
    int? offset,
  }) {
    // Join StockMovements with StockItems and Users
    final query = select(stockMovements).join([
      leftOuterJoin(stockItems, stockItems.id.equalsExp(stockMovements.stockItemId)),
      leftOuterJoin(users, users.id.equalsExp(stockMovements.userId)),
    ])
      ..orderBy([OrderingTerm.desc(stockMovements.occurredAt)]);

    if (limit != null) {
      query.limit(limit, offset: offset);
    }

    return query.watch().map((rows) {
      return rows.map((row) {
        final movement = row.readTable(stockMovements);
        final item = row.readTableOrNull(stockItems);
        final user = row.readTableOrNull(users);

        return StockMovementWithDetails(
          movement: movement,
          itemName: item?.name ?? 'Article supprimé',
          userName: user?.name,
        );
      }).toList();
    });
  }
}
