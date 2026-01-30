import { useMemo } from 'react';
import { Line } from '@ant-design/charts';
import { useQuery } from '@apollo/client';
import { Spin, Empty } from 'antd';
import dayjs from 'dayjs';
import { GET_ALERTS_TIMELINE } from '../../../graphql/queries';
import { ACM_COLORS } from '../../../config/antd-theme';

export const AlertsTrendChart: React.FC = () => {
  const startDate = dayjs().subtract(24, 'hours').toISOString();
  const endDate = dayjs().toISOString();

  const { data, loading, error } = useQuery(GET_ALERTS_TIMELINE, {
    variables: {
      start_date: startDate,
      end_date: endDate,
    },
    pollInterval: 60000, // Poll every minute
  });

  // Process data for chart
  const chartData = useMemo(() => {
    if (!data?.acm_alerts) return [];

    // Group by hour and severity
    const grouped: Record<string, Record<string, number>> = {};

    data.acm_alerts.forEach((alert: { severity: string; created_at: string }) => {
      const hour = dayjs(alert.created_at).format('HH:00');

      if (!grouped[hour]) {
        grouped[hour] = { CRITICAL: 0, HIGH: 0, MEDIUM: 0, LOW: 0 };
      }

      grouped[hour][alert.severity] = (grouped[hour][alert.severity] || 0) + 1;
    });

    // Convert to chart format
    const result: { hour: string; count: number; severity: string }[] = [];

    // Fill in all hours
    for (let i = 23; i >= 0; i--) {
      const hour = dayjs().subtract(i, 'hours').format('HH:00');
      const hourData = grouped[hour] || { CRITICAL: 0, HIGH: 0, MEDIUM: 0, LOW: 0 };

      ['CRITICAL', 'HIGH', 'MEDIUM', 'LOW'].forEach((severity) => {
        result.push({
          hour,
          count: hourData[severity] || 0,
          severity,
        });
      });
    }

    return result;
  }, [data]);

  if (loading) {
    return (
      <div style={{ height: 300, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <Spin />
      </div>
    );
  }

  if (error || chartData.length === 0) {
    return (
      <div style={{ height: 300, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <Empty description="No data available" />
      </div>
    );
  }

  const config = {
    data: chartData,
    xField: 'hour',
    yField: 'count',
    seriesField: 'severity',
    smooth: true,
    height: 300,
    color: [ACM_COLORS.critical, ACM_COLORS.high, ACM_COLORS.medium, ACM_COLORS.low],
    legend: {
      position: 'bottom' as const,
    },
    xAxis: {
      label: {
        autoRotate: true,
        style: {
          fontSize: 10,
        },
      },
    },
    yAxis: {
      label: {
        formatter: (v: string) => `${v}`,
      },
    },
    tooltip: {
      shared: true,
      showMarkers: true,
    },
    animation: {
      appear: {
        animation: 'path-in',
        duration: 1000,
      },
    },
  };

  return <Line {...config} />;
};

export default AlertsTrendChart;
