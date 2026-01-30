import { useState, useEffect, useCallback, useRef } from 'react';
import { useSubscription } from '@apollo/client';
import { notification } from 'antd';
import { ALERTS_SUBSCRIPTION, CRITICAL_ALERTS_SUBSCRIPTION } from '../graphql/subscriptions';

interface Alert {
  id: string;
  b_number: string;
  a_number: string;
  severity: string;
  status: string;
  threat_score: number;
  detection_type: string;
  carrier_name: string;
  created_at: string;
  updated_at: string;
}

interface UseRealTimeAlertsOptions {
  enableNotifications?: boolean;
  enableSound?: boolean;
  severityFilter?: string[];
  statusFilter?: string[];
  limit?: number;
}

export function useRealTimeAlerts(options: UseRealTimeAlertsOptions = {}) {
  const {
    enableNotifications = true,
    enableSound = true,
    severityFilter,
    statusFilter,
    limit = 100,
  } = options;

  const [alerts, setAlerts] = useState<Alert[]>([]);
  const previousAlertsRef = useRef<Set<string>>(new Set());
  const audioRef = useRef<HTMLAudioElement | null>(null);

  // Build where clause for subscription
  const buildWhereClause = () => {
    const conditions: Record<string, unknown>[] = [];

    if (severityFilter?.length) {
      conditions.push({ severity: { _in: severityFilter } });
    }

    if (statusFilter?.length) {
      conditions.push({ status: { _in: statusFilter } });
    }

    return conditions.length > 0 ? { _and: conditions } : undefined;
  };

  // Subscribe to alerts
  const { data, loading, error } = useSubscription(ALERTS_SUBSCRIPTION, {
    variables: {
      where: buildWhereClause(),
      limit,
    },
  });

  // Subscribe to critical alerts for special notifications
  const { data: criticalData } = useSubscription(CRITICAL_ALERTS_SUBSCRIPTION);

  // Play notification sound
  const playSound = useCallback(() => {
    if (!enableSound) return;

    if (!audioRef.current) {
      audioRef.current = new Audio('/sounds/alert.mp3');
      audioRef.current.volume = 0.5;
    }

    audioRef.current.play().catch((err) => {
      console.warn('Could not play notification sound:', err);
    });
  }, [enableSound]);

  // Show notification for new alerts
  const showNotification = useCallback(
    (alert: Alert) => {
      if (!enableNotifications) return;

      const severityColors: Record<string, string> = {
        CRITICAL: '#DC3545',
        HIGH: '#E67E22',
        MEDIUM: '#FFC107',
        LOW: '#17A2B8',
      };

      notification.open({
        message: `New ${alert.severity} Alert`,
        description: `B-Number: ${alert.b_number}\nDetection: ${alert.detection_type}`,
        duration: alert.severity === 'CRITICAL' ? 0 : 5, // Critical alerts stay until dismissed
        style: {
          borderLeft: `4px solid ${severityColors[alert.severity] || '#17A2B8'}`,
        },
      });

      if (alert.severity === 'CRITICAL') {
        playSound();
      }
    },
    [enableNotifications, playSound]
  );

  // Handle new alerts
  useEffect(() => {
    if (!data?.acm_alerts) return;

    const newAlerts: Alert[] = data.acm_alerts;

    // Find truly new alerts (not seen before)
    const newAlertIds = new Set(newAlerts.map((a) => a.id));
    const previousIds = previousAlertsRef.current;

    newAlerts.forEach((alert) => {
      if (!previousIds.has(alert.id)) {
        // This is a new alert
        if (previousIds.size > 0) {
          // Only notify if not initial load
          showNotification(alert);
        }
      }
    });

    // Update previous alerts ref
    previousAlertsRef.current = newAlertIds;

    // Update state
    setAlerts(newAlerts);
  }, [data, showNotification]);

  // Get counts by severity
  const countsBySeverity = alerts.reduce(
    (acc, alert) => {
      acc[alert.severity] = (acc[alert.severity] || 0) + 1;
      return acc;
    },
    {} as Record<string, number>
  );

  // Get counts by status
  const countsByStatus = alerts.reduce(
    (acc, alert) => {
      acc[alert.status] = (acc[alert.status] || 0) + 1;
      return acc;
    },
    {} as Record<string, number>
  );

  return {
    alerts,
    loading,
    error,
    criticalAlerts: criticalData?.acm_alerts || [],
    countsBySeverity,
    countsByStatus,
    totalCount: alerts.length,
    criticalCount: countsBySeverity.CRITICAL || 0,
  };
}

export default useRealTimeAlerts;
