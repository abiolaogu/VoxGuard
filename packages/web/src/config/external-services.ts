/**
 * External Services Configuration
 * Centralized configuration for all VoxGuard monitoring and admin portals
 */

export interface ExternalService {
  id: string;
  name: string;
  description: string;
  icon: string;
  url: string;
  category: 'monitoring' | 'database' | 'analytics' | 'sip' | 'admin';
  healthEndpoint?: string;
  credentials?: {
    username?: string;
    password?: string;
  };
}

// Base URLs from environment or defaults
const getBaseUrl = (envKey: string, defaultValue: string): string => {
  return import.meta.env[envKey] || defaultValue;
};

export const EXTERNAL_SERVICES: ExternalService[] = [
  // Monitoring & Observability
  {
    id: 'grafana',
    name: 'Grafana',
    description: 'Metrics dashboards, visualizations, and alerting',
    icon: 'LineChartOutlined',
    url: getBaseUrl('VITE_GRAFANA_URL', 'http://localhost:3003'),
    category: 'monitoring',
    healthEndpoint: '/api/health',
    credentials: {
      username: 'admin',
      password: 'acm_grafana_2026',
    },
  },
  {
    id: 'prometheus',
    name: 'Prometheus',
    description: 'Metrics collection, queries, and alerting rules',
    icon: 'FireOutlined',
    url: getBaseUrl('VITE_PROMETHEUS_URL', 'http://localhost:9091'),
    category: 'monitoring',
    healthEndpoint: '/-/healthy',
  },
  // Database Consoles
  {
    id: 'hasura',
    name: 'Hasura Console',
    description: 'GraphQL schema explorer and data management',
    icon: 'ApiOutlined',
    url: getBaseUrl('VITE_HASURA_CONSOLE_URL', 'http://localhost:8082/console'),
    category: 'admin',
    healthEndpoint: '/healthz',
  },
  {
    id: 'yugabyte',
    name: 'YugabyteDB',
    description: 'Distributed PostgreSQL cluster management',
    icon: 'DatabaseOutlined',
    url: getBaseUrl('VITE_YUGABYTE_URL', 'http://localhost:9005'),
    category: 'database',
  },
  {
    id: 'clickhouse',
    name: 'ClickHouse',
    description: 'OLAP analytics and historical data',
    icon: 'TableOutlined',
    url: getBaseUrl('VITE_CLICKHOUSE_URL', 'http://localhost:8123/play'),
    category: 'analytics',
  },
  // Time-Series Analytics
  {
    id: 'questdb',
    name: 'QuestDB Console',
    description: 'Real-time time-series analytics and SQL queries',
    icon: 'FieldTimeOutlined',
    url: getBaseUrl('VITE_QUESTDB_URL', 'http://localhost:9002'),
    category: 'analytics',
    healthEndpoint: '/exec?query=SELECT%201',
  },
  // SIP Analysis
  {
    id: 'homer',
    name: 'Homer SIP Capture',
    description: 'SIP packet capture, search, and analysis',
    icon: 'PhoneOutlined',
    url: getBaseUrl('VITE_HOMER_URL', 'http://localhost:9080'),
    category: 'sip',
  },
];

// Group services by category
export const SERVICE_CATEGORIES = {
  monitoring: {
    label: 'Monitoring',
    services: EXTERNAL_SERVICES.filter((s) => s.category === 'monitoring'),
  },
  database: {
    label: 'Databases',
    services: EXTERNAL_SERVICES.filter((s) => s.category === 'database'),
  },
  analytics: {
    label: 'Analytics',
    services: EXTERNAL_SERVICES.filter((s) => s.category === 'analytics'),
  },
  sip: {
    label: 'SIP Analysis',
    services: EXTERNAL_SERVICES.filter((s) => s.category === 'sip'),
  },
  admin: {
    label: 'Administration',
    services: EXTERNAL_SERVICES.filter((s) => s.category === 'admin'),
  },
};

