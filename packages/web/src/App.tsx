import { Refine } from '@refinedev/core';
import { RefineKbar, RefineKbarProvider } from '@refinedev/kbar';
import { ThemedLayoutV2, useNotificationProvider, ErrorComponent } from '@refinedev/antd';
import { BrowserRouter, Routes, Route, Outlet } from 'react-router-dom';
import { ConfigProvider, App as AntdApp, theme } from 'antd';
import {
    DashboardOutlined,
    AlertOutlined,
    ApiOutlined,
    PhoneOutlined,
    SwapOutlined,
    BankOutlined,
    TeamOutlined,
    ShopOutlined,
    ShoppingCartOutlined,
} from '@ant-design/icons';

import { hasuraDataProvider } from '@/providers/dataProvider';
import { liveProvider } from '@/providers/liveProvider';
import { authProvider } from '@/providers/authProvider';

// Pages
import { Dashboard } from '@/pages/dashboard';
import { FraudAlertList, FraudAlertShow } from '@/pages/anti-masking/fraud-alerts';
import { GatewayList, GatewayCreate, GatewayEdit } from '@/pages/anti-masking/gateways';
import { CallList, CallShow } from '@/pages/anti-masking/calls';
import { CorridorList } from '@/pages/remittance/corridors';
import { TransactionList, TransactionShow } from '@/pages/remittance/transactions';
import { BeneficiaryList, BeneficiaryCreate } from '@/pages/remittance/beneficiaries';
import { ListingList, ListingShow } from '@/pages/marketplace/listings';
import { OrderList, OrderShow } from '@/pages/marketplace/orders';
import { Login } from '@/pages/auth/login';

// Components
import { Header } from '@/components/layout/Header';
import { Sider } from '@/components/layout/Sider';

import '@refinedev/antd/dist/reset.css';
import './styles/index.css';

const { darkAlgorithm, defaultAlgorithm } = theme;

function App() {
    const isDarkMode = window.matchMedia('(prefers-color-scheme: dark)').matches;

    return (
        <BrowserRouter>
            <RefineKbarProvider>
                <ConfigProvider
                    theme={{
                        algorithm: isDarkMode ? darkAlgorithm : defaultAlgorithm,
                        token: {
                            colorPrimary: '#1890ff',
                            borderRadius: 6,
                        },
                    }}
                >
                    <AntdApp>
                        <Refine
                            dataProvider={hasuraDataProvider}
                            liveProvider={liveProvider}
                            authProvider={authProvider}
                            notificationProvider={useNotificationProvider}
                            routerProvider={{
                                routes: {
                                    login: '/login',
                                },
                            }}
                            resources={[
                                {
                                    name: 'dashboard',
                                    list: '/dashboard',
                                    meta: {
                                        icon: <DashboardOutlined />,
                                        label: 'Dashboard',
                                    },
                                },
                                // Anti-Masking Context
                                {
                                    name: 'fraud-alerts',
                                    list: '/anti-masking/fraud-alerts',
                                    show: '/anti-masking/fraud-alerts/:id',
                                    meta: {
                                        icon: <AlertOutlined />,
                                        label: 'Fraud Alerts',
                                        parent: 'anti-masking',
                                    },
                                },
                                {
                                    name: 'gateways',
                                    list: '/anti-masking/gateways',
                                    create: '/anti-masking/gateways/create',
                                    edit: '/anti-masking/gateways/:id/edit',
                                    meta: {
                                        icon: <ApiOutlined />,
                                        label: 'Gateways',
                                        parent: 'anti-masking',
                                    },
                                },
                                {
                                    name: 'calls',
                                    list: '/anti-masking/calls',
                                    show: '/anti-masking/calls/:id',
                                    meta: {
                                        icon: <PhoneOutlined />,
                                        label: 'Call Log',
                                        parent: 'anti-masking',
                                    },
                                },
                                // Remittance Context
                                {
                                    name: 'corridors',
                                    list: '/remittance/corridors',
                                    meta: {
                                        icon: <SwapOutlined />,
                                        label: 'Corridors',
                                        parent: 'remittance',
                                    },
                                },
                                {
                                    name: 'transactions',
                                    list: '/remittance/transactions',
                                    show: '/remittance/transactions/:id',
                                    meta: {
                                        icon: <BankOutlined />,
                                        label: 'Transactions',
                                        parent: 'remittance',
                                    },
                                },
                                {
                                    name: 'beneficiaries',
                                    list: '/remittance/beneficiaries',
                                    create: '/remittance/beneficiaries/create',
                                    meta: {
                                        icon: <TeamOutlined />,
                                        label: 'Beneficiaries',
                                        parent: 'remittance',
                                    },
                                },
                                // Marketplace Context
                                {
                                    name: 'listings',
                                    list: '/marketplace/listings',
                                    show: '/marketplace/listings/:id',
                                    meta: {
                                        icon: <ShopOutlined />,
                                        label: 'Listings',
                                        parent: 'marketplace',
                                    },
                                },
                                {
                                    name: 'orders',
                                    list: '/marketplace/orders',
                                    show: '/marketplace/orders/:id',
                                    meta: {
                                        icon: <ShoppingCartOutlined />,
                                        label: 'Orders',
                                        parent: 'marketplace',
                                    },
                                },
                            ]}
                            options={{
                                syncWithLocation: true,
                                warnWhenUnsavedChanges: true,
                                liveMode: 'auto',
                            }}
                        >
                            <Routes>
                                <Route path="/login" element={<Login />} />
                                <Route
                                    element={
                                        <ThemedLayoutV2
                                            Header={() => <Header />}
                                            Sider={() => <Sider />}
                                        >
                                            <Outlet />
                                        </ThemedLayoutV2>
                                    }
                                >
                                    <Route index element={<Dashboard />} />
                                    <Route path="/dashboard" element={<Dashboard />} />

                                    {/* Anti-Masking Routes */}
                                    <Route path="/anti-masking">
                                        <Route path="fraud-alerts" element={<FraudAlertList />} />
                                        <Route path="fraud-alerts/:id" element={<FraudAlertShow />} />
                                        <Route path="gateways" element={<GatewayList />} />
                                        <Route path="gateways/create" element={<GatewayCreate />} />
                                        <Route path="gateways/:id/edit" element={<GatewayEdit />} />
                                        <Route path="calls" element={<CallList />} />
                                        <Route path="calls/:id" element={<CallShow />} />
                                    </Route>

                                    {/* Remittance Routes */}
                                    <Route path="/remittance">
                                        <Route path="corridors" element={<CorridorList />} />
                                        <Route path="transactions" element={<TransactionList />} />
                                        <Route path="transactions/:id" element={<TransactionShow />} />
                                        <Route path="beneficiaries" element={<BeneficiaryList />} />
                                        <Route path="beneficiaries/create" element={<BeneficiaryCreate />} />
                                    </Route>

                                    {/* Marketplace Routes */}
                                    <Route path="/marketplace">
                                        <Route path="listings" element={<ListingList />} />
                                        <Route path="listings/:id" element={<ListingShow />} />
                                        <Route path="orders" element={<OrderList />} />
                                        <Route path="orders/:id" element={<OrderShow />} />
                                    </Route>

                                    <Route path="*" element={<ErrorComponent />} />
                                </Route>
                            </Routes>
                            <RefineKbar />
                        </Refine>
                    </AntdApp>
                </ConfigProvider>
            </RefineKbarProvider>
        </BrowserRouter>
    );
}

export default App;
