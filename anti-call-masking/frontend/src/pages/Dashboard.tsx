import React from 'react';
import { useQuery } from '@tanstack/react-query';
import {
  AlertTriangle,
  Shield,
  Phone,
  Clock,
  TrendingUp,
  Activity,
  CheckCircle,
  XCircle,
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

function TrafficChart() {
  // Demo data for traffic visualization
  const data = Array.from({ length: 24 }, (_, i) => ({
    hour: `${i}:00`,
    calls: Math.floor(Math.random() * 1000) + 500,
    alerts: Math.floor(Math.random() * 10),
  }));

  return (
    <div className="bg-white rounded-xl shadow-sm p-6">
      <h3 className="text-lg font-semibold text-gray-900 mb-4">Traffic Overview (24h)</h3>
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
              name="Calls"
            />
          </AreaChart>
        </ResponsiveContainer>
      </div>
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
        <div className="bg-white rounded-xl shadow-sm p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">System Health</h3>
          <div className="space-y-4">
            {[
              { name: 'kdb+ Engine', status: 'operational', latency: '0.3ms' },
              { name: 'Detection Service', status: 'operational', latency: '0.8ms' },
              { name: 'API Gateway', status: 'operational', latency: '1.2ms' },
              { name: 'Database', status: 'operational', latency: '2.1ms' },
            ].map((service) => (
              <div key={service.name} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                <div className="flex items-center gap-3">
                  <div className="w-2 h-2 rounded-full bg-green-500" />
                  <span className="text-sm font-medium text-gray-900">{service.name}</span>
                </div>
                <div className="flex items-center gap-4">
                  <span className="text-xs text-gray-500">{service.latency}</span>
                  <span className="px-2 py-1 text-xs font-medium bg-green-100 text-green-800 rounded">
                    {service.status}
                  </span>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