// Helper to generate deep links to external services
export const generateDeepLink = {
  // Grafana dashboard with filters
  grafana: {
    dashboard: (dashboardUid: string, vars?: Record<string, string>) => {
      const base = EXTERNAL_SERVICES.find((s) => s.id === 'grafana')?.url || '';
      const params = vars
        ? '?' + Object.entries(vars).map(([k, v]) => `var-${k}=${encodeURIComponent(v)}`).join('&')
        : '';
      return `${base}/d/${dashboardUid}${params}`;
    },
    explore: (query?: string) => {
      const base = EXTERNAL_SERVICES.find((s) => s.id === 'grafana')?.url || '';
      return query
        ? `${base}/explore?left=${encodeURIComponent(JSON.stringify({ queries: [{ expr: query }] }))}`
        : `${base}/explore`;
    },
    alerting: () => {
      const base = EXTERNAL_SERVICES.find((s) => s.id === 'grafana')?.url || '';
      return `${base}/alerting/list`;
    },
  },
  // Prometheus queries
  prometheus: {
    query: (expr: string) => {
      const base = EXTERNAL_SERVICES.find((s) => s.id === 'prometheus')?.url || '';
      return `${base}/graph?g0.expr=${encodeURIComponent(expr)}&g0.tab=0`;
    },
    alerts: () => {
      const base = EXTERNAL_SERVICES.find((s) => s.id === 'prometheus')?.url || '';
      return `${base}/alerts`;
    },
    targets: () => {
      const base = EXTERNAL_SERVICES.find((s) => s.id === 'prometheus')?.url || '';
      return `${base}/targets`;
    },
  },
  // QuestDB SQL queries
  questdb: {
    query: (sql: string) => {
      const base = EXTERNAL_SERVICES.find((s) => s.id === 'questdb')?.url || '';
      return `${base}/?query=${encodeURIComponent(sql)}`;
    },
  },
  // ClickHouse queries
  clickhouse: {
    query: (sql: string) => {
      const base = EXTERNAL_SERVICES.find((s) => s.id === 'clickhouse')?.url || '';
      return `${base}?query=${encodeURIComponent(sql)}`;
    },
  },
  // Homer SIP search
  homer: {
    search: (params: { from?: string; to?: string; callId?: string }) => {
      const base = EXTERNAL_SERVICES.find((s) => s.id === 'homer')?.url || '';
      const searchParams = new URLSearchParams();
      if (params.from) searchParams.set('from', params.from);
      if (params.to) searchParams.set('to', params.to);
      if (params.callId) searchParams.set('callid', params.callId);
      return `${base}/#/search?${searchParams.toString()}`;
    },
  },
  // Hasura console
  hasura: {
    table: (tableName: string) => {
      const base = EXTERNAL_SERVICES.find((s) => s.id === 'hasura')?.url || '';
      return `${base}/data/default/schema/public/tables/${tableName}/browse`;
    },
    graphiql: () => {
      const base = EXTERNAL_SERVICES.find((s) => s.id === 'hasura')?.url || '';
      return `${base}/api/api-explorer`;
    },
  },
};

// Alert-specific deep links for contextual navigation
export const generateAlertContextLinks = (alert: {
  carrier_name?: string;
  carrier_id?: string;
  b_number?: string;
  a_number?: string;
  created_at?: string;
}) => {
  const links = [];

  // Grafana: View carrier metrics
  if (alert.carrier_name || alert.carrier_id) {
    links.push({
      id: 'grafana-carrier',
      label: 'View Carrier Metrics',
      icon: 'LineChartOutlined',
      url: generateDeepLink.grafana.dashboard('carrier-overview', {
        carrier: alert.carrier_name || alert.carrier_id || '',
      }),
      description: 'Open Grafana dashboard filtered by carrier',
    });
  }

  // Prometheus: Query alert metrics
  links.push({
    id: 'prometheus-alerts',
    label: 'View Alert Metrics',
    icon: 'FireOutlined',
    url: generateDeepLink.prometheus.query(
      `acm_alerts_total{severity=~"CRITICAL|HIGH"}`
    ),
    description: 'View related metrics in Prometheus',
  });

  // QuestDB: Query call data
  if (alert.b_number) {
    links.push({
      id: 'questdb-calls',
      label: 'Query Call History',
      icon: 'FieldTimeOutlined',
      url: generateDeepLink.questdb.query(
        `SELECT * FROM call_events WHERE b_number = '${alert.b_number}' ORDER BY timestamp DESC LIMIT 100`
      ),
      description: 'View call history for this B-number in QuestDB',
    });
  }

  // Homer: Search SIP traces
  if (alert.a_number && alert.b_number) {
    links.push({
      id: 'homer-sip',
      label: 'View SIP Traces',
      icon: 'PhoneOutlined',
      url: generateDeepLink.homer.search({
        from: alert.a_number,
        to: alert.b_number,
      }),
      description: 'Search SIP packets for this call in Homer',
    });
  }

  // ClickHouse: Historical analysis
  links.push({
    id: 'clickhouse-history',
    label: 'Historical Analysis',
    icon: 'TableOutlined',
    url: generateDeepLink.clickhouse.query(
      `SELECT * FROM acm.alerts WHERE b_number = '${alert.b_number || ''}' ORDER BY created_at DESC LIMIT 100`
    ),
    description: 'Query historical alert data in ClickHouse',
  });

  // Hasura: View raw data
  links.push({
    id: 'hasura-data',
    label: 'View Raw Data',
    icon: 'ApiOutlined',
    url: generateDeepLink.hasura.table('acm_alerts'),
    description: 'Browse alerts table in Hasura Console',
  });

  return links;
};

export default EXTERNAL_SERVICES;
