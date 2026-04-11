export interface StockItem {
  id: number | null;
  name: string;
  quantity: number;
  unit: string;
  comment: string | null;
  isCustom: boolean;
  minThreshold: number | null;
  category: string | null;
  sortOrder: number;

  // Sync fields
  createdAt: Date;
  updatedAt: Date;
  firebaseId: string | null;
  createdBy: string | null;
  modifiedBy: string | null;
}

export function isStockLow(item: StockItem): boolean {
  if (item.minThreshold === null) {
    return false;
  }
  return item.quantity <= item.minThreshold;
}
