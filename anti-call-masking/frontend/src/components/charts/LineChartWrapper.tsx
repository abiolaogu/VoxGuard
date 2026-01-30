import { Line } from '@ant-design/charts';
import { Empty, Spin } from 'antd';
import { ACM_COLORS } from '../../config/antd-theme';

interface DataPoint {
  [key: string]: string | number;
}

interface LineChartWrapperProps {
  data: DataPoint[];
  xField: string;
  yField: string;
  seriesField?: string;
  height?: number;
  loading?: boolean;
  smooth?: boolean;
  colors?: string[];
  showLegend?: boolean;
  emptyMessage?: string;
}

export const LineChartWrapper: React.FC<LineChartWrapperProps> = ({
  data,
  xField,
  yField,
  seriesField,
  height = 300,
  loading = false,
  smooth = true,
  colors,
  showLegend = true,
  emptyMessage = 'No data available',
}) => {
  if (loading) {
    return (
      <div
        style={{
          height,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
        }}
      >
        <Spin />
      </div>
    );
  }

  if (!data || data.length === 0) {
    return (
      <div
        style={{
          height,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
        }}
      >
        <Empty description={emptyMessage} />
      </div>
    );
  }

  const config = {
    data,
    xField,
    yField,
    seriesField,
    smooth,
    height,
    color: colors || [
      ACM_COLORS.primary,
      ACM_COLORS.secondary,
      ACM_COLORS.accent,
      ACM_COLORS.success,
    ],
    legend: showLegend
      ? {
          position: 'bottom' as const,
        }
      : false,
    xAxis: {
      label: {
        autoRotate: true,
        style: {
          fontSize: 10,
        },
      },
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

export default LineChartWrapper;
