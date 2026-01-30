import { Column } from '@ant-design/charts';
import { Empty, Spin } from 'antd';
import { ACM_COLORS } from '../../config/antd-theme';

interface DataPoint {
  [key: string]: string | number;
}

interface ColumnChartWrapperProps {
  data: DataPoint[];
  xField: string;
  yField: string;
  seriesField?: string;
  height?: number;
  loading?: boolean;
  colors?: string | string[];
  showLegend?: boolean;
  showLabel?: boolean;
  isGroup?: boolean;
  isStack?: boolean;
  emptyMessage?: string;
}

export const ColumnChartWrapper: React.FC<ColumnChartWrapperProps> = ({
  data,
  xField,
  yField,
  seriesField,
  height = 250,
  loading = false,
  colors,
  showLegend = false,
  showLabel = true,
  isGroup = false,
  isStack = false,
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
    isGroup,
    isStack,
    height,
    color: colors || ACM_COLORS.primary,
    label: showLabel
      ? {
          position: 'top' as const,
          style: {
            fill: '#666',
            fontSize: 12,
          },
        }
      : undefined,
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
        animation: 'scale-in-y',
        duration: 800,
      },
    },
  };

  return <Column {...config} />;
};

export default ColumnChartWrapper;
