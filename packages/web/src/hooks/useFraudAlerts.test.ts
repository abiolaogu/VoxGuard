import { describe, it, expect, vi, beforeEach } from 'vitest';
import { renderHook, waitFor } from '@testing-library/react';
import { useFraudAlerts } from '../useFraudAlerts';

// Mock Refine hooks
vi.mock('@refinedev/core', () => ({
    useList: vi.fn(() => ({
        data: {
            data: [
                {
                    id: '1',
                    b_number: '+2348012345678',
                    fraud_type: 'CLI_MASKING',
                    score: 0.95,
                    severity: 'CRITICAL',
                    distinct_callers: 250,
                    status: 'PENDING',
                    detected_at: new Date().toISOString(),
                },
                {
                    id: '2',
                    b_number: '+2348087654321',
                    fraud_type: 'SIMBOX',
                    score: 0.78,
                    severity: 'HIGH',
                    distinct_callers: 120,
                    status: 'ACKNOWLEDGED',
                    detected_at: new Date().toISOString(),
                },
            ],
            total: 2,
        },
        isLoading: false,
        refetch: vi.fn(),
    })),
    useUpdate: vi.fn(() => ({
        mutate: vi.fn(),
    })),
    useCustomMutation: vi.fn(() => ({
        mutate: vi.fn(),
    })),
    useSubscription: vi.fn(),
}));

describe('useFraudAlerts', () => {
    beforeEach(() => {
        vi.clearAllMocks();
    });

    it('should return alerts data', () => {
        const { result } = renderHook(() => useFraudAlerts());

        expect(result.current.alerts).toHaveLength(2);
        expect(result.current.total).toBe(2);
        expect(result.current.isLoading).toBe(false);
    });

    it('should filter by severity', () => {
        const { result } = renderHook(() =>
            useFraudAlerts({ severity: 'CRITICAL' })
        );

        expect(result.current.alerts).toBeDefined();
    });

    it('should provide acknowledge function', () => {
        const { result } = renderHook(() => useFraudAlerts());

        expect(typeof result.current.acknowledgeAlert).toBe('function');
    });

    it('should provide resolve function', () => {
        const { result } = renderHook(() => useFraudAlerts());

        expect(typeof result.current.resolveAlert).toBe('function');
    });

    it('should provide report to NCC function', () => {
        const { result } = renderHook(() => useFraudAlerts());

        expect(typeof result.current.reportToNCC).toBe('function');
    });
});
