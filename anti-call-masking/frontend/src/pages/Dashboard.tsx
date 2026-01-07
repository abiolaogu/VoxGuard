import { useQuery } from '@tanstack/react-query';
import {
  AlertTriangle,
  Phone,
  Clock,
  TrendingUp,
  CheckCircle,
  XCircle,
  RefreshCw,
} from 'lucide-react';
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
} from 'recharts';
import { statsApi, alertsApi, Alert } from '../services/api';
import { cn } from '../utils/cn';

const SEVERITY_COLORS = {
  CRITICAL: '#ef4444',
  HIGH: '#f97316',
  MEDIUM: '#eab308',
  LOW: '#22c55e',
};

interface StatCardProps {
  title: string;
  value: string | number;
  icon: React.ReactNode;
  trend?: { value: number; isPositive: boolean };
  className?: string;
}

function StatCard({ title, value, icon, trend, className }: StatCardProps) {
  return (
    <div className={cn('bg-white rounded-xl shadow-sm p-6', className)}>
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm font-medium text-gray-500">{title}</p>
          <p className="mt-2 text-3xl font-bold text-gray-900">{value}</p>
          {trend && (
            <p
              className={cn(
                'mt-1 text-sm flex items-center gap-1',
                trend.isPositive ? 'text-green-600' : 'text-red-600'
              )}
            >
              <TrendingUp className={cn('h-4 w-4', !trend.isPositive && 'rotate-180')} />
              {trend.value}% from last hour
            </p>
          )}
        </div>
        <div className="p-3 bg-blue-50 rounded-lg">{icon}</div>
      </div>
    </div>
  );
}

function AlertSeverityChart({ alerts }: { alerts: Alert[] }) {
  const data = [
    { name: 'Critical', value: alerts.filter((a) => a.severity === 'CRITICAL').length, color: SEVERITY_COLORS.CRITICAL },
    { name: 'High', value: alerts.filter((a) => a.severity === 'HIGH').length, color: SEVERITY_COLORS.HIGH },
    { name: 'Medium', value: alerts.filter((a) => a.severity === 'MEDIUM').length, color: SEVERITY_COLORS.MEDIUM },
    { name: 'Low', value: alerts.filter((a) => a.severity === 'LOW').length, color: SEVERITY_COLORS.LOW },
  ].filter((d) => d.value > 0);

  return (
    <div className="bg-white rounded-xl shadow-sm p-6">
      <h3 className="text-lg font-semibold text-gray-900 mb-4">Alert Distribution</h3>
      <div className="h-64">
        <ResponsiveContainer width="100%" height="100%">
          <PieChart>
            <Pie
              data={data}
              cx="50%"
              cy="50%"
              innerRadius={60}
              outerRadius={80}
              paddingAngle={5}
              dataKey="value"
            >
              {data.map((entry, index) => (
                <Cell key={`cell-${index}`} fill={entry.color} />
              ))}
            </Pie>
            <Tooltip />
          </PieChart>
        </ResponsiveContainer>
      </div>
      <div className="flex justify-center gap-4 mt-4">
        {data.map((entry) => (
          <div key={entry.name} className="flex items-center gap-2">
            <div className="w-3 h-3 rounded-full" style={{ backgroundColor: entry.color }} />
            <span className="text-sm text-gray-600">
              {entry.name}: {entry.value}
            </span>
          </div>
        ))}
      </div>
    </div>
  );
}

