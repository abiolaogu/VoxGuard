import type { AuthProvider } from '@refinedev/core';
import { gqlClient } from './dataProvider';
import { gql } from 'graphql-request';
import type { User, AuthPayload } from '@/types';

const LOGIN_MUTATION = gql`
  mutation Login($email: String!, $password: String!) {
    login(email: $email, password: $password) {
      accessToken
      refreshToken
      expiresAt
      user {
        id
        email
        firstName
        lastName
        role
        status
        avatarUrl
      }
    }
  }
`;

const REFRESH_MUTATION = gql`
  mutation RefreshToken {
    refreshToken {
      accessToken
      refreshToken
      expiresAt
      user {
        id
        email
        firstName
        lastName
        role
        status
        avatarUrl
      }
    }
  }
`;

const GET_ME_QUERY = gql`
  query GetMe {
    users(limit: 1) {
      id
      email
      firstName: first_name
      lastName: last_name
      role
      status
      kycLevel: kyc_level
      avatarUrl: avatar_url
    }
  }
`;

/**
 * Auth Provider for Refine
 * Handles login, logout, token refresh, and user identity
 */
export const authProvider: AuthProvider = {
    login: async ({ email, password }) => {
        try {
            const response = await gqlClient.request<{ login: AuthPayload }>(LOGIN_MUTATION, {
                email,
                password,
            });

            const { accessToken, refreshToken, user } = response.login;

            localStorage.setItem('access_token', accessToken);
            localStorage.setItem('refresh_token', refreshToken);
            localStorage.setItem('user', JSON.stringify(user));

            return {
                success: true,
                redirectTo: '/dashboard',
            };
        } catch (error: unknown) {
            const message = error instanceof Error ? error.message : 'Login failed';
            return {
                success: false,
                error: {
                    name: 'LoginError',
                    message,
                },
            };
        }
    },

    logout: async () => {
        localStorage.removeItem('access_token');
        localStorage.removeItem('refresh_token');
        localStorage.removeItem('user');

        return {
            success: true,
            redirectTo: '/login',
        };
    },

    check: async () => {
        const token = localStorage.getItem('access_token');

        if (!token) {
            return {
                authenticated: false,
                redirectTo: '/login',
            };
        }

        // Check if token is expired
        try {
            const payload = JSON.parse(atob(token.split('.')[1]));
            const expiry = payload.exp * 1000;

            if (Date.now() >= expiry) {
                // Try to refresh
                try {
                    const response = await gqlClient.request<{ refreshToken: AuthPayload }>(REFRESH_MUTATION);
                    const { accessToken, refreshToken } = response.refreshToken;

                    localStorage.setItem('access_token', accessToken);
                    localStorage.setItem('refresh_token', refreshToken);

                    return { authenticated: true };
                } catch {
                    return {
                        authenticated: false,
                        redirectTo: '/login',
                    };
                }
            }
        } catch {
            // Token parsing failed
            return {
                authenticated: false,
                redirectTo: '/login',
            };
        }

        return { authenticated: true };
    },

    getPermissions: async () => {
        const userStr = localStorage.getItem('user');
        if (!userStr) return null;

        const user: User = JSON.parse(userStr);
        return user.role;
    },

    getIdentity: async () => {
        const userStr = localStorage.getItem('user');
        if (!userStr) return null;

        const user: User = JSON.parse(userStr);
        return {
            id: user.id,
            name: `${user.firstName} ${user.lastName}`,
            email: user.email,
            avatar: user.avatarUrl,
            role: user.role,
        };
    },

    onError: async (error) => {
        if (error.statusCode === 401) {
            return {
                logout: true,
                redirectTo: '/login',
                error,
            };
        }
        return { error };
    },
};

export default authProvider;
