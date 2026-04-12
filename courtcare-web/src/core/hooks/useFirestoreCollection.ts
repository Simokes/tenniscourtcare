import { useState, useEffect } from 'react';

export function useFirestoreCollection<T>(
  subscribe: (callback: (items: T[]) => void) => () => void
): { data: T[]; isLoading: boolean; error: Error | null } {
  const [data, setData] = useState<T[]>([]);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    let unsubscribe: (() => void) | undefined;

    try {
      unsubscribe = subscribe((items: T[]) => {
        setData(items);
        setIsLoading(false);
      });
    } catch (e) {
      setError(e as Error);
      setIsLoading(false);
    }

    return () => {
      if (unsubscribe) {
        unsubscribe();
      }
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return { data, isLoading, error };
}
