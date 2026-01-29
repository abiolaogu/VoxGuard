import { useCallback } from 'react';
import { useList, useCreate } from '@refinedev/core';
import type { MarketplaceListing, MarketplaceOrder, ListingFilters, OrderStatus } from '@/types';

/**
 * Hook for marketplace operations
 */
export const useMarketplace = (filters?: ListingFilters) => {
    const queryFilters = [];

    if (filters?.categoryId) {
        queryFilters.push({ field: 'category_id', operator: 'eq' as const, value: filters.categoryId });
    }
    if (filters?.stateId) {
        queryFilters.push({ field: 'state_id', operator: 'eq' as const, value: filters.stateId });
    }
    if (filters?.status) {
        queryFilters.push({ field: 'status', operator: 'eq' as const, value: filters.status });
    }
    if (filters?.pricingType) {
        queryFilters.push({ field: 'pricing_type', operator: 'eq' as const, value: filters.pricingType });
    }
    if (filters?.minPrice) {
        queryFilters.push({ field: 'price_ngn', operator: 'gte' as const, value: filters.minPrice });
    }
    if (filters?.maxPrice) {
        queryFilters.push({ field: 'price_ngn', operator: 'lte' as const, value: filters.maxPrice });
    }

    // Listings
    const {
        data: listingsData,
        isLoading: listingsLoading,
        refetch: refetchListings,
    } = useList<MarketplaceListing>({
        resource: 'marketplace_listings',
        filters: [
            { field: 'status', operator: 'eq', value: 'ACTIVE' },
            ...queryFilters,
        ],
        sorters: [
            { field: 'is_featured', order: 'desc' },
            { field: 'created_at', order: 'desc' },
        ],
        meta: {
            fields: [
                'id',
                'title',
                'slug',
                'pricing_type',
                'price_ngn',
                'images',
                'status',
                'is_featured',
                { provider: ['business_name', 'average_rating'] },
                { category: ['name'] },
                { state: ['name'] },
            ],
        },
    });

    // User's orders
    const {
        data: ordersData,
        isLoading: ordersLoading,
        refetch: refetchOrders,
    } = useList<MarketplaceOrder>({
        resource: 'marketplace_orders',
        sorters: [{ field: 'created_at', order: 'desc' }],
        meta: {
            fields: [
                'id',
                'reference',
                'status',
                'agreed_amount',
                'created_at',
                { listing: ['title'] },
                { provider: ['business_name'] },
            ],
        },
    });

    // Categories
    const { data: categoriesData, isLoading: categoriesLoading } = useList({
        resource: 'service_categories',
        filters: [{ field: 'is_active', operator: 'eq', value: true }],
        pagination: { mode: 'off' },
        sorters: [{ field: 'display_order', order: 'asc' }],
        meta: {
            fields: ['id', 'code', 'name', 'icon', 'parent_id'],
        },
    });

    // States
    const { data: statesData, isLoading: statesLoading } = useList({
        resource: 'nigerian_states',
        pagination: { mode: 'off' },
        sorters: [{ field: 'name', order: 'asc' }],
        meta: {
            fields: ['id', 'code', 'name'],
        },
    });

    const { mutate: createOrder } = useCreate();

    // Create inquiry
    const createInquiry = useCallback(
        async (listingId: string, providerId: string, requirements: string) => {
            return createOrder({
                resource: 'marketplace_orders',
                values: {
                    listing_id: listingId,
                    provider_id: providerId,
                    requirements,
                    status: 'INQUIRY' as OrderStatus,
                    created_at: new Date().toISOString(),
                },
            });
        },
        [createOrder]
    );

    // Featured listings
    const featuredListings = (listingsData?.data || []).filter(
        (listing: any) => listing.is_featured
    );

    return {
        listings: listingsData?.data || [],
        featuredListings,
        totalListings: listingsData?.total || 0,
        listingsLoading,
        refetchListings,
        orders: ordersData?.data || [],
        ordersLoading,
        refetchOrders,
        categories: categoriesData?.data || [],
        categoriesLoading,
        states: statesData?.data || [],
        statesLoading,
        createInquiry,
    };
};

export default useMarketplace;
