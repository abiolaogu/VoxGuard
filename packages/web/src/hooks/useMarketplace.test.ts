import { describe, it, expect, vi, beforeEach } from 'vitest';
import { renderHook } from '@testing-library/react';
import { useMarketplace } from '../useMarketplace';

// Mock Refine hooks
vi.mock('@refinedev/core', () => ({
    useList: vi.fn((config: any) => {
        if (config.resource === 'marketplace_listings') {
            return {
                data: {
                    data: [
                        {
                            id: '1',
                            title: 'Professional Plumbing Services',
                            slug: 'professional-plumbing',
                            pricing_type: 'NEGOTIABLE',
                            price_ngn: null,
                            images: ['https://example.com/image1.jpg'],
                            status: 'ACTIVE',
                            is_featured: true,
                            provider: { business_name: 'ABC Services', average_rating: 4.5 },
                            category: { name: 'Home Services' },
                            state: { name: 'Lagos' },
                        },
                        {
                            id: '2',
                            title: 'Legal Consultation',
                            slug: 'legal-consultation',
                            pricing_type: 'HOURLY',
                            price_ngn: 50000,
                            images: [],
                            status: 'ACTIVE',
                            is_featured: false,
                            provider: { business_name: 'Legal Pro', average_rating: 4.8 },
                            category: { name: 'Legal Services' },
                            state: { name: 'Abuja' },
                        },
                    ],
                    total: 2,
                },
                isLoading: false,
                refetch: vi.fn(),
            };
        }
        if (config.resource === 'marketplace_orders') {
            return {
                data: {
                    data: [
                        {
                            id: '1',
                            reference: 'ORD-2024-001',
                            status: 'IN_PROGRESS',
                            agreed_amount: 75000,
                            listing: { title: 'Professional Plumbing' },
                            provider: { business_name: 'ABC Services' },
                        },
                    ],
                },
                isLoading: false,
                refetch: vi.fn(),
            };
        }
        if (config.resource === 'service_categories') {
            return {
                data: {
                    data: [
                        { id: '1', code: 'HOME', name: 'Home Services' },
                        { id: '2', code: 'LEGAL', name: 'Legal Services' },
                    ],
                },
                isLoading: false,
            };
        }
        if (config.resource === 'nigerian_states') {
            return {
                data: {
                    data: [
                        { id: '1', code: 'LA', name: 'Lagos' },
                        { id: '2', code: 'AB', name: 'Abuja FCT' },
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
}));

describe('useMarketplace', () => {
    beforeEach(() => {
        vi.clearAllMocks();
    });

    it('should return listings data', () => {
        const { result } = renderHook(() => useMarketplace());

        expect(result.current.listings).toHaveLength(2);
        expect(result.current.totalListings).toBe(2);
    });

    it('should filter featured listings', () => {
        const { result } = renderHook(() => useMarketplace());

        expect(result.current.featuredListings).toHaveLength(1);
        expect(result.current.featuredListings[0].title).toBe('Professional Plumbing Services');
    });

    it('should return orders data', () => {
        const { result } = renderHook(() => useMarketplace());

        expect(result.current.orders).toHaveLength(1);
        expect(result.current.orders[0].reference).toBe('ORD-2024-001');
    });

    it('should return categories', () => {
        const { result } = renderHook(() => useMarketplace());

        expect(result.current.categories).toHaveLength(2);
    });

    it('should return Nigerian states', () => {
        const { result } = renderHook(() => useMarketplace());

        expect(result.current.states).toHaveLength(2);
        expect(result.current.states[0].name).toBe('Lagos');
    });

    it('should provide create inquiry function', () => {
        const { result } = renderHook(() => useMarketplace());

        expect(typeof result.current.createInquiry).toBe('function');
    });
});
