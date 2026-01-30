import { GraphQLClient } from 'graphql-request';
import dataProvider from '@refinedev/hasura';

// Environment variables
const HASURA_ENDPOINT = import.meta.env.VITE_HASURA_ENDPOINT || 'http://localhost:8082/v1/graphql';
const HASURA_ADMIN_SECRET = import.meta.env.VITE_HASURA_ADMIN_SECRET || 'acm_hasura_secret';

// Get auth token from localStorage
const getAuthToken = (): string | null => {
  try {
    const authStorage = localStorage.getItem('voxguard-auth');
    if (authStorage) {
      const parsed = JSON.parse(authStorage);
      return parsed?.state?.token || null;
    }
  } catch (e) {
    console.error('Error parsing auth storage:', e);
  }
  return null;
};

// Get headers for GraphQL client
const getHeaders = (): Record<string, string> => {
  const token = getAuthToken();
  if (token) {
    return { Authorization: `Bearer ${token}` };
  }
  return { 'x-hasura-admin-secret': HASURA_ADMIN_SECRET };
};

// Create GraphQL client with dynamic headers
const client = new GraphQLClient(HASURA_ENDPOINT, {
  headers: getHeaders,
});

// Create Hasura data provider
// Using 'as any' to work around version mismatch between graphql-request versions
export const hasuraDataProvider = dataProvider(client as any, {
  idType: 'uuid',
  namingConvention: 'hasura-default',
});

// Export as default data provider for Refine
export const acmDataProvider = hasuraDataProvider;

export default acmDataProvider;
