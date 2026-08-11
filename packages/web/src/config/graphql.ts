import { ApolloClient, InMemoryCache, HttpLink, split } from '@apollo/client';
import { GraphQLWsLink } from '@apollo/client/link/subscriptions';
import { getMainDefinition } from '@apollo/client/utilities';
import { createClient } from 'graphql-ws';
import { setContext } from '@apollo/client/link/context';

// Environment variables
// Environment variables
const HASURA_ENDPOINT = import.meta.env.VITE_HASURA_ENDPOINT || '/v1/graphql';
// HARDCODED for debugging to ensure it is not missed
const HASURA_ADMIN_SECRET = 'acm_hasura_secret';

// Helper to construct WebSocket URL
const getWsUrl = () => {
  const envUrl = import.meta.env.VITE_HASURA_WS_ENDPOINT;
  if (envUrl && (envUrl.startsWith('ws://') || envUrl.startsWith('wss://'))) {
    return envUrl;
  }
  // Construct from window location if relative or missing
  if (typeof window !== 'undefined') {
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    const host = window.location.host;
    const path = envUrl || '/v1/graphql';
    return `${protocol}//${host}${path}`;
  }
  return 'ws://localhost:8082/v1/graphql'; // Fallback for SSR/build
};

const HASURA_WS_ENDPOINT = getWsUrl();

// HTTP Link for queries and mutations
const httpLink = new HttpLink({
  uri: HASURA_ENDPOINT,
});

// Auth link to add headers
const authLink = setContext((_, { headers }) => {
  // FORCE ADMIN ACCESS: Always send admin secret, ignore token for now to verify data access
  return {
    headers: {
      ...headers,
      'x-hasura-admin-secret': HASURA_ADMIN_SECRET,
    },
  };
});

// WebSocket Link for subscriptions
const wsLink = new GraphQLWsLink(
  createClient({
    url: HASURA_WS_ENDPOINT,
    connectionParams: () => {
      // FORCE ADMIN ACCESS via WebSocket
      return {
        headers: {
          'x-hasura-admin-secret': HASURA_ADMIN_SECRET,
        },
      };
    },
    retryAttempts: 5,
    shouldRetry: () => true,
    on: {
      connected: () => console.log('[WS] Connected to Hasura'),
      closed: () => console.log('[WS] Disconnected from Hasura'),
      error: (error) => console.error('[WS] Error:', error),
    },
  })
);

// Split link - use WebSocket for subscriptions, HTTP for queries/mutations
const splitLink = split(
  ({ query }) => {
    const definition = getMainDefinition(query);
    return (
      definition.kind === 'OperationDefinition' &&
      definition.operation === 'subscription'
    );
  },
  wsLink,
  authLink.concat(httpLink)
);

// Apollo Client instance
export const apolloClient = new ApolloClient({
  link: splitLink,
  cache: new InMemoryCache({
    typePolicies: {
      Query: {
        fields: {
          acm_alerts: {
            merge(_existing, incoming) {
              return incoming;
            },
          },
          acm_users: {
            merge(_existing, incoming) {
              return incoming;
            },
          },
        },
      },
    },
  }),
  defaultOptions: {
    watchQuery: {
      fetchPolicy: 'cache-and-network',
    },
    query: {
      fetchPolicy: 'network-only',
    },
  },
});

// Export configuration for Refine Hasura data provider
export const hasuraConfig = {
  url: HASURA_ENDPOINT,
  headers: () => {
    // FORCE ADMIN ACCESS via Data Provider
    return {
      'x-hasura-admin-secret': HASURA_ADMIN_SECRET,
    };
  },
};

export default apolloClient;
