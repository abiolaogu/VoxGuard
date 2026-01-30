export { authProvider } from './auth-provider';
export type { User } from './auth-provider';

export { acmDataProvider, hasuraDataProvider } from './data-provider';

export { liveProvider } from './live-provider';

export {
  accessControlProvider,
  checkPermission,
  getCurrentUserPermissions,
  isAdmin,
} from './access-control';

// Re-export Apollo client from config for components that need it directly
export { apolloClient } from '../config/graphql';
