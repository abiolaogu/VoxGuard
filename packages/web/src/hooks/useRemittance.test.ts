import { describe, it, expect, vi, beforeEach } from 'vitest';
import { renderHook } from '@testing-library/react';
import { useRemittance } from '../useRemittance';

// Mock Refine hooks
vi.mock('@refinedev/core', () => ({
    useList: vi.fn((config: any) => {
        if (config.resource === 'remittance_transactions') {
            return {
                data: {
                    data: [
                        {
                            id: '1',
                            reference: 'TXN-2024-001',
                            amount_sent: 500,
                            currency_sent: 'GBP',
                            amount_received: 850000,
                            status: 'COMPLETED',
                            initiated_at: new Date().toISOString(),
                        },
                    ],
                    total: 1,
                },
                isLoading: false,
                refetch: vi.fn(),
            };
        }
        if (config.resource === 'beneficiaries') {
            return {
                data: {
                    data: [
                        {
                            id: '1',
                            first_name: 'John',
                            last_name: 'Doe',
                            bank_code: '058',
                            account_number: '1234567890',
                            is_favorite: true,
                        },
                    ],
                },
                isLoading: false,
            };
        }
        if (config.resource === 'remittance_corridors') {
            return {
                data: {
                    data: [
                        {
                            id: '1',
                            source_currency: 'GBP',
                            destination_currency: 'NGN',
                            exchange_rate: 1700,
                            fee_structure: { flat_fee: 3, percentage_fee: 0.01, min_fee: 3, max_fee: 15 },
                            min_amount: 50,
                            max_amount: 10000,
                        },
                    ],
                },
                isLoading: false,
            };
        }
        return { data: { data: [] }, isLoading: false };
    }),
    useCreate: vi.fn(() => ({
        mutate: vi.fn(),
    })),
    useCustom: vi.fn(() => ({
        data: null,
        isLoading: false,
    })),
}));

describe('useRemittance', () => {
    beforeEach(() => {
        vi.clearAllMocks();
    });

    it('should return transactions data', () => {
        const { result } = renderHook(() => useRemittance());

        expect(result.current.transactions).toHaveLength(1);
        expect(result.current.transactions[0].reference).toBe('TXN-2024-001');
    });

    it('should return beneficiaries data', () => {
        const { result } = renderHook(() => useRemittance());

        expect(result.current.beneficiaries).toHaveLength(1);
        expect(result.current.beneficiaries[0].first_name).toBe('John');
    });

    it('should return corridors data', () => {
        const { result } = renderHook(() => useRemittance());

        expect(result.current.corridors).toHaveLength(1);
        expect(result.current.corridors[0].exchange_rate).toBe(1700);
    });

    it('should calculate fees correctly', () => {
        const { result } = renderHook(() => useRemittance());

        const corridor = result.current.corridors[0];
        const fee = result.current.calculateFees(500, corridor);

        // flat_fee (3) + percentage_fee (500 * 0.01 = 5) = 8
        expect(fee).toBe(8);
    });

    it('should apply min fee when calculated fee is lower', () => {
        const { result } = renderHook(() => useRemittance());

        const corridor = result.current.corridors[0];
        const fee = result.current.calculateFees(50, corridor); // 3 + 0.5 = 3.5, but min is 3

        expect(fee).toBeGreaterThanOrEqual(3);
    });

    it('should apply max fee when calculated fee is higher', () => {
        const { result } = renderHook(() => useRemittance());

        const corridor = result.current.corridors[0];
        const fee = result.current.calculateFees(5000, corridor); // 3 + 50 = 53, capped at 15

        expect(fee).toBeLessThanOrEqual(15);
    });

    it('should provide initiate transfer function', () => {
        const { result } = renderHook(() => useRemittance());

        expect(typeof result.current.initiateTransfer).toBe('function');
    });
});
