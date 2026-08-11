import type { AuthProvider } from '@refinedev/core';

// User interface matching Hasura schema
export interface User {
  id: string;
  email: string;
  name?: string;
  username: string;
  roles: string[];
  is_active: boolean;
  created_at: string;
  last_login?: string;
}



// Storage key for auth data
const AUTH_STORAGE_KEY = 'voxguard-auth';



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
    try {
      // Use the management API endpoint (proxied via Nginx)
      const response = await fetch('/api/v1/management/auth/login', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          username: email, // Backend expects 'username', mapping email to it
          password
        }),
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        return {
          success: false,
          error: {
            name: 'LoginError',
            message: errorData.error || 'Invalid email or password',
          },
        };
      }

      const data = await response.json();

      // Store real token and user data
      if (data.access_token && data.user) {
        storeAuth(data.user, data.access_token);
        return {
          success: true,
          redirectTo: '/voxguard/dashboard', // Ensure correct redirect path
        };
      }

      return {
        success: false,
        error: {
          name: 'LoginError',
          message: 'Invalid response from server',
        },
      };
    } catch (error) {
      return {
        success: false,
        error: {
          name: 'NetworkError',
          message: 'Failed to connect to authentication server',
        },
      };
    }
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
      return auth.user.roles || [];
    }
    return [];
  },

  getIdentity: async () => {
    const auth = getStoredAuth();
    if (auth?.user) {
      const role = auth.user.roles && auth.user.roles.length > 0 ? auth.user.roles[0] : 'viewer';
      return {
        id: auth.user.id,
        name: auth.user.name || auth.user.username,
        email: auth.user.email,
        avatar: `https://ui-avatars.com/api/?name=${encodeURIComponent(auth.user.name || auth.user.username)}&background=1B4F72&color=fff`,
        role: role,
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
