import { useMemo } from 'react';
import { Area } from '@ant-design/charts';
import { Empty } from 'antd';
import dayjs from 'dayjs';
import { ACM_COLORS } from '../../../config/antd-theme';

// Mock data for traffic visualization
// In production, this would come from QuestDB via Hasura action
const generateMockTrafficData = () => {
  const data = [];
  const now = dayjs();

  for (let i = 23; i >= 0; i--) {
    const hour = now.subtract(i, 'hours').format('HH:00');
    const baseTraffic = 1000 + Math.random() * 500;
    const maskedCalls = Math.floor(baseTraffic * (0.02 + Math.random() * 0.03));

    data.push({
      hour,
      value: Math.floor(baseTraffic),
      type: 'Total Calls',
    });

    data.push({
      hour,
      value: maskedCalls,
      type: 'Masked Calls',
    });
  }

  return data;
};

export const TrafficAreaChart: React.FC = () => {
  const chartData = useMemo(() => generateMockTrafficData(), []);

  if (chartData.length === 0) {
    return (
      <div style={{ height: 250, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <Empty description="No traffic data" />
      </div>
    );
  }

  const config = {
    data: chartData,
    xField: 'hour',
    yField: 'value',
    seriesField: 'type',
    height: 250,
    color: [ACM_COLORS.primaryLight, ACM_COLORS.critical],
    areaStyle: {
      fillOpacity: 0.6,
    },
    smooth: true,
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
        formatter: (v: string) => {
          const num = Number(v);
          return num >= 1000 ? `${(num / 1000).toFixed(1)}k` : v;
        },
      },
    },
    tooltip: {
      shared: true,
      showMarkers: true,
      formatter: (datum: { type: string; value: number }) => ({
        name: datum.type,
        value: datum.value.toLocaleString(),
      }),
    },
    animation: {
      appear: {
        animation: 'wave-in',
        duration: 1000,
      },
    },
  };

  return <Area {...config} />;
};

export default TrafficAreaChart;
