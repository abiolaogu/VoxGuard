import { Refine, Authenticated } from '@refinedev/core';
import { RefineKbar, RefineKbarProvider } from '@refinedev/kbar';
import {
  ThemedLayoutV2,
  ThemedSiderV2,
  useNotificationProvider,
  ErrorComponent,
} from '@refinedev/antd';
import routerBindings, {
  CatchAllNavigate,
  DocumentTitleHandler,
  NavigateToResource,
  UnsavedChangesNotifier,
} from '@refinedev/react-router-v6';
import { BrowserRouter, Routes, Route, Outlet } from 'react-router-dom';
import { ApolloProvider } from '@apollo/client';
import { App as AntdApp, ConfigProvider } from 'antd';

// Providers
import { authProvider, acmDataProvider, liveProvider, accessControlProvider, apolloClient } from './providers';

// Config
import { resources, refineOptions } from './config/refine';
import { lightTheme, darkTheme } from './config/antd-theme';

// Layout Components
import { Header } from './components/layout/Header';
import { Title } from './components/layout/Title';

// Pages
import { DashboardPage } from './pages/dashboard';
import { LoginPage } from './pages/login';

// Resources
import { AlertList, AlertShow, AlertEdit } from './resources/alerts';
import { GatewayList, GatewayShow, GatewayCreate, GatewayEdit } from './resources/gateways';
import { UserList, UserShow, UserCreate, UserEdit } from './resources/users';
import { AnalyticsPage } from './resources/analytics';
import { SettingsPage } from './resources/settings';

// VoxGuard Security Pages (from VoxSwitch-IM)
import {
  RVSDashboardPage,
  CompositeScoringPage,
  ListsManagePage,
  MultiCallDetectionPage,
  RevenueFraudPage,
  TrafficControlPage,
  FalsePositivesPage,
} from './pages/security';

// NCC Compliance Pages
import { NCCCompliancePage, MNPLookupPage } from './pages/ncc';

// Hooks
import { useThemeMode } from './hooks/useThemeMode';

// Ant Design styles
import '@refinedev/antd/dist/reset.css';

function AppContent() {
  const { mode } = useThemeMode();
  const theme = mode === 'dark' ? darkTheme : lightTheme;

  return (
    <ConfigProvider theme={theme}>
      <AntdApp>
        <BrowserRouter>
          <Refine
            dataProvider={acmDataProvider}
            authProvider={authProvider}
            liveProvider={liveProvider}
            accessControlProvider={accessControlProvider}
            routerProvider={routerBindings}
            notificationProvider={useNotificationProvider}
            resources={resources}
            options={refineOptions}
          >
            <Routes>
              {/* Public Routes */}
              <Route
                element={
                  <Authenticated
                    key="auth-outer"
                    fallback={<Outlet />}
                  >
                    <NavigateToResource resource="dashboard" />
                  </Authenticated>
                }
              >
                <Route path="/login" element={<LoginPage />} />
              </Route>

              {/* Protected Routes */}
              <Route
                element={
                  <Authenticated
                    key="auth-inner"
                    fallback={<CatchAllNavigate to="/login" />}
                  >
                    <ThemedLayoutV2
                      Header={() => <Header />}
                      Sider={() => (
                        <ThemedSiderV2
                          Title={({ collapsed }) => (
                            <Title collapsed={collapsed} />
                          )}
                          fixed
                        />
                      )}
                    >
                      <Outlet />
                    </ThemedLayoutV2>
                  </Authenticated>
                }
              >
                {/* Dashboard */}
                <Route index element={<NavigateToResource resource="dashboard" />} />
                <Route path="/dashboard" element={<DashboardPage />} />

                {/* Alerts */}
                <Route path="/alerts">
                  <Route index element={<AlertList />} />
                  <Route path="show/:id" element={<AlertShow />} />
                  <Route path="edit/:id" element={<AlertEdit />} />
                </Route>

                {/* Gateways */}
                <Route path="/gateways">
                  <Route index element={<GatewayList />} />
                  <Route path="show/:id" element={<GatewayShow />} />
                  <Route path="create" element={<GatewayCreate />} />
                  <Route path="edit/:id" element={<GatewayEdit />} />
                </Route>

                {/* Users */}
                <Route path="/users">
                  <Route index element={<UserList />} />
                  <Route path="show/:id" element={<UserShow />} />
                  <Route path="create" element={<UserCreate />} />
                  <Route path="edit/:id" element={<UserEdit />} />
                </Route>

                {/* Analytics */}
                <Route path="/analytics" element={<AnalyticsPage />} />

                {/* Settings */}
                <Route path="/settings" element={<SettingsPage />} />

                {/* VoxGuard Security Pages */}
                <Route path="/security/rvs-dashboard" element={<RVSDashboardPage />} />
                <Route path="/security/composite-scoring" element={<CompositeScoringPage />} />
                <Route path="/security/lists-manage" element={<ListsManagePage />} />
                <Route path="/security/multicall-detection" element={<MultiCallDetectionPage />} />
                <Route path="/security/revenue-fraud" element={<RevenueFraudPage />} />
                <Route path="/security/traffic-control" element={<TrafficControlPage />} />
                <Route path="/security/false-positives" element={<FalsePositivesPage />} />

                {/* NCC Compliance Pages */}
                <Route path="/ncc/compliance" element={<NCCCompliancePage />} />
                <Route path="/ncc/mnp-lookup" element={<MNPLookupPage />} />

                {/* Catch All */}
                <Route path="*" element={<ErrorComponent />} />
              </Route>
            </Routes>

            <RefineKbar />
            <UnsavedChangesNotifier />
            <DocumentTitleHandler />
          </Refine>
        </BrowserRouter>
      </AntdApp>
    </ConfigProvider>
  );
}

export default function App() {
  return (
    <ApolloProvider client={apolloClient}>
      <RefineKbarProvider>
        <AppContent />
      </RefineKbarProvider>
    </ApolloProvider>
  );
}
