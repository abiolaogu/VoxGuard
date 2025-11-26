import React, { useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  ArrowLeft,
  Phone,
  MapPin,
  Clock,
  AlertTriangle,
  User,
  FileText,
  CheckCircle,
  XCircle,
  Loader2,
} from 'lucide-react';
import { alertsApi, Alert } from '../services/api';
import { useAuthStore } from '../stores/authStore';
import { cn } from '../utils/cn';

const SEVERITY_STYLES = {
  CRITICAL: 'bg-red-100 text-red-800 border-red-200',
  HIGH: 'bg-orange-100 text-orange-800 border-orange-200',
  MEDIUM: 'bg-yellow-100 text-yellow-800 border-yellow-200',
  LOW: 'bg-green-100 text-green-800 border-green-200',
};

export function AlertDetail() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const user = useAuthStore((state) => state.user);
  const [notes, setNotes] = useState('');
  const [selectedStatus, setSelectedStatus] = useState<Alert['status'] | null>(null);

  // Demo alert data
  const demoAlert: Alert = {
    id: id || 'demo-001',
    timestamp: new Date().toISOString(),
    bNumber: '+2348012345678',
    aNumbers: [
      '+2347011111111',
      '+2347022222222',
      '+2347033333333',
      '+2347044444444',
      '+2347055555555',
      '+2347066666666',
    ],
    sourceIps: ['192.168.1.100', '192.168.1.101', '10.0.0.50'],
    callCount: 6,
    windowSeconds: 5,
    severity: 'CRITICAL',
    status: 'NEW',
    notes: 'Multiple source IPs detected within detection window.',
  };

  const { data: alert = demoAlert, isLoading } = useQuery({
    queryKey: ['alert', id],
    queryFn: () => alertsApi.getById(id!),
    enabled: !!id,
  });

  const updateMutation = useMutation({
    mutationFn: ({ status, notes }: { status: Alert['status']; notes?: string }) =>
      alertsApi.updateStatus(id!, status, notes),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['alert', id] });
      queryClient.invalidateQueries({ queryKey: ['alerts'] });
      setSelectedStatus(null);
      setNotes('');
    },
  });

  const handleStatusUpdate = (status: Alert['status']) => {
    updateMutation.mutate({ status, notes });
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-96">
        <Loader2 className="h-8 w-8 animate-spin text-gray-400" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <button
          onClick={() => navigate('/alerts')}
          className="flex items-center gap-2 text-gray-600 hover:text-gray-900"
        >
          <ArrowLeft className="h-5 w-5" />
          Back to Alerts
        </button>

        <div className="flex items-center gap-2">
          <span className={cn('px-3 py-1 text-sm font-medium rounded border', SEVERITY_STYLES[alert.severity])}>
            {alert.severity}
          </span>
        </div>
      </div>

      {/* Main Content */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Alert Details */}
        <div className="lg:col-span-2 space-y-6">
          {/* Overview Card */}
          <div className="bg-white rounded-xl shadow-sm p-6">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">Alert Overview</h2>

            <div className="grid grid-cols-2 gap-6">
              <div>
                <p className="text-sm text-gray-500">Alert ID</p>
                <p className="font-mono text-sm">{alert.id}</p>
              </div>
              <div>
                <p className="text-sm text-gray-500">Detection Time</p>
                <p className="text-sm">{new Date(alert.timestamp).toLocaleString()}</p>
              </div>
              <div>
                <p className="text-sm text-gray-500">Window Duration</p>
                <p className="text-sm">{alert.windowSeconds} seconds</p>
              </div>
              <div>
                <p className="text-sm text-gray-500">Total Calls</p>
                <p className="text-sm font-semibold text-red-600">{alert.callCount} calls</p>
              </div>
            </div>
          </div>

          {/* B-Number Details */}
          <div className="bg-white rounded-xl shadow-sm p-6">
            <h2 className="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
              <Phone className="h-5 w-5 text-blue-600" />
              Target B-Number
            </h2>
            <div className="p-4 bg-gray-50 rounded-lg">
              <p className="font-mono text-xl font-semibold">{alert.bNumber}</p>
              <p className="text-sm text-gray-500 mt-1">
                Received {alert.callCount} calls from {alert.aNumbers.length} distinct A-numbers
              </p>
            </div>
          </div>

          {/* A-Numbers Table */}
          <div className="bg-white rounded-xl shadow-sm p-6">
            <h2 className="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
              <AlertTriangle className="h-5 w-5 text-orange-600" />
              Source A-Numbers ({alert.aNumbers.length})
            </h2>
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead>
                  <tr>
                    <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">#</th>
                    <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">A-Number</th>
                    <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-200">
                  {alert.aNumbers.map((aNumber, idx) => (
                    <tr key={idx} className="hover:bg-gray-50">
                      <td className="px-4 py-3 text-sm text-gray-500">{idx + 1}</td>
                      <td className="px-4 py-3 font-mono text-sm">{aNumber}</td>
                      <td className="px-4 py-3">
                        <span className="px-2 py-1 text-xs bg-red-100 text-red-800 rounded">
                          Suspicious
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>

          {/* Source IPs */}
          <div className="bg-white rounded-xl shadow-sm p-6">
            <h2 className="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
              <MapPin className="h-5 w-5 text-purple-600" />
              Source IP Addresses ({alert.sourceIps?.length || 0})
            </h2>
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
              {(alert.sourceIps || []).map((ip, idx) => (
                <div key={idx} className="p-3 bg-gray-50 rounded-lg">
                  <p className="font-mono text-sm">{ip}</p>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Actions Sidebar */}
        <div className="space-y-6">
          {/* Current Status */}
          <div className="bg-white rounded-xl shadow-sm p-6">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">Current Status</h2>
            <div className={cn(
              'p-4 rounded-lg text-center',
              alert.status === 'NEW' && 'bg-blue-50 text-blue-800',
              alert.status === 'INVESTIGATING' && 'bg-yellow-50 text-yellow-800',
              alert.status === 'RESOLVED' && 'bg-green-50 text-green-800',
              alert.status === 'FALSE_POSITIVE' && 'bg-gray-50 text-gray-800'
            )}>
              <p className="text-lg font-semibold">{alert.status}</p>
            </div>

            {alert.assignedTo && (
              <div className="mt-4 flex items-center gap-2 text-sm text-gray-600">
                <User className="h-4 w-4" />
                Assigned to: {alert.assignedTo}
              </div>
            )}
          </div>

          {/* Update Status */}
          <div className="bg-white rounded-xl shadow-sm p-6">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">Update Status</h2>

            <div className="space-y-3">
              <button
                onClick={() => handleStatusUpdate('INVESTIGATING')}
                disabled={updateMutation.isPending || alert.status === 'INVESTIGATING'}
                className={cn(
                  'w-full flex items-center justify-center gap-2 px-4 py-2 rounded-lg font-medium transition-colors',
                  alert.status === 'INVESTIGATING'
                    ? 'bg-yellow-100 text-yellow-800 cursor-not-allowed'
                    : 'bg-yellow-500 text-white hover:bg-yellow-600'
                )}
              >
                <Clock className="h-4 w-4" />
                Mark Investigating
              </button>

              <button
                onClick={() => handleStatusUpdate('RESOLVED')}
                disabled={updateMutation.isPending || alert.status === 'RESOLVED'}
                className={cn(
                  'w-full flex items-center justify-center gap-2 px-4 py-2 rounded-lg font-medium transition-colors',
                  alert.status === 'RESOLVED'
                    ? 'bg-green-100 text-green-800 cursor-not-allowed'
                    : 'bg-green-500 text-white hover:bg-green-600'
                )}
              >
                <CheckCircle className="h-4 w-4" />
                Mark Resolved
              </button>

              <button
                onClick={() => handleStatusUpdate('FALSE_POSITIVE')}
                disabled={updateMutation.isPending || alert.status === 'FALSE_POSITIVE'}
                className={cn(
                  'w-full flex items-center justify-center gap-2 px-4 py-2 rounded-lg font-medium transition-colors',
                  alert.status === 'FALSE_POSITIVE'
                    ? 'bg-gray-100 text-gray-800 cursor-not-allowed'
                    : 'bg-gray-500 text-white hover:bg-gray-600'
                )}
              >
                <XCircle className="h-4 w-4" />
                False Positive
              </button>
            </div>
          </div>

          {/* Add Notes */}
          <div className="bg-white rounded-xl shadow-sm p-6">
            <h2 className="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
              <FileText className="h-5 w-5" />
              Investigation Notes
            </h2>

            {alert.notes && (
              <div className="mb-4 p-3 bg-gray-50 rounded-lg">
                <p className="text-sm text-gray-600">{alert.notes}</p>
              </div>
            )}

            <textarea
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder="Add investigation notes..."
              rows={4}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          {/* Response Actions */}
          <div className="bg-white rounded-xl shadow-sm p-6">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">Response Actions</h2>

            <div className="space-y-3">
              <button className="w-full px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 font-medium">
                Block A-Numbers
              </button>
              <button className="w-full px-4 py-2 bg-orange-600 text-white rounded-lg hover:bg-orange-700 font-medium">
                Disconnect Active Calls
              </button>
              <button className="w-full px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 font-medium">
                Generate Report
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
