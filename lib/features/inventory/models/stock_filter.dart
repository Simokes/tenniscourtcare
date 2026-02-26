enum StockFilter {
  all,
  lowStock,
  fixed,
  custom;

  String get label {
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
