import { useState, useEffect } from 'react';
import { DocumentReference, DocumentData, onSnapshot } from 'firebase/firestore';
import logger from '@/core/utils/logger';

export function useFirestoreDocument<T>(
  label: string,
  docRef: DocumentReference<DocumentData> | null,
  fromDoc: (id: string, data: Record<string, unknown>) => T
): { data: T | null; isLoading: boolean; error: Error | null } {
  const [data, setData] = useState<T | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    if (!docRef) {
      return;
    }

    logger.firestore(label, 'subscribe document');
    const unsubscribe = onSnapshot(
      docRef,
      (snap) => {
        if (snap.exists()) {
          logger.firestore(label, 'snapshot recu');
          setData(fromDoc(snap.id, snap.data() as Record<string, unknown>));
        } else {
          setData(null);
        }
        setIsLoading(false);
      },
      (err) => {
        setError(err);
        setIsLoading(false);
      }
    );

    return () => unsubscribe();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [docRef?.path]); // Dependency on the path string is stable

  if (!docRef) {
    return { data: null, isLoading: false, error: null };
  }

  return { data, isLoading, error };
}
