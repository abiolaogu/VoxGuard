import type { AuthProvider } from '@refinedev/core';

// User interface matching Hasura schema
export interface User {
  id: string;
  email: string;
  name: string;
  role: 'admin' | 'analyst' | 'developer' | 'viewer';
  avatar?: string;
  permissions: string[];
  created_at: string;
  last_login?: string;
}

// Demo users for development (will be replaced by Hasura auth)
const DEMO_USERS: Record<string, { password: string; user: User }> = {
  'admin@acm.com': {
    password: 'demo123',
    user: {
      id: '1',
      email: 'admin@acm.com',
      name: 'Admin User',
      role: 'admin',
      permissions: ['all'],
      created_at: '2024-01-01T00:00:00Z',
    },
  },
  'analyst@acm.com': {
    password: 'demo123',
    user: {
      id: '2',
      email: 'analyst@acm.com',
      name: 'Security Analyst',
      role: 'analyst',
      permissions: ['alerts:read', 'alerts:update', 'analytics:read'],
      created_at: '2024-01-01T00:00:00Z',
    },
  },
  'developer@acm.com': {
    password: 'demo123',
    user: {
      id: '3',
      email: 'developer@acm.com',
      name: 'Developer',
      role: 'developer',
      permissions: ['alerts:read', 'analytics:read', 'settings:read'],
      created_at: '2024-01-01T00:00:00Z',
    },
  },
  'viewer@acm.com': {
    password: 'demo123',
    user: {
      id: '4',
      email: 'viewer@acm.com',
      name: 'Viewer',
      role: 'viewer',
      permissions: ['alerts:read', 'analytics:read'],
      created_at: '2024-01-01T00:00:00Z',
    },
  },
};

// Storage key for auth data
const AUTH_STORAGE_KEY = 'voxguard-auth';

// Generate a mock JWT token (in production, this comes from Hasura/Auth service)
const generateToken = (user: User): string => {
  const header = btoa(JSON.stringify({ alg: 'HS256', typ: 'JWT' }));
  const payload = btoa(
    JSON.stringify({
      sub: user.id,
      email: user.email,
      role: user.role,
      'https://hasura.io/jwt/claims': {
        'x-hasura-allowed-roles': [user.role],
        'x-hasura-default-role': user.role,
        'x-hasura-user-id': user.id,
      },
      iat: Math.floor(Date.now() / 1000),
      exp: Math.floor(Date.now() / 1000) + 86400, // 24 hours
    })
  );
  const signature = 'mock-signature';
  return `${header}.${payload}.${signature}`;
};

// Get stored auth data
const getStoredAuth = (): { user: User; token: string } | null => {
  try {
    const stored = localStorage.getItem(AUTH_STORAGE_KEY);
    if (stored) {
      return JSON.parse(stored).state;
    }
  } catch (e) {
    console.error('Error reading auth storage:', e);
  }
  return null;
};

// Store auth data
const storeAuth = (user: User, token: string): void => {
  localStorage.setItem(
    AUTH_STORAGE_KEY,
    JSON.stringify({
      state: { user, token, isAuthenticated: true },
    })
  );
};

// Clear auth data
const clearAuth = (): void => {
  localStorage.removeItem(AUTH_STORAGE_KEY);
};

// Refine Auth Provider
export const authProvider: AuthProvider = {
  login: async ({ email, password }) => {
    // Check demo users
    const demoUser = DEMO_USERS[email];
    if (demoUser && demoUser.password === password) {
      const token = generateToken(demoUser.user);
      storeAuth(demoUser.user, token);

      return {
        success: true,
        redirectTo: '/dashboard',
      };
    }

    // TODO: Implement real Hasura authentication
    // const response = await fetch('/api/auth/login', {
    //   method: 'POST',
    //   headers: { 'Content-Type': 'application/json' },
    //   body: JSON.stringify({ email, password }),
    // });
    // const data = await response.json();

    return {
      success: false,
      error: {
        name: 'LoginError',
        message: 'Invalid email or password',
      },
    };
  },

  logout: async () => {
    clearAuth();
    return {
      success: true,
      redirectTo: '/login',
    };
  },

  check: async () => {
    const auth = getStoredAuth();
    if (auth?.token) {
      return {
        authenticated: true,
      };
    }

    return {
      authenticated: false,
      redirectTo: '/login',
      error: {
        name: 'Unauthorized',
        message: 'Please login to continue',
      },
    };
  },

  getPermissions: async () => {
    const auth = getStoredAuth();
    if (auth?.user) {
      return auth.user.permissions;
    }
    return [];
  },

  getIdentity: async () => {
    const auth = getStoredAuth();
    if (auth?.user) {
      return {
        id: auth.user.id,
        name: auth.user.name,
        email: auth.user.email,
        avatar: auth.user.avatar || `https://ui-avatars.com/api/?name=${encodeURIComponent(auth.user.name)}&background=1B4F72&color=fff`,
        role: auth.user.role,
      };
    }
    return null;
  },

  onError: async (error) => {
    if (error?.statusCode === 401 || error?.statusCode === 403) {
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
