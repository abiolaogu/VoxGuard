import { useCallback, useMemo } from 'react';
import { useList, useCreate, useCustom } from '@refinedev/core';
import type {
    RemittanceTransaction,
    Beneficiary,
    RemittanceCorridor,
    TransactionFilters,
    InitiateTransferInput,
} from '@/types';

/**
 * Hook for remittance operations
 */
export const useRemittance = (filters?: TransactionFilters) => {
    const queryFilters = [];

    if (filters?.status) {
        queryFilters.push({ field: 'status', operator: 'eq' as const, value: filters.status });
    }
    if (filters?.beneficiaryId) {
        queryFilters.push({ field: 'beneficiary_id', operator: 'eq' as const, value: filters.beneficiaryId });
    }
    if (filters?.dateRange) {
        queryFilters.push({
            field: 'initiated_at',
            operator: 'gte' as const,
            value: filters.dateRange.start,
        });
        queryFilters.push({
            field: 'initiated_at',
            operator: 'lte' as const,
            value: filters.dateRange.end,
        });
    }

    // Transactions
    const {
        data: transactionsData,
        isLoading: transactionsLoading,
        refetch: refetchTransactions,
    } = useList<RemittanceTransaction>({
        resource: 'remittance_transactions',
        filters: queryFilters,
        sorters: [{ field: 'initiated_at', order: 'desc' }],
        meta: {
            fields: [
                'id',
                'reference',
                'amount_sent',
                'currency_sent',
                'amount_received',
                'status',
                'initiated_at',
                { beneficiary: ['first_name', 'last_name'] },
            ],
        },
    });

    // Beneficiaries
    const { data: beneficiariesData, isLoading: beneficiariesLoading } = useList<Beneficiary>({
        resource: 'beneficiaries',
        sorters: [{ field: 'is_favorite', order: 'desc' }],
        pagination: { mode: 'off' },
        meta: {
            fields: ['id', 'first_name', 'last_name', 'bank_code', 'account_number', 'is_favorite'],
        },
    });

    // Corridors
    const { data: corridorsData, isLoading: corridorsLoading } = useList<RemittanceCorridor>({
        resource: 'remittance_corridors',
        filters: [{ field: 'is_active', operator: 'eq', value: true }],
        pagination: { mode: 'off' },
        meta: {
            fields: [
                'id',
                'source_currency',
                'destination_currency',
                'exchange_rate',
                'fee_structure',
                'min_amount',
                'max_amount',
            ],
        },
    });

    const { mutate: createTransfer } = useCreate();

    // Get exchange rate
    const useExchangeRate = (sourceCurrency: string, targetCurrency: string) => {
        const { data: rateData, isLoading: rateLoading } = useCustom({
            url: '',
            method: 'get',
            meta: {
                gqlQuery: `
          query GetExchangeRate($source: String!, $target: String!) {
            remittance_corridors(
              where: {
                source_currency: { _eq: $source }
                destination_currency: { _eq: $target }
                is_active: { _eq: true }
              }
              limit: 1
            ) {
              exchange_rate
              fee_structure
              min_amount
              max_amount
            }
          }
        `,
                variables: { source: sourceCurrency, target: targetCurrency },
            },
        });

        return {
            rate: (rateData?.data as any)?.remittance_corridors?.[0]?.exchange_rate,
            fees: (rateData?.data as any)?.remittance_corridors?.[0]?.fee_structure,
            isLoading: rateLoading,
        };
    };

    // Calculate fees
    const calculateFees = useCallback(
        (amount: number, corridor: RemittanceCorridor) => {
            const fees = corridor.feeStructure;
            if (!fees) return 0;

            let fee = (fees as any).flat_fee || 0;
            const percentageFee = amount * ((fees as any).percentage_fee || 0);
            fee += percentageFee;

            if ((fees as any).min_fee && fee < (fees as any).min_fee) {
                fee = (fees as any).min_fee;
            }
            if ((fees as any).max_fee && fee > (fees as any).max_fee) {
                fee = (fees as any).max_fee;
            }

            return fee;
        },
        []
    );

    // Initiate transfer
    const initiateTransfer = useCallback(
        async (input: InitiateTransferInput) => {
            return createTransfer({
                resource: 'remittance_transactions',
                values: {
                    beneficiary_id: input.beneficiaryId,
                    amount_sent: input.amount,
                    currency_sent: input.currency,
                    purpose: input.purpose,
                    narration: input.narration,
                    status: 'PENDING',
                    initiated_at: new Date().toISOString(),
                },
            });
        },
        [createTransfer]
    );

    return {
        transactions: transactionsData?.data || [],
        totalTransactions: transactionsData?.total || 0,
        transactionsLoading,
        refetchTransactions,
        beneficiaries: beneficiariesData?.data || [],
        beneficiariesLoading,
        corridors: corridorsData?.data || [],
        corridorsLoading,
        calculateFees,
        initiateTransfer,
        useExchangeRate,
    };
};

export default useRemittance;
