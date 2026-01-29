import React, { useState } from 'react';
import { Refine } from '@refinedev/core';
import { RefineKbarProvider } from '@refinedev/kbar';
import { ThemedLayoutV2, notificationProvider, RefineThemes } from '@refinedev/antd';
import { App as AntApp, ConfigProvider, theme as antTheme, Switch, Space, Typography } from 'antd';
import { BrowserRouter, Routes, Route, Outlet } from 'react-router-dom';
import { AnimatePresence } from 'framer-motion';
import {
    DashboardOutlined,
    AlertOutlined,
    PhoneOutlined,
    ApiOutlined,
    FileTextOutlined,
    SettingOutlined,
    MoonOutlined,
    SunOutlined,
} from '@ant-design/icons';

import { dataProvider } from './providers/dataProvider';
import { liveProvider } from './providers/liveProvider';
import { authProvider } from './providers/authProvider';
import { lovableTheme, lovableDarkTheme } from './theme';
import { ErrorBoundary } from './components/feedback';
import { PageTransition } from './components/animations';
import { Header } from './components/layout/Header';
import { Sider } from './components/layout/Sider';

// Pages - Anti-Masking Only
import Dashboard from './pages/dashboard';
import { FraudAlertList, FraudAlertShow } from './pages/anti-masking/fraud-alerts';
import { CallList, CallShow } from './pages/anti-masking/calls';
import { GatewayList, GatewayCreate, GatewayEdit } from './pages/anti-masking/gateways';
import { Login } from './pages/auth/login';

import '@refinedev/antd/dist/reset.css';
import './styles/index.css';

const { Text } = Typography;

// Dark mode context
const ThemeContext = React.createContext<{
    isDarkMode: boolean;
    toggleDarkMode: () => void;
}>({
    isDarkMode: false,
    toggleDarkMode: () => { },
});

export const useTheme = () => React.useContext(ThemeContext);

// Theme toggle component for header
export const ThemeToggle: React.FC = () => {
    const { isDarkMode, toggleDarkMode } = useTheme();

    return (
        <Space>
            <SunOutlined style={{ color: isDarkMode ? '#666' : '#faad14' }} />
            <Switch
                checked={isDarkMode}
                onChange={toggleDarkMode}
                size="small"
                style={{ backgroundColor: isDarkMode ? '#1890ff' : undefined }}
            />
            <MoonOutlined style={{ color: isDarkMode ? '#1890ff' : '#666' }} />
        </Space>
    );
};

// Layout wrapper with animations
const AnimatedLayout: React.FC = () => {
    return (
        <ThemedLayoutV2
            Header={() => <Header />}
            Sider={() => <Sider />}
        >
            <AnimatePresence mode="wait">
                <PageTransition>
                    <ErrorBoundary>
                        <Outlet />
                    </ErrorBoundary>
                </PageTransition>
            </AnimatePresence>
        </ThemedLayoutV2>
    );
};

const App: React.FC = () => {
    const [isDarkMode, setIsDarkMode] = useState(false);

    const toggleDarkMode = () => {
        setIsDarkMode((prev) => !prev);
    };

    const currentTheme = isDarkMode ? lovableDarkTheme : lovableTheme;

    return (
        <ThemeContext.Provider value={{ isDarkMode, toggleDarkMode }}>
            <BrowserRouter>
                <ConfigProvider
                    theme={{
                        ...currentTheme,
                        algorithm: isDarkMode ? antTheme.darkAlgorithm : antTheme.defaultAlgorithm,
                    }}
                >
                    <AntApp>
                        <RefineKbarProvider>
                            <Refine
                                dataProvider={dataProvider}
                                liveProvider={liveProvider}
                                authProvider={authProvider}
                                notificationProvider={notificationProvider}
                                routerProvider={{} as any}
                                options={{
                                    syncWithLocation: true,
                                    warnWhenUnsavedChanges: true,
                                    liveMode: 'auto',
                                }}
                                resources={[
                                    {
                                        name: 'dashboard',
                                        list: '/dashboard',
                                        meta: {
                                            label: 'Dashboard',
                                            icon: <DashboardOutlined />,
                                        },
                                    },
                                    // Anti-Masking Resources
                                    {
                                        name: 'fraud-alerts',
                                        list: '/anti-masking/fraud-alerts',
                                        show: '/anti-masking/fraud-alerts/:id',
                                        meta: {
                                            label: 'Fraud Alerts',
                                            icon: <AlertOutlined />,
                                            parent: 'Anti-Masking',
                                        },
                                    },
                                    {
                                        name: 'calls',
                                        list: '/anti-masking/calls',
                                        show: '/anti-masking/calls/:id',
                                        meta: {
                                            label: 'Call Log',
                                            icon: <PhoneOutlined />,
                                            parent: 'Anti-Masking',
                                        },
                                    },
                                    {
                                        name: 'gateways',
                                        list: '/anti-masking/gateways',
                                        create: '/anti-masking/gateways/create',
                                        edit: '/anti-masking/gateways/:id/edit',
                                        meta: {
                                            label: 'Gateways',
                                            icon: <ApiOutlined />,
                                            parent: 'Anti-Masking',
                                        },
                                    },
                                    {
                                        name: 'reports',
                                        list: '/anti-masking/reports',
                                        meta: {
                                            label: 'Reports',
                                            icon: <FileTextOutlined />,
                                            parent: 'Anti-Masking',
                                        },
                                    },
                                ]}
                            >
                                <Routes>
                                    <Route path="/login" element={<Login />} />
                                    <Route element={<AnimatedLayout />}>
                                        <Route index element={<Dashboard />} />
                                        <Route path="/dashboard" element={<Dashboard />} />

                                        {/* Anti-Masking Routes */}
                                        <Route path="/anti-masking/fraud-alerts" element={<FraudAlertList />} />
                                        <Route path="/anti-masking/fraud-alerts/:id" element={<FraudAlertShow />} />
                                        <Route path="/anti-masking/calls" element={<CallList />} />
                                        <Route path="/anti-masking/calls/:id" element={<CallShow />} />
                                        <Route path="/anti-masking/gateways" element={<GatewayList />} />
                                        <Route path="/anti-masking/gateways/create" element={<GatewayCreate />} />
                                        <Route path="/anti-masking/gateways/:id/edit" element={<GatewayEdit />} />
                                    </Route>
                                </Routes>
                            </Refine>
                        </RefineKbarProvider>
                    </AntApp>
                </ConfigProvider>
            </BrowserRouter>
        </ThemeContext.Provider>
    );
};

export default App;

