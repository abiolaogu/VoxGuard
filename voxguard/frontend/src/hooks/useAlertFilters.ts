import { useState, useCallback, useMemo } from 'react';
import type { Dayjs } from 'dayjs';

export interface AlertFilters {
  severity?: string[];
  status?: string[];
  dateRange?: [Dayjs | null, Dayjs | null];
  search?: string;
  carrier?: string;
  assignedTo?: string;
}

export interface UseAlertFiltersReturn {
  filters: AlertFilters;
  setFilters: React.Dispatch<React.SetStateAction<AlertFilters>>;
  setSeverity: (severity: string[]) => void;
  setStatus: (status: string[]) => void;
  setDateRange: (range: [Dayjs | null, Dayjs | null]) => void;
  setSearch: (search: string) => void;
  setCarrier: (carrier: string) => void;
  setAssignedTo: (userId: string) => void;
  clearFilters: () => void;
  hasActiveFilters: boolean;
  activeFilterCount: number;
  graphqlFilters: Record<string, unknown>;
}

const defaultFilters: AlertFilters = {
  severity: [],
  status: [],
  dateRange: undefined,
  search: '',
  carrier: '',
  assignedTo: '',
};

export function useAlertFilters(initialFilters?: Partial<AlertFilters>): UseAlertFiltersReturn {
  const [filters, setFilters] = useState<AlertFilters>({
    ...defaultFilters,
    ...initialFilters,
  });

  const setSeverity = useCallback((severity: string[]) => {
    setFilters((prev) => ({ ...prev, severity }));
  }, []);

  const setStatus = useCallback((status: string[]) => {
    setFilters((prev) => ({ ...prev, status }));
  }, []);

  const setDateRange = useCallback((dateRange: [Dayjs | null, Dayjs | null]) => {
    setFilters((prev) => ({ ...prev, dateRange }));
  }, []);

  const setSearch = useCallback((search: string) => {
    setFilters((prev) => ({ ...prev, search }));
  }, []);

  const setCarrier = useCallback((carrier: string) => {
    setFilters((prev) => ({ ...prev, carrier }));
  }, []);

  const setAssignedTo = useCallback((assignedTo: string) => {
    setFilters((prev) => ({ ...prev, assignedTo }));
  }, []);

  const clearFilters = useCallback(() => {
    setFilters(defaultFilters);
  }, []);

  const hasActiveFilters = useMemo(() => {
    return (
      (filters.severity?.length || 0) > 0 ||
      (filters.status?.length || 0) > 0 ||
      !!filters.dateRange?.[0] ||
      !!filters.search ||
      !!filters.carrier ||
      !!filters.assignedTo
    );
  }, [filters]);

  const activeFilterCount = useMemo(() => {
    let count = 0;
    if (filters.severity?.length) count++;
    if (filters.status?.length) count++;
    if (filters.dateRange?.[0]) count++;
    if (filters.search) count++;
    if (filters.carrier) count++;
    if (filters.assignedTo) count++;
    return count;
  }, [filters]);

  // Convert filters to GraphQL where clause
  const graphqlFilters = useMemo(() => {
    const conditions: Record<string, unknown>[] = [];

    if (filters.severity?.length) {
      conditions.push({ severity: { _in: filters.severity } });
    }

    if (filters.status?.length) {
      conditions.push({ status: { _in: filters.status } });
    }

    if (filters.dateRange?.[0] && filters.dateRange?.[1]) {
      conditions.push({
        created_at: {
          _gte: filters.dateRange[0].toISOString(),
          _lte: filters.dateRange[1].toISOString(),
        },
      });
    }

    if (filters.search) {
      conditions.push({
        _or: [
          { b_number: { _ilike: `%${filters.search}%` } },
          { a_number: { _ilike: `%${filters.search}%` } },
          { carrier_name: { _ilike: `%${filters.search}%` } },
        ],
      });
    }

    if (filters.carrier) {
      conditions.push({ carrier_id: { _eq: filters.carrier } });
    }

    if (filters.assignedTo) {
      conditions.push({ assigned_to: { _eq: filters.assignedTo } });
    }

    return conditions.length > 0 ? { _and: conditions } : {};
  }, [filters]);

  return {
    filters,
    setFilters,
    setSeverity,
    setStatus,
    setDateRange,
    setSearch,
    setCarrier,
    setAssignedTo,
    clearFilters,
    hasActiveFilters,
    activeFilterCount,
    graphqlFilters,
  };
}

export default useAlertFilters;
