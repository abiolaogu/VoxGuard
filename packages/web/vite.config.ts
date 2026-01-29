import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
    plugins: [react()],
    resolve: {
        alias: {
            '@': path.resolve(__dirname, './src'),
            '@components': path.resolve(__dirname, './src/components'),
            '@pages': path.resolve(__dirname, './src/pages'),
            '@hooks': path.resolve(__dirname, './src/hooks'),
            '@providers': path.resolve(__dirname, './src/providers'),
            '@contexts': path.resolve(__dirname, './src/contexts'),
            '@graphql': path.resolve(__dirname, './src/graphql'),
            '@types': path.resolve(__dirname, './src/types'),
        },
    },
    server: {
        port: 3000,
        host: true,
    },
    build: {
        outDir: 'dist',
        sourcemap: true,
    },
    test: {
        globals: true,
        environment: 'jsdom',
        setupFiles: './src/test/setup.ts',
        coverage: {
            reporter: ['text', 'json', 'html'],
        },
    },
});
