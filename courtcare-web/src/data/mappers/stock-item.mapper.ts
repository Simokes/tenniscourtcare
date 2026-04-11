import { StockItem } from '../../domain/entities/stock-item';
import { Timestamp } from 'firebase/firestore';

function parseTimestamp(ts: unknown): Date {
  if (ts instanceof Timestamp) {
    return ts.toDate();
  }
  if (typeof ts === 'string') {
    return new Date(ts);
  }
  return new Date();
}

export function firestoreToStockItem(id: string, data: Record<string, unknown>): StockItem {
  return {
    id: null,
    name: String(data['name'] ?? ''),
    quantity: Number(data['quantity'] ?? 0),
    unit: String(data['unit'] ?? ''),
    comment: data['comment'] != null ? String(data['comment']) : null,
    isCustom: Boolean(data['isCustom'] ?? false),
    minThreshold: data['minThreshold'] != null ? Number(data['minThreshold']) : null,
    category: data['category'] != null ? String(data['category']) : null,
    sortOrder: Number(data['sortOrder'] ?? 0),
    createdAt: parseTimestamp(data['createdAt']),
    updatedAt: parseTimestamp(data['updatedAt']),
    firebaseId: id,
    createdBy: data['createdBy'] != null ? String(data['createdBy']) : null,
    modifiedBy: data['modifiedBy'] != null ? String(data['modifiedBy']) : null,
  };
}

export function stockItemToFirestore(item: StockItem): Record<string, unknown> {
  const result: Record<string, unknown> = {
    name: item.name,
    quantity: item.quantity,
    unit: item.unit,
    isCustom: item.isCustom,
    sortOrder: item.sortOrder,
    createdAt: Timestamp.fromDate(item.createdAt),
    updatedAt: Timestamp.fromDate(item.updatedAt),
    firebaseId: item.firebaseId,
  };

  if (item.comment !== null) result['comment'] = item.comment;
  if (item.minThreshold !== null) result['minThreshold'] = item.minThreshold;
  if (item.category !== null) result['category'] = item.category;
  if (item.createdBy !== null) result['createdBy'] = item.createdBy;
  if (item.modifiedBy !== null) result['modifiedBy'] = item.modifiedBy;

  return result;
}
