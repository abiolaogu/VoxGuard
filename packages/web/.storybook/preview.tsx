import type { Preview } from '@storybook/react';
import { ConfigProvider, App } from 'antd';

import '@refinedev/antd/dist/reset.css';
import '../src/styles/index.css';

const preview: Preview = {
    parameters: {
        actions: { argTypesRegex: '^on[A-Z].*' },
        controls: {
            matchers: {
                color: /(background|color)$/i,
                date: /Date$/i,
            },
        },
        backgrounds: {
            default: 'light',
            values: [
                { name: 'light', value: '#f5f5f5' },
                { name: 'dark', value: '#1f1f1f' },
                { name: 'white', value: '#ffffff' },
            ],
        },
    },
    decorators: [
        (Story) => (
            <ConfigProvider
                theme={{
                    token: {
                        colorPrimary: '#1890ff',
                        borderRadius: 6,
                    },
                }}
            >
                <App>
                    <Story />
                </App>
            </ConfigProvider>
        ),
    ],
};

export default preview;
