enum StockFilter {
  all,
  lowStock,
  fixed,        // ← AJOUTER (au lieu de "official")
  custom;

  String toDisplayString() {
    switch (this) {
      case StockFilter.all:
        return 'Tous';
      case StockFilter.lowStock:
        return 'En alerte';
      case StockFilter.fixed:
        return 'Fixes';
      case StockFilter.custom:
        return 'Personnalisés';
    }
  }
}