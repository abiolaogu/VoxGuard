import { ApolloClient, InMemoryCache, HttpLink, split } from '@apollo/client';
import { GraphQLWsLink } from '@apollo/client/link/subscriptions';
import { getMainDefinition } from '@apollo/client/utilities';
import { createClient } from 'graphql-ws';
import { setContext } from '@apollo/client/link/context';

// Environment variables
const HASURA_ENDPOINT = import.meta.env.VITE_HASURA_ENDPOINT || 'http://localhost:8082/v1/graphql';
const HASURA_WS_ENDPOINT = import.meta.env.VITE_HASURA_WS_ENDPOINT || 'ws://localhost:8082/v1/graphql';
const HASURA_ADMIN_SECRET = import.meta.env.VITE_HASURA_ADMIN_SECRET || 'acm_hasura_secret';

// Get auth token from localStorage
const getAuthToken = (): string | null => {
  try {
    const authStorage = localStorage.getItem('acm-auth');
    if (authStorage) {
      const parsed = JSON.parse(authStorage);
      return parsed?.state?.token || null;
    }
  } catch (e) {
    console.error('Error parsing auth storage:', e);
  }
  return null;
};

// HTTP Link for queries and mutations
const httpLink = new HttpLink({
  uri: HASURA_ENDPOINT,
});

// Auth link to add headers
const authLink = setContext((_, { headers }) => {
  const token = getAuthToken();

  return {
    headers: {
      ...headers,
      ...(token
        ? { Authorization: `Bearer ${token}` }
        : { 'x-hasura-admin-secret': HASURA_ADMIN_SECRET }),
    },
  };
});

// WebSocket Link for subscriptions
const wsLink = new GraphQLWsLink(
  createClient({
    url: HASURA_WS_ENDPOINT,
    connectionParams: () => {
      const token = getAuthToken();
      return {
        headers: token
          ? { Authorization: `Bearer ${token}` }
          : { 'x-hasura-admin-secret': HASURA_ADMIN_SECRET },
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
    const token = getAuthToken();
    return token
      ? { Authorization: `Bearer ${token}` }
      : { 'x-hasura-admin-secret': HASURA_ADMIN_SECRET };
  },
};

export default apolloClient;
