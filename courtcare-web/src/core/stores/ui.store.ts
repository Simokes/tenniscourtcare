import { create } from 'zustand';

interface UIStore {
  isSidebarOpen: boolean;
  activeModal: string | null;
  setSidebarOpen: (open: boolean) => void;
  toggleSidebar: () => void;
  openModal: (modalId: string) => void;
  closeModal: () => void;
}

const initialState = {
  isSidebarOpen: false,
  activeModal: null,
};

export const useUIStore = create<UIStore>((set) => ({
  ...initialState,
  setSidebarOpen: (open: boolean) => set({ isSidebarOpen: open }),
  toggleSidebar: () => set((state) => ({ isSidebarOpen: !state.isSidebarOpen })),
  openModal: (modalId: string) => set({ activeModal: modalId }),
  closeModal: () => set({ activeModal: null }),
}));
