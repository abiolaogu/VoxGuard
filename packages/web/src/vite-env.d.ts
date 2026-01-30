/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_HASURA_ENDPOINT: string;
  readonly VITE_HASURA_WS_ENDPOINT: string;
  readonly VITE_HASURA_ADMIN_SECRET: string;
  readonly VITE_API_BASE_URL: string;
  readonly VITE_ACM_ENGINE_URL: string;
  readonly VITE_APP_NAME: string;
  readonly VITE_APP_VERSION: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
