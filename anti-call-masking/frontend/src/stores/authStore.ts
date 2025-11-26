import { create } from 'zustand';
import { persist } from 'zustand/middleware';

export type UserRole = 'admin' | 'analyst' | 'developer' | 'viewer';

export interface User {
  id: string;
  name: string;
  email: string;
  role: UserRole;
  permissions: string[];
}

interface AuthState {
  user: User | null;
  token: string | null;
  isAuthenticated: boolean;
  login: (email: string, password: string) => Promise<boolean>;
  logout: () => void;
  checkAuth: () => boolean;
}

// Demo users for different roles
const demoUsers: Record<string, User> = {
  'admin@acm.com': {
    id: '1',
    name: 'System Admin',
    email: 'admin@acm.com',
    role: 'admin',
    permissions: ['all'],
  },
  'analyst@acm.com': {
    id: '2',
    name: 'SOC Analyst',
    email: 'analyst@acm.com',
    role: 'analyst',
    permissions: ['view_alerts', 'manage_alerts', 'view_analytics', 'generate_reports'],
  },
  'developer@acm.com': {
    id: '3',
    name: 'API Developer',
    email: 'developer@acm.com',
    role: 'developer',
    permissions: ['view_api_docs', 'manage_api_keys', 'view_analytics'],
  },
  'viewer@acm.com': {
    id: '4',
    name: 'Executive Viewer',
    email: 'viewer@acm.com',
    role: 'viewer',
    permissions: ['view_dashboard', 'view_analytics'],
  },
};

export const useAuthStore = create<AuthState>()(
  persist(
    (set, get) => ({
      user: null,
      token: null,
      isAuthenticated: false,

      login: async (email: string, password: string) => {
        // Demo authentication - in production, call API
        const user = demoUsers[email.toLowerCase()];
        if (user && password === 'demo123') {
          const token = btoa(`${email}:${Date.now()}`);
          set({ user, token, isAuthenticated: true });
          return true;
        }
        return false;
      },

      logout: () => {
        set({ user: null, token: null, isAuthenticated: false });
      },

      checkAuth: () => {
        const state = get();
        return state.isAuthenticated && state.token !== null;
      },
    }),
    {
      name: 'acm-auth-storage',
    }
  )
);

// Permission check helper
export function hasPermission(user: User | null, permission: string): boolean {
  if (!user) return false;
  if (user.permissions.includes('all')) return true;
  return user.permissions.includes(permission);
}

// Role check helper
export function hasRole(user: User | null, roles: UserRole | UserRole[]): boolean {
  if (!user) return false;
  const roleArray = Array.isArray(roles) ? roles : [roles];
  return roleArray.includes(user.role);
}
