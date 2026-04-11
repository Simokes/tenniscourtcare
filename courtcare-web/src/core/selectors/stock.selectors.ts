import { StockItem, isStockLow } from '@/domain/entities/stock-item';

export function getLowStockItems(items: StockItem[]): StockItem[] {
  return items.filter((item) => isStockLow(item));
}

export function getCriticalItems(items: StockItem[]): StockItem[] {
  return items.filter((item) => item.minThreshold !== null && item.quantity === 0);
}

export function getItemsByCategory(items: StockItem[]): Record<string, StockItem[]> {
  const grouped = items.reduce((acc, item) => {
    const categoryKey = item.category || 'sans-categorie';
    if (!acc[categoryKey]) {
      acc[categoryKey] = [];
    }
    acc[categoryKey].push(item);
    return acc;
  }, {} as Record<string, StockItem[]>);

  // Sort each group by sortOrder
  Object.keys(grouped).forEach((key) => {
    grouped[key].sort((a, b) => a.sortOrder - b.sortOrder);
  });

  return grouped;
}

export function searchItems(items: StockItem[], query: string): StockItem[] {
  if (!query.trim()) {
    return items;
  }

  const lowerQuery = query.toLowerCase();
  return items.filter((item) => {
    const nameMatch = item.name.toLowerCase().includes(lowerQuery);
    const commentMatch = item.comment ? item.comment.toLowerCase().includes(lowerQuery) : false;
    return nameMatch || commentMatch;
  });
}

export function sortItemsBySortOrder(items: StockItem[]): StockItem[] {
  return [...items].sort((a, b) => a.sortOrder - b.sortOrder);
}
