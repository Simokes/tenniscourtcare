import { useEffect } from 'react';
import { onAuthStateChanged } from 'firebase/auth';
import { auth, db } from '@/core/firebase/client';
import { firestoreUserRepository } from '@/data/repositories/user.repository';
import { useAuthStore } from '@/core/stores/auth.store';
import logger from '@/core/utils/logger';
import { getDocs, collection } from 'firebase/firestore';

export function useAuthListener(): void {
  const { setUser, setIsLoading, setIsSetupRequired, reset } = useAuthStore();

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (firebaseUser) => {
      setIsLoading(true);
      if (!firebaseUser) {
        reset();
        return;
      }
      try {
        const user = await firestoreUserRepository.getByFirebaseUid(firebaseUser.uid);
        if (user) {
          setUser(user);
          logger.firestore('useAuth', 'user loaded from Firestore');
        } else {
          const snapshot = await getDocs(collection(db, 'users'));
          setIsSetupRequired(snapshot.empty);
          setUser(null);
        }
      } catch (err) {
        logger.error('useAuth', 'erreur chargement user', err);
        setUser(null);
      } finally {
        setIsLoading(false);
      }
    });
    return () => unsubscribe();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);
}

export function useAuth(): {
  user: import('@/domain/entities/user').User | null;
  role: import('@/domain/enums/role').Role | null;
  isSetupRequired: boolean;
  isLoading: boolean;
} {
  const user = useAuthStore((state) => state.user);
  const role = useAuthStore((state) => state.role);
  const isSetupRequired = useAuthStore((state) => state.isSetupRequired);
  const isLoading = useAuthStore((state) => state.isLoading);

  return {
    user,
    role,
    isSetupRequired,
    isLoading,
  };
}