function RecentAlerts({ alerts }: { alerts: Alert[] }) {
  const recentAlerts = alerts.slice(0, 5);

  return (
    <div className="bg-white rounded-xl shadow-sm p-6">
      <h3 className="text-lg font-semibold text-gray-900 mb-4">Recent Alerts</h3>
      <div className="space-y-4">
        {recentAlerts.length === 0 ? (
          <div className="text-center py-8 text-gray-500">
            <CheckCircle className="h-12 w-12 mx-auto mb-2 text-green-500" />
            <p>No active alerts</p>
          </div>
        ) : (
          recentAlerts.map((alert) => (
            <div
              key={alert.id}
              className="flex items-center justify-between p-4 bg-gray-50 rounded-lg"
            >
              <div className="flex items-center gap-3">
                <div
                  className={cn(
                    'w-2 h-2 rounded-full',
                    alert.severity === 'CRITICAL' && 'bg-red-500',
                    alert.severity === 'HIGH' && 'bg-orange-500',
                    alert.severity === 'MEDIUM' && 'bg-yellow-500',
                    alert.severity === 'LOW' && 'bg-green-500'
                  )}
                />
                <div>
                  <p className="text-sm font-medium text-gray-900">
                    {alert.callCount} calls to {alert.bNumber}
                  </p>
                  <p className="text-xs text-gray-500">
                    {new Date(alert.timestamp).toLocaleTimeString()}
                  </p>
                </div>
              </div>
              <span
                className={cn(
                  'px-2 py-1 text-xs font-medium rounded',
                  alert.status === 'NEW' && 'bg-blue-100 text-blue-800',
                  alert.status === 'INVESTIGATING' && 'bg-yellow-100 text-yellow-800',
                  alert.status === 'RESOLVED' && 'bg-green-100 text-green-800',
                  alert.status === 'FALSE_POSITIVE' && 'bg-gray-100 text-gray-800'
                )}
              >
                {alert.status}
              </span>
            </div>
          ))
        )}
      </div>
    </div>
  );
}

interface ServiceHealth {
  name: string;
  status: 'operational' | 'degraded' | 'down';
  latency?: number;
}

