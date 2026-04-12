import { create } from 'zustand';
import { User } from '@/domain/entities/user';
import { Role } from '@/domain/enums/role';

interface AuthState {
  user: User | null;
  role: Role | null;
  isSetupRequired: boolean;
  isLoading: boolean;
}

interface AuthStore extends AuthState {
  setUser: (user: User | null) => void;
  setRole: (role: Role | null) => void;
  setIsSetupRequired: (v: boolean) => void;
  setIsLoading: (v: boolean) => void;
  reset: () => void;
}

const initialState: AuthState = {
  user: null,
  role: null,
  isSetupRequired: false,
  isLoading: true,
};

export const useAuthStore = create<AuthStore>((set) => ({
  ...initialState,
  setUser: (user: User | null) => set({ user, role: user?.role ?? null }),
  setRole: (role: Role | null) => set({ role }),
  setIsSetupRequired: (v: boolean) => set({ isSetupRequired: v }),
  setIsLoading: (v: boolean) => set({ isLoading: v }),
  reset: () => set(initialState),
}));
