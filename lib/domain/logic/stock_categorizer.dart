import '../entities/stock_item.dart';

class StockCategorizer {
  static const String materiaux = 'Matériaux';
  static const String produitsEntretien = 'Produits d\'entretien';
  static const String fournitureMaintenance = 'Fourniture Maintenance';
  static const String autres = 'Autres';

  static String getCategory(StockItem item) {
    final name = item.name.toLowerCase();

    if (name.contains('manto') ||
        name.contains('sottomanto') ||
        name.contains('silice') ||
        name.contains('brique')) {
      return materiaux;
    }

    if (name.contains('peinture') ||
        name.contains('savon') ||
        name.contains('vitre') ||
        name.contains('démoussant') ||
        name.contains('nettoyant')) {
      return produitsEntretien;
    }

    if (name.contains('balais') ||
        name.contains('filet') ||
        name.contains('balle') ||
        name.contains('raclette') ||
        name.contains('pelle') ||
        name.contains('brosse')) {
      return fournitureMaintenance;
    }

    return autres;
  }

  static Map<String, List<StockItem>> groupItems(List<StockItem> items) {
    final Map<String, List<StockItem>> groups = {
      materiaux: [],
      produitsEntretien: [],
      fournitureMaintenance: [],
      autres: [],
    };

    for (var item in items) {
      final category = getCategory(item);
      groups.putIfAbsent(category, () => []).add(item);
    }

    // Remove empty groups if desired, or keep them to show empty sections
    groups.removeWhere((key, value) => value.isEmpty);

    return groups;
  }
}
