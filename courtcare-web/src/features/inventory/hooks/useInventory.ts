'use client'
import { useMemo } from 'react'
import { useFirestoreCollection } from '@/core/hooks/useFirestoreCollection'
import { firestoreStockItemRepository } from '@/data/repositories/stock-item.repository'
import {
  getLowStockItems,
  getCriticalItems,
  getItemsByCategory,
  searchItems,
  sortItemsBySortOrder
} from '@/core/selectors/stock.selectors'
import { StockItem } from '@/domain/entities/stock-item'

export function useInventory(searchQuery: string = ''): {
  items: StockItem[]
  filtered: StockItem[]
  byCategory: Record<string, StockItem[]>
  lowStock: StockItem[]
  critical: StockItem[]
  isLoading: boolean
  error: Error | null
} {
  const { data: items, isLoading, error } = useFirestoreCollection(
    firestoreStockItemRepository.subscribe
  )

  const sorted = useMemo(() => sortItemsBySortOrder(items), [items])
  const filtered = useMemo(() => searchItems(sorted, searchQuery), [sorted, searchQuery])
  const byCategory = useMemo(() => getItemsByCategory(filtered), [filtered])
  const lowStock = useMemo(() => getLowStockItems(items), [items])
  const critical = useMemo(() => getCriticalItems(items), [items])

  return { items, filtered, byCategory, lowStock, critical, isLoading, error }
}
