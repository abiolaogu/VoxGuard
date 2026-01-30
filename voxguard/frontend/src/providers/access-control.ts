import type { AccessControlProvider } from '@refinedev/core';

// Permission definitions by role
const ROLE_PERMISSIONS: Record<string, string[]> = {
  admin: ['all'],
  analyst: [
    'dashboard:read',
    'alerts:read',
    'alerts:update',
    'analytics:read',
    'users:read',
    'settings:read',
  ],
  developer: [
    'dashboard:read',
    'alerts:read',
    'analytics:read',
    'settings:read',
  ],
  viewer: [
    'dashboard:read',
    'alerts:read',
    'analytics:read',
  ],
};

// Resource to permission mapping
const RESOURCE_PERMISSIONS: Record<string, Record<string, string>> = {
  dashboard: {
    list: 'dashboard:read',
  },
  acm_alerts: {
    list: 'alerts:read',
    show: 'alerts:read',
    create: 'alerts:create',
    edit: 'alerts:update',
    delete: 'alerts:delete',
  },
  acm_users: {
    list: 'users:read',
    show: 'users:read',
    create: 'users:create',
    edit: 'users:update',
    delete: 'users:delete',
  },
  analytics: {
    list: 'analytics:read',
    show: 'analytics:read',
  },
  acm_settings: {
    list: 'settings:read',
    edit: 'settings:update',
  },
};

// Get stored user role from localStorage
const getUserRole = (): string | null => {
  try {
    const authStorage = localStorage.getItem('acm-auth');
    if (authStorage) {
      const parsed = JSON.parse(authStorage);
      return parsed?.state?.user?.role || null;
    }
  } catch (e) {
    console.error('Error reading auth storage:', e);
  }
  return null;
};

// Check if user has specific permission
const hasPermission = (userPermissions: string[], requiredPermission: string): boolean => {
  // Admin with 'all' permission has access to everything
  if (userPermissions.includes('all')) {
    return true;
  }

  // Check for exact permission match
  if (userPermissions.includes(requiredPermission)) {
    return true;
  }

  // Check for wildcard permissions (e.g., 'alerts:*')
  const [resource] = requiredPermission.split(':');
  if (userPermissions.includes(`${resource}:*`)) {
    return true;
  }

  return false;
};

// Refine Access Control Provider
export const accessControlProvider: AccessControlProvider = {
  can: async ({ resource, action }) => {
    const role = getUserRole();

    if (!role) {
      return {
        can: false,
        reason: 'User not authenticated',
      };
    }

    const userPermissions = ROLE_PERMISSIONS[role] || [];

    // Admin has all permissions
    if (userPermissions.includes('all')) {
      return { can: true };
    }

    // Get required permission for this resource/action
    const resourcePermissions = RESOURCE_PERMISSIONS[resource || ''];
    if (!resourcePermissions) {
      // Resource not in permission map - allow by default for known resources
      return { can: true };
    }

    const requiredPermission = resourcePermissions[action || 'list'];
    if (!requiredPermission) {
      // Action not in permission map - deny by default
      return {
        can: false,
        reason: `Unknown action: ${action}`,
      };
    }

    // Check if user has the required permission
    if (hasPermission(userPermissions, requiredPermission)) {
      return { can: true };
    }

    return {
      can: false,
      reason: `Insufficient permissions. Required: ${requiredPermission}`,
    };
  },

  options: {
    buttons: {
      enableAccessControl: true,
      hideIfUnauthorized: true,
    },
  },
};

// Utility function to check permissions in components
export const checkPermission = (permission: string): boolean => {
  const role = getUserRole();
  if (!role) return false;

  const userPermissions = ROLE_PERMISSIONS[role] || [];
  return hasPermission(userPermissions, permission);
};

// Utility function to get all permissions for current user
export const getCurrentUserPermissions = (): string[] => {
  const role = getUserRole();
  if (!role) return [];

  return ROLE_PERMISSIONS[role] || [];
};

// Utility function to check if user is admin
export const isAdmin = (): boolean => {
  const role = getUserRole();
  return role === 'admin';
};

export default accessControlProvider;
