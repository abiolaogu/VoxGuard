import { defineConfig, loadEnv } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

// https://vitejs.dev/config/
export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '');
  return {
    base: env.VITE_BASE_PATH || '/',
    plugins: [react()],
    resolve: {
      alias: {
        '@': path.resolve(__dirname, './src'),
      },
    },
    server: {
      port: 3000,
      proxy: {
        // Management API proxy
        '/api': {
          target: 'http://localhost:8081',
          changeOrigin: true,
        },
        // ACM Engine proxy
        '/acm': {
          target: 'http://localhost:8080',
          changeOrigin: true,
        },
        // Hasura GraphQL proxy (optional - can also use direct connection)
        '/v1/graphql': {
          target: 'http://localhost:8082',
          changeOrigin: true,
          ws: true, // Enable WebSocket proxy for subscriptions
        },
      },
    },
    build: {
      outDir: 'dist',
      sourcemap: true,
      // Increase chunk size warning limit for large dependencies
      chunkSizeWarningLimit: 1000,
    },
    // Optimize dependencies
    optimizeDeps: {
      include: [
        'react',
        'react-dom',
        'react-router-dom',
        '@refinedev/core',
        '@refinedev/antd',
        'antd',
        '@ant-design/icons',
        '@apollo/client',
        'graphql',
        'dayjs',
      ],
    },
    // Environment variable prefix
    envPrefix: 'VITE_',
  };
});
