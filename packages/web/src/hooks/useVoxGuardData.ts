import { useState, useEffect, useCallback } from 'react';

interface UseVoxGuardDataResult<T> {
  data: T | undefined;
  loading: boolean;
  error: Error | undefined;
  reload: () => void;
}

export function useVoxGuardData<T>(fetchFn: () => Promise<T>): UseVoxGuardDataResult<T> {
  const [data, setData] = useState<T | undefined>(undefined);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | undefined>(undefined);

  const load = useCallback(() => {
    setLoading(true);
    setError(undefined);
    fetchFn()
      .then(setData)
      .catch((err) => setError(err instanceof Error ? err : new Error(String(err))))
      .finally(() => setLoading(false));
  }, [fetchFn]);

  useEffect(() => {
    load();
  }, [load]);

  return { data, loading, error, reload: load };
}
