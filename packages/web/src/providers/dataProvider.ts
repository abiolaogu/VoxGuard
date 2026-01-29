import { GraphQLClient } from 'graphql-request';
import dataProvider from '@refinedev/hasura';

/**
 * Hasura GraphQL client configuration
 */
const createGraphQLClient = () => {
    const endpoint = import.meta.env.VITE_HASURA_ENDPOINT || 'http://localhost:8080/v1/graphql';

    return new GraphQLClient(endpoint, {
        headers: () => {
            const token = localStorage.getItem('access_token');
            const headers: Record<string, string> = {};

            if (token) {
                headers['Authorization'] = `Bearer ${token}`;
            }

            // For development, use admin secret
            if (import.meta.env.DEV && import.meta.env.VITE_HASURA_ADMIN_SECRET) {
                headers['x-hasura-admin-secret'] = import.meta.env.VITE_HASURA_ADMIN_SECRET;
            }

            return headers;
        },
    });
};

export const gqlClient = createGraphQLClient();

/**
 * Hasura Data Provider for Refine
 * Provides CRUD operations for all resources
 */
export const hasuraDataProvider = dataProvider(gqlClient, {
    namingConvention: 'hasura-default',
    idType: 'uuid',
});

/**
 * Resource naming map for Hasura tables
 */
export const resourceMap = {
    // Anti-Masking Context
    'fraud-alerts': 'fraud_alerts',
    'gateways': 'gateways',
    'calls': 'call_verifications',
    'carriers': 'carriers',
    'blacklist': 'blacklist',

    // Remittance Context
    'corridors': 'remittance_corridors',
    'transactions': 'remittance_transactions',
    'beneficiaries': 'beneficiaries',
    'banks': 'nigerian_banks',

    // Marketplace Context
    'listings': 'marketplace_listings',
    'orders': 'marketplace_orders',
    'providers': 'provider_profiles',
    'categories': 'service_categories',

    // Identity Context
    'users': 'users',
    'notifications': 'notifications',
};

export default hasuraDataProvider;
