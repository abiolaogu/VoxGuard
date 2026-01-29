import { useCallback } from 'react';
import { useList, useUpdate, useCustomMutation, useSubscription } from '@refinedev/core';
import type { FraudAlert, AlertFilters, AlertStatus, ResolutionType } from '@/types';

/**
 * Hook for fraud alert operations
 */
export const useFraudAlerts = (filters?: AlertFilters) => {
    const queryFilters = [];

    if (filters?.status) {
        queryFilters.push({ field: 'status', operator: 'eq' as const, value: filters.status });
    }
    if (filters?.severity) {
        queryFilters.push({ field: 'severity', operator: 'eq' as const, value: filters.severity });
    }
    if (filters?.fraudType) {
        queryFilters.push({ field: 'fraud_type', operator: 'eq' as const, value: filters.fraudType });
    }
    if (filters?.dateRange) {
        queryFilters.push({
            field: 'detected_at',
            operator: 'gte' as const,
            value: filters.dateRange.start,
        });
        queryFilters.push({
            field: 'detected_at',
            operator: 'lte' as const,
            value: filters.dateRange.end,
        });
    }

    const { data, isLoading, refetch } = useList<FraudAlert>({
        resource: 'fraud_alerts',
        filters: queryFilters,
        sorters: [{ field: 'detected_at', order: 'desc' }],
        meta: {
            fields: [
                'id',
                'b_number',
                'fraud_type',
                'score',
                'severity',
                'distinct_callers',
                'status',
                'detected_at',
            ],
        },
        liveMode: 'auto',
    });

    const { mutate: update } = useUpdate();
    const { mutate: reportNCC } = useCustomMutation();

    // Subscribe to real-time updates
    useSubscription({
        channel: 'fraud_alerts',
        types: ['created', 'updated'],
        onLiveEvent: () => {
            refetch();
        },
    });

    const acknowledgeAlert = useCallback(
        async (alertId: string) => {
            return update({
                resource: 'fraud_alerts',
                id: alertId,
                values: {
                    status: 'ACKNOWLEDGED' as AlertStatus,
                    acknowledged_at: new Date().toISOString(),
                },
            });
        },
        [update]
    );

    const resolveAlert = useCallback(
        async (alertId: string, resolution: ResolutionType, notes?: string) => {
            return update({
                resource: 'fraud_alerts',
                id: alertId,
                values: {
                    status: 'RESOLVED' as AlertStatus,
                    resolved_at: new Date().toISOString(),
                    resolution,
                    resolution_notes: notes,
                },
            });
        },
        [update]
    );

    const reportToNCC = useCallback(
        async (alertId: string) => {
            return reportNCC({
                url: '',
                method: 'post',
                values: { alertId },
                meta: {
                    gqlMutation: `
            mutation ReportToNCC($alertId: uuid!) {
              reportToNCC(alert_id: $alertId) {
                success
                message
                data
              }
            }
          `,
                },
            });
        },
        [reportNCC]
    );

    return {
        alerts: data?.data || [],
        total: data?.total || 0,
        isLoading,
        refetch,
        acknowledgeAlert,
        resolveAlert,
        reportToNCC,
    };
};

export default useFraudAlerts;
