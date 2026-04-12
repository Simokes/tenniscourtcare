import { useFirestoreCollection } from '@/core/hooks/useFirestoreCollection';
import { firestoreTerrainRepository } from '@/data/repositories/terrain.repository';
import { firestoreMaintenanceRepository } from '@/data/repositories/maintenance.repository';
import { firestoreAppEventRepository } from '@/data/repositories/app-event.repository';
import { firestoreStockItemRepository } from '@/data/repositories/stock-item.repository';
import { Terrain } from '@/domain/entities/terrain';
import { Maintenance } from '@/domain/entities/maintenance';
import { AppEvent } from '@/domain/entities/app-event';
import { StockItem } from '@/domain/entities/stock-item';

export function useDashboard(): {
  terrains: Terrain[];
  maintenances: Maintenance[];
  events: AppEvent[];
  stockItems: StockItem[];
  isLoading: boolean;
  error: Error | null;
} {
  const { data: terrains, isLoading: loadingTerrains, error: terrainsError } = useFirestoreCollection(
    firestoreTerrainRepository.subscribe
  );
  const { data: maintenances, isLoading: loadingMaintenances, error: maintenancesError } = useFirestoreCollection(
    firestoreMaintenanceRepository.subscribe
  );
  const { data: events, isLoading: loadingEvents, error: eventsError } = useFirestoreCollection(
    firestoreAppEventRepository.subscribe
  );
  const { data: stockItems, isLoading: loadingStockItems, error: stockItemsError } = useFirestoreCollection(
    firestoreStockItemRepository.subscribe
  );

  const isLoading = loadingTerrains || loadingMaintenances || loadingEvents || loadingStockItems;
  const error = terrainsError || maintenancesError || eventsError || stockItemsError || null;

  return {
    terrains,
    maintenances,
    events,
    stockItems,
    isLoading,
    error,
  };
}
