import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
  LineChart,
  Line,
  PieChart,
  Pie,
  Cell,
  AreaChart,
  Area,
} from 'recharts';
import { Calendar, TrendingUp, TrendingDown, Activity, Clock } from 'lucide-react';
import { analyticsApi, statsApi } from '../services/api';
import { cn } from '../utils/cn';

const COLORS = ['#3b82f6', '#22c55e', '#eab308', '#ef4444', '#8b5cf6', '#ec4899'];

export function Analytics() {
  const [timeRange, setTimeRange] = useState<'1h' | '24h' | '7d' | '30d'>('24h');

  const getMinutes = () => {
    switch (timeRange) {
      case '1h': return 60;
      case '24h': return 1440;
      case '7d': return 10080;
      case '30d': return 43200;
      default: return 1440;
    }
  };

  // Demo data for analytics
  const hourlyData = Array.from({ length: 24 }, (_, i) => ({
    hour: `${i}:00`,
    alerts: Math.floor(Math.random() * 20) + 5,
    calls: Math.floor(Math.random() * 5000) + 1000,
    blocked: Math.floor(Math.random() * 10) + 2,
  }));

  const weeklyData = Array.from({ length: 7 }, (_, i) => {
    const date = new Date();
    date.setDate(date.getDate() - (6 - i));
    return {
      day: date.toLocaleDateString('en-US', { weekday: 'short' }),
      critical: Math.floor(Math.random() * 10) + 1,
      high: Math.floor(Math.random() * 20) + 5,
      medium: Math.floor(Math.random() * 30) + 10,
      low: Math.floor(Math.random() * 15) + 5,
    };
  });

  const topTargetsData = [
    { number: '+2348012345678', count: 45 },
    { number: '+2348098765432', count: 32 },
    { number: '+2348055667788', count: 28 },
    { number: '+2348011223344', count: 21 },
    { number: '+2348099887766', count: 18 },
  ];

  const sourceDistribution = [
    { name: 'Nigeria', value: 45 },
    { name: 'Ghana', value: 20 },
    { name: 'South Africa', value: 15 },
    { name: 'Kenya', value: 12 },
    { name: 'Other', value: 8 },
  ];

  const detectionMetrics = {
    avgDetectionTime: 0.8,
    avgResponseTime: 2.3,
    falsePositiveRate: 2.1,
    truePositiveRate: 97.9,
    callsAnalyzed: 1247893,
    fraudPrevented: 4521,
  };

  return (
    <div className="space-y-6">
      {/* Time Range Selector */}
      <div className="bg-white rounded-xl shadow-sm p-4 flex items-center justify-between">
        <div className="flex items-center gap-2 text-gray-600">
          <Calendar className="h-5 w-5" />
          <span className="font-medium">Time Range</span>
        </div>
        <div className="flex gap-2">
          {(['1h', '24h', '7d', '30d'] as const).map((range) => (
            <button
              key={range}
              onClick={() => setTimeRange(range)}
              className={cn(
                'px-4 py-2 rounded-lg text-sm font-medium transition-colors',
                timeRange === range
                  ? 'bg-blue-600 text-white'
                  : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
              )}
            >
              {range}
            </button>
          ))}
        </div>
      </div>

      {/* Key Metrics */}
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
        <div className="bg-white rounded-xl shadow-sm p-4">
          <p className="text-sm text-gray-500">Detection Time</p>
          <p className="text-2xl font-bold text-green-600">{detectionMetrics.avgDetectionTime}ms</p>
          <p className="text-xs text-gray-400">average</p>
        </div>
        <div className="bg-white rounded-xl shadow-sm p-4">
          <p className="text-sm text-gray-500">Response Time</p>
          <p className="text-2xl font-bold text-blue-600">{detectionMetrics.avgResponseTime}s</p>
          <p className="text-xs text-gray-400">average</p>
        </div>
        <div className="bg-white rounded-xl shadow-sm p-4">
          <p className="text-sm text-gray-500">True Positive</p>
          <p className="text-2xl font-bold text-green-600">{detectionMetrics.truePositiveRate}%</p>
          <p className="text-xs text-gray-400">accuracy</p>
        </div>
        <div className="bg-white rounded-xl shadow-sm p-4">
          <p className="text-sm text-gray-500">False Positive</p>
          <p className="text-2xl font-bold text-yellow-600">{detectionMetrics.falsePositiveRate}%</p>
          <p className="text-xs text-gray-400">rate</p>
        </div>
        <div className="bg-white rounded-xl shadow-sm p-4">
          <p className="text-sm text-gray-500">Calls Analyzed</p>
          <p className="text-2xl font-bold text-gray-900">{(detectionMetrics.callsAnalyzed / 1000000).toFixed(2)}M</p>
          <p className="text-xs text-gray-400">total</p>
        </div>
        <div className="bg-white rounded-xl shadow-sm p-4">
          <p className="text-sm text-gray-500">Fraud Prevented</p>
          <p className="text-2xl font-bold text-red-600">{detectionMetrics.fraudPrevented.toLocaleString()}</p>
          <p className="text-xs text-gray-400">attempts</p>
        </div>
      </div>

      {/* Charts Row 1 */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Hourly Alert Trend */}
        <div className="bg-white rounded-xl shadow-sm p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Alert Trend (24h)</h3>
          <div className="h-80">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={hourlyData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="hour" tick={{ fontSize: 12 }} />
                <YAxis tick={{ fontSize: 12 }} />
                <Tooltip />
                <Area
                  type="monotone"
                  dataKey="alerts"
                  stroke="#ef4444"
                  fill="#ef4444"
                  fillOpacity={0.2}
                  name="Alerts"
                />
                <Area
                  type="monotone"
                  dataKey="blocked"
                  stroke="#22c55e"
                  fill="#22c55e"
                  fillOpacity={0.2}
                  name="Blocked"
                />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Weekly Severity Breakdown */}
        <div className="bg-white rounded-xl shadow-sm p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Weekly Severity Breakdown</h3>
          <div className="h-80">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={weeklyData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="day" tick={{ fontSize: 12 }} />
                <YAxis tick={{ fontSize: 12 }} />
                <Tooltip />
                <Legend />
                <Bar dataKey="critical" stackId="a" fill="#ef4444" name="Critical" />
                <Bar dataKey="high" stackId="a" fill="#f97316" name="High" />
                <Bar dataKey="medium" stackId="a" fill="#eab308" name="Medium" />
                <Bar dataKey="low" stackId="a" fill="#22c55e" name="Low" />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>

      {/* Charts Row 2 */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Top Targeted Numbers */}
        <div className="lg:col-span-2 bg-white rounded-xl shadow-sm p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Top Targeted B-Numbers</h3>
          <div className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={topTargetsData} layout="vertical">
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis type="number" tick={{ fontSize: 12 }} />
                <YAxis dataKey="number" type="category" tick={{ fontSize: 10 }} width={120} />
                <Tooltip />
                <Bar dataKey="count" fill="#3b82f6" name="Attack Count" />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Source Distribution */}
        <div className="bg-white rounded-xl shadow-sm p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Attack Origin</h3>
          <div className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={sourceDistribution}
                  cx="50%"
                  cy="50%"
                  innerRadius={50}
                  outerRadius={80}
                  paddingAngle={5}
                  dataKey="value"
                >
                  {sourceDistribution.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          </div>
          <div className="flex flex-wrap justify-center gap-2 mt-4">
            {sourceDistribution.map((entry, index) => (
              <div key={entry.name} className="flex items-center gap-1">
                <div
                  className="w-3 h-3 rounded-full"
                  style={{ backgroundColor: COLORS[index % COLORS.length] }}
                />
                <span className="text-xs text-gray-600">{entry.name}</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Detection Performance */}
      <div className="bg-white rounded-xl shadow-sm p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Detection Performance Over Time</h3>
        <div className="h-80">
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={hourlyData}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="hour" tick={{ fontSize: 12 }} />
              <YAxis tick={{ fontSize: 12 }} />
              <Tooltip />
              <Legend />
              <Line
                type="monotone"
                dataKey="calls"
                stroke="#3b82f6"
                strokeWidth={2}
                dot={false}
                name="Calls Processed"
              />
              <Line
                type="monotone"
                dataKey="alerts"
                stroke="#ef4444"
                strokeWidth={2}
                dot={false}
                name="Alerts Generated"
              />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  );
}
