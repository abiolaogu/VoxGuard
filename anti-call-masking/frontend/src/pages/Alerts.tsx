import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import {
  AlertTriangle,
  Search,
  Filter,
  ChevronRight,
  Clock,
  MapPin,
  Phone,
  RefreshCw,
} from 'lucide-react';
import { alertsApi, Alert } from '../services/api';
import { cn } from '../utils/cn';

const SEVERITY_STYLES = {
  CRITICAL: 'bg-red-100 text-red-800 border-red-200',
  HIGH: 'bg-orange-100 text-orange-800 border-orange-200',
  MEDIUM: 'bg-yellow-100 text-yellow-800 border-yellow-200',
  LOW: 'bg-green-100 text-green-800 border-green-200',
};

const STATUS_STYLES = {
  NEW: 'bg-blue-100 text-blue-800',
  INVESTIGATING: 'bg-yellow-100 text-yellow-800',
  RESOLVED: 'bg-green-100 text-green-800',
  FALSE_POSITIVE: 'bg-gray-100 text-gray-800',
};

export function Alerts() {
  const [searchTerm, setSearchTerm] = useState('');
  const [severityFilter, setSeverityFilter] = useState<string>('all');
  const [statusFilter, setStatusFilter] = useState<string>('all');

  const { data: alerts = [], isLoading, refetch, isFetching } = useQuery({
    queryKey: ['alerts'],
    queryFn: () => alertsApi.getRecent(1440), // Last 24 hours
    refetchInterval: 30000,
  });

  // Filter alerts
  const filteredAlerts = alerts.filter((alert) => {
    const matchesSearch =
      searchTerm === '' ||
      alert.bNumber.includes(searchTerm) ||
      alert.aNumbers.some((a) => a.includes(searchTerm)) ||
      alert.id.includes(searchTerm);

    const matchesSeverity = severityFilter === 'all' || alert.severity === severityFilter;
    const matchesStatus = statusFilter === 'all' || alert.status === statusFilter;

    return matchesSearch && matchesSeverity && matchesStatus;
  });

  // Group alerts by severity for summary
  const summary = {
    critical: alerts.filter((a) => a.severity === 'CRITICAL').length,
    high: alerts.filter((a) => a.severity === 'HIGH').length,
    medium: alerts.filter((a) => a.severity === 'MEDIUM').length,
    low: alerts.filter((a) => a.severity === 'LOW').length,
  };

  return (
    <div className="space-y-6">
      {/* Summary Cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <button
          onClick={() => setSeverityFilter('CRITICAL')}
          className={cn(
            'p-4 rounded-lg border-2 text-left transition-all',
            severityFilter === 'CRITICAL' ? 'border-red-500 bg-red-50' : 'border-transparent bg-white shadow-sm hover:border-red-300'
          )}
        >
          <p className="text-2xl font-bold text-red-600">{summary.critical}</p>
          <p className="text-sm text-gray-600">Critical</p>
        </button>
        <button
          onClick={() => setSeverityFilter('HIGH')}
          className={cn(
            'p-4 rounded-lg border-2 text-left transition-all',
            severityFilter === 'HIGH' ? 'border-orange-500 bg-orange-50' : 'border-transparent bg-white shadow-sm hover:border-orange-300'
          )}
        >
          <p className="text-2xl font-bold text-orange-600">{summary.high}</p>
          <p className="text-sm text-gray-600">High</p>
        </button>
        <button
          onClick={() => setSeverityFilter('MEDIUM')}
          className={cn(
            'p-4 rounded-lg border-2 text-left transition-all',
            severityFilter === 'MEDIUM' ? 'border-yellow-500 bg-yellow-50' : 'border-transparent bg-white shadow-sm hover:border-yellow-300'
          )}
        >
          <p className="text-2xl font-bold text-yellow-600">{summary.medium}</p>
          <p className="text-sm text-gray-600">Medium</p>
        </button>
        <button
          onClick={() => setSeverityFilter('LOW')}
          className={cn(
            'p-4 rounded-lg border-2 text-left transition-all',
            severityFilter === 'LOW' ? 'border-green-500 bg-green-50' : 'border-transparent bg-white shadow-sm hover:border-green-300'
          )}
        >
          <p className="text-2xl font-bold text-green-600">{summary.low}</p>
          <p className="text-sm text-gray-600">Low</p>
        </button>
      </div>

      {/* Filters */}
      <div className="bg-white rounded-xl shadow-sm p-4">
        <div className="flex flex-col md:flex-row gap-4">
          {/* Search */}
          <div className="flex-1 relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-gray-400" />
            <input
              type="text"
              placeholder="Search by B-number, A-number, or ID..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          {/* Status Filter */}
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="all">All Statuses</option>
            <option value="NEW">New</option>
            <option value="INVESTIGATING">Investigating</option>
            <option value="RESOLVED">Resolved</option>
            <option value="FALSE_POSITIVE">False Positive</option>
          </select>

          {/* Clear Filters */}
          {(severityFilter !== 'all' || statusFilter !== 'all' || searchTerm) && (
            <button
              onClick={() => {
                setSeverityFilter('all');
                setStatusFilter('all');
                setSearchTerm('');
              }}
              className="px-4 py-2 text-gray-600 hover:text-gray-900"
            >
              Clear filters
            </button>
          )}

          {/* Refresh */}
          <button
            onClick={() => refetch()}
            disabled={isFetching}
            className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50"
          >
            <RefreshCw className={cn('h-4 w-4', isFetching && 'animate-spin')} />
            Refresh
          </button>
        </div>
      </div>

      {/* Alerts List */}
      <div className="bg-white rounded-xl shadow-sm overflow-hidden">
        {isLoading ? (
          <div className="p-8 text-center">
            <RefreshCw className="h-8 w-8 mx-auto animate-spin text-gray-400" />
            <p className="mt-2 text-gray-500">Loading alerts...</p>
          </div>
        ) : filteredAlerts.length === 0 ? (
          <div className="p-8 text-center">
            <AlertTriangle className="h-12 w-12 mx-auto text-gray-300" />
            <p className="mt-2 text-gray-500">No alerts found</p>
          </div>
        ) : (
          <div className="divide-y divide-gray-200">
            {filteredAlerts.map((alert) => (
              <Link
                key={alert.id}
                to={`/alerts/${alert.id}`}
                className="block hover:bg-gray-50 transition-colors"
              >
                <div className="p-4 sm:p-6">
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <div className="flex items-center gap-3">
                        <span className={cn('px-2 py-1 text-xs font-medium rounded border', SEVERITY_STYLES[alert.severity])}>
                          {alert.severity}
                        </span>
                        <span className={cn('px-2 py-1 text-xs font-medium rounded', STATUS_STYLES[alert.status])}>
                          {alert.status}
                        </span>
                        <span className="text-xs text-gray-500">ID: {alert.id.slice(0, 8)}</span>
                      </div>

                      <div className="mt-3 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
                        <div className="flex items-center gap-2 text-sm">
                          <Phone className="h-4 w-4 text-gray-400" />
                          <span className="text-gray-600">B-Number:</span>
                          <span className="font-mono font-medium">{alert.bNumber}</span>
                        </div>
                        <div className="flex items-center gap-2 text-sm">
                          <AlertTriangle className="h-4 w-4 text-gray-400" />
                          <span className="text-gray-600">A-Numbers:</span>
                          <span className="font-medium">{alert.callCount}</span>
                        </div>
                        <div className="flex items-center gap-2 text-sm">
                          <MapPin className="h-4 w-4 text-gray-400" />
                          <span className="text-gray-600">IPs:</span>
                          <span className="font-medium">{alert.sourceIps?.length || 1}</span>
                        </div>
                        <div className="flex items-center gap-2 text-sm">
                          <Clock className="h-4 w-4 text-gray-400" />
                          <span className="text-gray-500">
                            {new Date(alert.timestamp).toLocaleString()}
                          </span>
                        </div>
                      </div>
                    </div>

                    <ChevronRight className="h-5 w-5 text-gray-400" />
                  </div>
                </div>
              </Link>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
