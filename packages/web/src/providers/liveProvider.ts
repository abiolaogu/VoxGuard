import { createClient, Client } from 'graphql-ws';
import { liveProvider as hasuraLiveProvider } from '@refinedev/hasura';

/**
 * WebSocket client for GraphQL subscriptions
 */
const createWsClient = (): Client => {
    const wsEndpoint = import.meta.env.VITE_HASURA_WS_ENDPOINT || 'ws://localhost:8080/v1/graphql';

    return createClient({
        url: wsEndpoint,
        connectionParams: () => {
            const token = localStorage.getItem('access_token');
            const params: Record<string, string> = {};

            if (token) {
                params['Authorization'] = `Bearer ${token}`;
            }

            // For development
            if (import.meta.env.DEV && import.meta.env.VITE_HASURA_ADMIN_SECRET) {
                params['x-hasura-admin-secret'] = import.meta.env.VITE_HASURA_ADMIN_SECRET;
            }

            return { headers: params };
        },
        retryAttempts: 5,
        shouldRetry: () => true,
        on: {
            connected: () => console.log('[WS] Connected to GraphQL subscriptions'),
            error: (error) => console.error('[WS] Subscription error:', error),
            closed: () => console.log('[WS] WebSocket closed'),
        },
    });
};

export const wsClient = createWsClient();

/**
 * Live Provider for real-time updates
 * Enables GraphQL subscriptions for Refine resources
 */
export const liveProvider = hasuraLiveProvider(wsClient, {
    namingConvention: 'hasura-default',
});

export default liveProvider;
