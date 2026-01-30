import { Area } from '@ant-design/charts';
import { Empty, Spin } from 'antd';
import { VG_COLORS } from '../../config/antd-theme';

interface DataPoint {
  [key: string]: string | number;
}

interface AreaChartWrapperProps {
  data: DataPoint[];
  xField: string;
  yField: string;
  seriesField?: string;
  height?: number;
  loading?: boolean;
  smooth?: boolean;
  colors?: string[];
  showLegend?: boolean;
  fillOpacity?: number;
  emptyMessage?: string;
}

export const AreaChartWrapper: React.FC<AreaChartWrapperProps> = ({
  data,
  xField,
  yField,
  seriesField,
  height = 300,
  loading = false,
  smooth = true,
  colors,
  showLegend = true,
  fillOpacity = 0.6,
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
    color: colors || [VG_COLORS.primaryLight, VG_COLORS.critical],
    areaStyle: {
      fillOpacity,
    },
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
        animation: 'wave-in',
        duration: 1000,
      },
    },
  };

  return <Area {...config} />;
};

export default AreaChartWrapper;
