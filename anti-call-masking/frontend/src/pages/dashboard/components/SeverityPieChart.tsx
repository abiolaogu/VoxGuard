import { useMemo } from 'react';
import { Pie } from '@ant-design/charts';
import { useSubscription } from '@apollo/client';
import { Spin, Empty } from 'antd';
import { UNRESOLVED_ALERTS_COUNT_SUBSCRIPTION } from '../../../graphql/subscriptions';
import { ACM_COLORS } from '../../../config/antd-theme';

export const SeverityPieChart: React.FC = () => {
  const { data, loading, error } = useSubscription(UNRESOLVED_ALERTS_COUNT_SUBSCRIPTION);

  const chartData = useMemo(() => {
    if (!data) return [];

    return [
      {
        type: 'Critical',
        value: data.critical_count?.aggregate?.count || 0,
        color: ACM_COLORS.critical,
      },
      {
        type: 'High',
        value: Math.max(0, (data.new_count?.aggregate?.count || 0) - (data.critical_count?.aggregate?.count || 0)),
        color: ACM_COLORS.high,
      },
      {
        type: 'Medium',
        value: data.investigating_count?.aggregate?.count || 0,
        color: ACM_COLORS.medium,
      },
      {
        type: 'Low',
        value: data.confirmed_count?.aggregate?.count || 0,
        color: ACM_COLORS.low,
      },
    ].filter((item) => item.value > 0);
  }, [data]);

  if (loading) {
    return (
      <div style={{ height: 250, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <Spin />
      </div>
    );
  }

  if (error || chartData.length === 0) {
    return (
      <div style={{ height: 250, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <Empty description="No alerts" />
      </div>
    );
  }

  const config = {
    data: chartData,
    angleField: 'value',
    colorField: 'type',
    radius: 0.8,
    innerRadius: 0.6,
    height: 250,
    color: [ACM_COLORS.critical, ACM_COLORS.high, ACM_COLORS.medium, ACM_COLORS.low],
    label: {
      type: 'inner',
      offset: '-50%',
      content: '{value}',
      style: {
        textAlign: 'center',
        fontSize: 14,
        fill: '#fff',
      },
    },
    legend: {
      position: 'bottom' as const,
    },
    statistic: {
      title: {
        content: 'Total',
        style: {
          fontSize: '14px',
        },
      },
      content: {
        style: {
          fontSize: '24px',
          fontWeight: 'bold',
        },
      },
    },
    interactions: [
      { type: 'element-active' },
      { type: 'pie-statistic-active' },
    ],
    animation: {
      appear: {
        animation: 'fade-in',
        duration: 800,
      },
    },
  };

  return <Pie {...config} />;
};

export default SeverityPieChart;
