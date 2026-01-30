import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

// https://vitejs.dev/config/
export default defineConfig({
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
    rollupOptions: {
      output: {
        manualChunks: {
          // Core React
          vendor: ['react', 'react-dom', 'react-router-dom'],
          // Refine framework
          refine: [
            '@refinedev/core',
            '@refinedev/antd',
            '@refinedev/react-router-v6',
            '@refinedev/hasura',
          ],
          // UI components
          antd: ['antd', '@ant-design/icons'],
          // Charts
          charts: ['@ant-design/charts'],
          // GraphQL
          graphql: ['@apollo/client', 'graphql', 'graphql-ws'],
          // Utilities
          utils: ['dayjs'],
        },
      },
    },
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
});
