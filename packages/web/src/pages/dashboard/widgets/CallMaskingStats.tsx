import { useEffect, useState } from 'react';
import { Area, AreaConfig } from '@ant-design/charts';
import { Segmented, Space, Spin, Empty } from 'antd';
import { useCustom } from '@refinedev/core';

interface CallDataPoint {
    time: string;
    value: number;
    type: 'Total Calls' | 'Flagged' | 'Blocked';
}

const CALLS_TIMESERIES_QUERY = `
  query CallsTimeseries($interval: String!) {
    calls_by_hour: call_verifications_aggregate(
      where: { created_at: { _gte: "now() - interval '24 hours'" } }
    ) {
      nodes {
        created_at
        is_flagged
        status
      }
    }
  }
`;

export const CallMaskingStats: React.FC = () => {
    const [timeRange, setTimeRange] = useState<string>('24h');
    const [chartData, setChartData] = useState<CallDataPoint[]>([]);

    const { data, isLoading } = useCustom({
        url: '',
        method: 'get',
        meta: {
            gqlQuery: CALLS_TIMESERIES_QUERY,
            variables: { interval: timeRange },
        },
    });

    useEffect(() => {
        if (data?.data) {
            // Process data into time buckets
            const nodes = (data.data as any)?.calls_by_hour?.nodes || [];
            const hourlyData: Record<string, { total: number; flagged: number; blocked: number }> = {};

            nodes.forEach((call: any) => {
                const hour = new Date(call.created_at).toISOString().slice(0, 13) + ':00';
                if (!hourlyData[hour]) {
                    hourlyData[hour] = { total: 0, flagged: 0, blocked: 0 };
                }
                hourlyData[hour].total++;
                if (call.is_flagged) hourlyData[hour].flagged++;
                if (call.status === 'BLOCKED') hourlyData[hour].blocked++;
            });

            const formattedData: CallDataPoint[] = [];
            Object.entries(hourlyData)
                .sort(([a], [b]) => a.localeCompare(b))
                .forEach(([time, counts]) => {
                    const displayTime = new Date(time).toLocaleTimeString('en-US', {
                        hour: '2-digit',
                        minute: '2-digit',
                    });
                    formattedData.push({ time: displayTime, value: counts.total, type: 'Total Calls' });
                    formattedData.push({ time: displayTime, value: counts.flagged, type: 'Flagged' });
                    formattedData.push({ time: displayTime, value: counts.blocked, type: 'Blocked' });
                });

            setChartData(formattedData);
        }
    }, [data]);

    if (isLoading) {
        return (
            <div style={{ height: 300, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Spin />
            </div>
        );
    }

    if (chartData.length === 0) {
        return <Empty description="No call data available" />;
    }

    const config: AreaConfig = {
        data: chartData,
        xField: 'time',
        yField: 'value',
        seriesField: 'type',
        smooth: true,
        height: 300,
        color: ['#1890ff', '#faad14', '#ff4d4f'],
        areaStyle: (datum: CallDataPoint) => {
            if (datum.type === 'Total Calls') return { fillOpacity: 0.3 };
            return { fillOpacity: 0.5 };
        },
        legend: {
            position: 'top-right',
        },
        tooltip: {
            shared: true,
        },
    };

    return (
        <Space direction="vertical" style={{ width: '100%' }}>
            <Segmented
                options={[
                    { label: '1h', value: '1h' },
                    { label: '6h', value: '6h' },
                    { label: '24h', value: '24h' },
                    { label: '7d', value: '7d' },
                ]}
                value={timeRange}
                onChange={(val) => setTimeRange(val as string)}
            />
            <Area {...config} />
        </Space>
    );
};

export default CallMaskingStats;
