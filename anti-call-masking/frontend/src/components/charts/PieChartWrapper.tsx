import { Pie } from '@ant-design/charts';
import { Empty, Spin } from 'antd';
import { ACM_COLORS } from '../../config/antd-theme';

interface DataPoint {
  type: string;
  value: number;
  [key: string]: string | number;
}

interface PieChartWrapperProps {
  data: DataPoint[];
  angleField?: string;
  colorField?: string;
  height?: number;
  loading?: boolean;
  colors?: string[];
  showLegend?: boolean;
  innerRadius?: number;
  showStatistic?: boolean;
  statisticTitle?: string;
  emptyMessage?: string;
}

export const PieChartWrapper: React.FC<PieChartWrapperProps> = ({
  data,
  angleField = 'value',
  colorField = 'type',
  height = 250,
  loading = false,
  colors,
  showLegend = true,
  innerRadius = 0.6,
  showStatistic = true,
  statisticTitle = 'Total',
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
    angleField,
    colorField,
    radius: 0.8,
    innerRadius,
    height,
    color: colors || [
      ACM_COLORS.critical,
      ACM_COLORS.high,
      ACM_COLORS.medium,
      ACM_COLORS.low,
      ACM_COLORS.primary,
    ],
    label: {
      type: 'inner',
      offset: '-50%',
      content: '{value}',
      style: {
        fontSize: 14,
        fill: '#fff',
      },
    },
    legend: showLegend
      ? {
          position: 'bottom' as const,
        }
      : false,
    statistic: showStatistic
      ? {
          title: {
            content: statisticTitle,
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
        }
      : undefined,
    interactions: [{ type: 'element-active' }, { type: 'pie-statistic-active' }],
    animation: {
      appear: {
        animation: 'fade-in',
        duration: 800,
      },
    },
  };

  return <Pie {...config} />;
};

export default PieChartWrapper;