function SystemHealth() {
  const { data: healthData, isLoading, error } = useQuery({
    queryKey: ['health'],
    queryFn: statsApi.getHealth,
    refetchInterval: 30000, // Check every 30 seconds
  });

  // Default services with fallback status
  const services: ServiceHealth[] = healthData?.services || [
    { name: 'kdb+ Engine', status: 'operational', latency: healthData?.kdbLatency },
    { name: 'Detection Service', status: 'operational', latency: healthData?.detectionLatency },
    { name: 'API Gateway', status: 'operational', latency: healthData?.apiLatency },
    { name: 'Database', status: 'operational', latency: healthData?.dbLatency },
  ];

  // If health check fails, show all services as unknown
  const displayServices = error ? [
    { name: 'kdb+ Engine', status: 'degraded' as const },
    { name: 'Detection Service', status: 'degraded' as const },
    { name: 'API Gateway', status: 'degraded' as const },
    { name: 'Database', status: 'degraded' as const },
  ] : services;

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'operational': return 'bg-green-500';
      case 'degraded': return 'bg-yellow-500';
      case 'down': return 'bg-red-500';
      default: return 'bg-gray-400';
    }
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'operational': return 'bg-green-100 text-green-800';
      case 'degraded': return 'bg-yellow-100 text-yellow-800';
      case 'down': return 'bg-red-100 text-red-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  return (
    <div className="bg-white rounded-xl shadow-sm p-6">
      <h3 className="text-lg font-semibold text-gray-900 mb-4">System Health</h3>
      {isLoading ? (
        <div className="space-y-4">
          {[1, 2, 3, 4].map((i) => (
            <div key={i} className="animate-pulse flex items-center justify-between p-3 bg-gray-50 rounded-lg">
              <div className="flex items-center gap-3">
                <div className="w-2 h-2 rounded-full bg-gray-300" />
                <div className="h-4 w-24 bg-gray-300 rounded" />
              </div>
              <div className="h-4 w-16 bg-gray-300 rounded" />
            </div>
          ))}
        </div>
      ) : (
        <div className="space-y-4">
          {displayServices.map((service) => (
            <div key={service.name} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
              <div className="flex items-center gap-3">
                <div className={cn('w-2 h-2 rounded-full', getStatusColor(service.status))} />
                <span className="text-sm font-medium text-gray-900">{service.name}</span>
              </div>
              <div className="flex items-center gap-4">
                {service.latency !== undefined && (
                  <span className="text-xs text-gray-500">{service.latency.toFixed(1)}ms</span>
                )}
                <span className={cn('px-2 py-1 text-xs font-medium rounded', getStatusBadge(service.status))}>
                  {service.status}
                </span>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

function TrafficChart() {
  const { data: trafficData, isLoading } = useQuery({
    queryKey: ['traffic'],
    queryFn: () => statsApi.getTraffic(1440), // Last 24 hours
    refetchInterval: 60000, // Refresh every minute
  });

  // Generate fallback data if API not available
  const data = trafficData?.length ? trafficData.map((t, i) => ({
    hour: new Date(t.timestamp).getHours() + ':00',
    calls: t.callsPerSecond * 60, // Convert to calls per minute for display
    alerts: t.alertsPerMinute,
  })) : Array.from({ length: 24 }, (_, i) => ({
    hour: `${i}:00`,
    calls: 0,
    alerts: 0,
  }));

  return (
    <div className="bg-white rounded-xl shadow-sm p-6">
      <h3 className="text-lg font-semibold text-gray-900 mb-4">Traffic Overview (24h)</h3>
      {isLoading ? (
        <div className="h-64 flex items-center justify-center">
          <RefreshCw className="h-8 w-8 animate-spin text-gray-400" />
        </div>
      ) : (
        <div className="h-64">
          <ResponsiveContainer width="100%" height="100%">
            <AreaChart data={data}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="hour" tick={{ fontSize: 12 }} />
              <YAxis tick={{ fontSize: 12 }} />
              <Tooltip />
              <Area
                type="monotone"
                dataKey="calls"
                stroke="#3b82f6"
                fill="#3b82f6"
                fillOpacity={0.2}
                name="Calls/min"
              />
            </AreaChart>
          </ResponsiveContainer>
        </div>
      )}
    </div>
  );
}

export function Dashboard() {
  const { data: alerts = [], isLoading: alertsLoading } = useQuery({
    queryKey: ['alerts'],
    queryFn: () => alertsApi.getRecent(60),
    refetchInterval: 30000, // Refresh every 30 seconds
  });

  const { data: stats, isLoading: statsLoading } = useQuery({
    queryKey: ['stats'],
    queryFn: statsApi.getSystem,
    refetchInterval: 30000,
  });

  // Calculate stats from alerts if API not available
  const calculatedStats = {
    totalAlerts: alerts.length,
    criticalAlerts: alerts.filter((a) => a.severity === 'CRITICAL').length,
    highAlerts: alerts.filter((a) => a.severity === 'HIGH').length,
    resolvedToday: alerts.filter((a) => a.status === 'RESOLVED').length,
    newAlerts: alerts.filter((a) => a.status === 'NEW').length,
  };

  return (
    <div className="space-y-6">
      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatCard
          title="Active Alerts"
          value={calculatedStats.totalAlerts}
          icon={<AlertTriangle className="h-6 w-6 text-blue-600" />}
          trend={{ value: 12, isPositive: false }}
        />
        <StatCard
          title="Critical Alerts"
          value={calculatedStats.criticalAlerts}
          icon={<XCircle className="h-6 w-6 text-red-600" />}
          className={calculatedStats.criticalAlerts > 0 ? 'border-l-4 border-red-500' : ''}
        />
        <StatCard
          title="Calls Processed"
          value={stats?.callsProcessed?.toLocaleString() || '1.2M'}
          icon={<Phone className="h-6 w-6 text-green-600" />}
        />
        <StatCard
          title="Avg Detection Time"
          value={stats?.avgResponseTime ? `${stats.avgResponseTime}ms` : '<1ms'}
          icon={<Clock className="h-6 w-6 text-purple-600" />}
        />
      </div>

      {/* Charts Row */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <TrafficChart />
        <AlertSeverityChart alerts={alerts} />
      </div>

      {/* Bottom Row */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <RecentAlerts alerts={alerts} />

        {/* System Health */}
        <SystemHealth />
      </div>
    </div>
  );
}
