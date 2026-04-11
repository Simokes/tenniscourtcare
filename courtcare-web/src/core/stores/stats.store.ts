import { create } from 'zustand';

type StatsPeriod = 'week' | 'month' | 'year' | 'custom';

interface StatsState {
  period: StatsPeriod;
  selectedTerrainIds: number[];
  customStart: Date | null;
  customEnd: Date | null;
}

interface StatsStore extends StatsState {
  setPeriod: (period: StatsPeriod) => void;
  setSelectedTerrainIds: (ids: number[]) => void;
  toggleTerrainId: (id: number) => void;
  setCustomRange: (start: Date, end: Date) => void;
  reset: () => void;
}

const initialState: StatsState = {
  period: 'month',
  selectedTerrainIds: [],
  customStart: null,
  customEnd: null,
};

export const useStatsStore = create<StatsStore>((set) => ({
  ...initialState,
  setPeriod: (period: StatsPeriod) => set({ period }),
  setSelectedTerrainIds: (ids: number[]) => set({ selectedTerrainIds: ids }),
  toggleTerrainId: (id: number) =>
    set((state) => ({
      selectedTerrainIds: state.selectedTerrainIds.includes(id)
        ? state.selectedTerrainIds.filter((terrainId) => terrainId !== id)
        : [...state.selectedTerrainIds, id],
    })),
  setCustomRange: (start: Date, end: Date) =>
    set({ customStart: start, customEnd: end, period: 'custom' }),
  reset: () => set(initialState),
}));
