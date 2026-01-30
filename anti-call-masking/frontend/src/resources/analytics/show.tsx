import { useState, useMemo } from 'react';
import {
  Card,
  Row,
  Col,
  Typography,
  Statistic,
  Select,
  DatePicker,
  Space,
  Empty,
  Table,
} from 'antd';
import {
  RiseOutlined,
  AlertOutlined,
  PhoneOutlined,
  SafetyCertificateOutlined,
} from '@ant-design/icons';
import { useQuery, useSubscription } from '@apollo/client';
import { Area, Pie, Column } from '@ant-design/charts';
import dayjs, { Dayjs } from 'dayjs';

import { UNRESOLVED_ALERTS_COUNT_SUBSCRIPTION } from '../../graphql/subscriptions';
import { GET_ALERTS_TIMELINE } from '../../graphql/queries';
import { ACM_COLORS } from '../../config/antd-theme';

const { Title, Text } = Typography;
const { RangePicker } = DatePicker;

type TimeRange = '1h' | '24h' | '7d' | '30d' | 'custom';

const timeRangeOptions = [
  { label: 'Last Hour', value: '1h' },
  { label: 'Last 24 Hours', value: '24h' },
  { label: 'Last 7 Days', value: '7d' },
  { label: 'Last 30 Days', value: '30d' },
  { label: 'Custom', value: 'custom' },
];

// Generate mock traffic data
const generateTrafficData = (hours: number) => {
  const data = [];
  const now = dayjs();

  for (let i = hours - 1; i >= 0; i--) {
    const time = now.subtract(i, 'hours');
    const baseTraffic = 800 + Math.random() * 400;

    data.push({
      time: time.format('HH:mm'),
      value: Math.floor(baseTraffic),
      type: 'Total Calls',
    });

    data.push({
      time: time.format('HH:mm'),
      value: Math.floor(baseTraffic * (0.02 + Math.random() * 0.03)),
      type: 'Masked Calls',
    });
  }

  return data;
};

// Generate mock carrier data
const generateCarrierData = () => [
  { carrier: 'MTN Nigeria', alerts: 145, percentage: 35 },
  { carrier: 'Airtel Nigeria', alerts: 98, percentage: 24 },
  { carrier: 'Glo Mobile', alerts: 87, percentage: 21 },
  { carrier: '9mobile', alerts: 54, percentage: 13 },
  { carrier: 'Other', alerts: 29, percentage: 7 },
];

export const AnalyticsPage: React.FC = () => {
  const [timeRange, setTimeRange] = useState<TimeRange>('24h');
  const [customRange, setCustomRange] = useState<[Dayjs, Dayjs] | null>(null);

  // Real-time alert counts
  const { data: alertCounts, loading: countsLoading } = useSubscription(
    UNRESOLVED_ALERTS_COUNT_SUBSCRIPTION
  );

  // Calculate date range based on selection
  const dateRange = useMemo(() => {
    const now = dayjs();
    switch (timeRange) {
      case '1h':
        return { start: now.subtract(1, 'hour'), end: now };
      case '24h':
        return { start: now.subtract(24, 'hours'), end: now };
      case '7d':
        return { start: now.subtract(7, 'days'), end: now };
      case '30d':
        return { start: now.subtract(30, 'days'), end: now };
      case 'custom':
        return customRange
          ? { start: customRange[0], end: customRange[1] }
          : { start: now.subtract(24, 'hours'), end: now };
      default:
        return { start: now.subtract(24, 'hours'), end: now };
    }
  }, [timeRange, customRange]);

  // Fetch alerts timeline
  const { data: alertsData, loading: alertsLoading } = useQuery(GET_ALERTS_TIMELINE, {
    variables: {
      start_date: dateRange.start.toISOString(),
      end_date: dateRange.end.toISOString(),
    },
  });

  // Mock data
  const trafficData = useMemo(() => generateTrafficData(24), []);
  const carrierData = useMemo(() => generateCarrierData(), []);

  // Process alerts for severity distribution
  const severityData = useMemo(() => {
    if (!alertsData?.acm_alerts) return [];

    const counts: Record<string, number> = { CRITICAL: 0, HIGH: 0, MEDIUM: 0, LOW: 0 };
    alertsData.acm_alerts.forEach((alert: { severity: string }) => {
      counts[alert.severity] = (counts[alert.severity] || 0) + 1;
    });

    return [
      { type: 'Critical', value: counts.CRITICAL, color: ACM_COLORS.critical },
      { type: 'High', value: counts.HIGH, color: ACM_COLORS.high },
      { type: 'Medium', value: counts.MEDIUM, color: ACM_COLORS.medium },
      { type: 'Low', value: counts.LOW, color: ACM_COLORS.low },
    ].filter((item) => item.value > 0);
  }, [alertsData]);

  // Stats
  const criticalCount = alertCounts?.critical_count?.aggregate?.count || 0;
  const totalAlerts = alertsData?.acm_alerts?.length || 0;

  // Chart configs
  const trafficChartConfig = {
    data: trafficData,
    xField: 'time',
    yField: 'value',
    seriesField: 'type',
    height: 300,
    color: [ACM_COLORS.primaryLight, ACM_COLORS.critical],
    smooth: true,
    areaStyle: { fillOpacity: 0.6 },
    legend: { position: 'bottom' as const },
  };

  const severityPieConfig = {
    data: severityData,
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
      style: { fontSize: 14, fill: '#fff' },
    },
    legend: { position: 'bottom' as const },
    statistic: {
      title: { content: 'Total' },
      content: { style: { fontSize: '20px' } },
    },
  };

  const carrierColumnConfig = {
    data: carrierData,
    xField: 'carrier',
    yField: 'alerts',
    height: 250,
    color: ACM_COLORS.primary,
    label: {
      position: 'top' as const,
      style: { fill: '#666', fontSize: 12 },
    },
    xAxis: {
      label: {
        autoRotate: true,
        style: { fontSize: 10 },
      },
    },
  };

  return (
    <div className="acm-fade-in">
      <div className="acm-page-header" style={{ marginBottom: 24 }}>
        <Row justify="space-between" align="middle">
          <Col>
            <Title level={3} style={{ marginBottom: 4 }}>
              Analytics
            </Title>
            <Text type="secondary">
              Call masking detection analytics and traffic insights
            </Text>
          </Col>
          <Col>
            <Space>
              <Select
                value={timeRange}
                onChange={(value) => setTimeRange(value as TimeRange)}
                options={timeRangeOptions}
                style={{ width: 150 }}
              />
              {timeRange === 'custom' && (
                <RangePicker
                  value={customRange}
                  onChange={(dates) =>
                    setCustomRange(dates as [Dayjs, Dayjs])
                  }
                />
              )}
            </Space>
          </Col>
        </Row>
      </div>

      {/* Stats Cards */}
      <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
        <Col xs={12} sm={6}>
          <Card bordered={false} className="acm-stats-card">
            <Statistic
              title="Total Alerts"
              value={totalAlerts}
              loading={alertsLoading}
              prefix={<AlertOutlined style={{ color: ACM_COLORS.primary }} />}
            />
          </Card>
        </Col>
        <Col xs={12} sm={6}>
          <Card bordered={false} className="acm-stats-card">
            <Statistic
              title="Critical"
              value={criticalCount}
              loading={countsLoading}
              valueStyle={{ color: criticalCount > 0 ? ACM_COLORS.critical : undefined }}
              prefix={<SafetyCertificateOutlined style={{ color: ACM_COLORS.critical }} />}
            />
          </Card>
        </Col>
        <Col xs={12} sm={6}>
          <Card bordered={false} className="acm-stats-card">
            <Statistic
              title="Detection Rate"
              value={2.8}
              suffix="%"
              prefix={<RiseOutlined style={{ color: ACM_COLORS.success }} />}
            />
          </Card>
        </Col>
        <Col xs={12} sm={6}>
          <Card bordered={false} className="acm-stats-card">
            <Statistic
              title="Avg Response Time"
              value={4.2}
              suffix="min"
              prefix={<PhoneOutlined style={{ color: ACM_COLORS.info }} />}
            />
          </Card>
        </Col>
      </Row>

      {/* Charts */}
      <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
        <Col xs={24} lg={16}>
          <Card title="Traffic Overview" bordered={false}>
            <Area {...trafficChartConfig} />
          </Card>
        </Col>
        <Col xs={24} lg={8}>
          <Card title="Alerts by Severity" bordered={false}>
            {severityData.length > 0 ? (
              <Pie {...severityPieConfig} />
            ) : (
              <Empty description="No alerts in selected period" />
            )}
          </Card>
        </Col>
      </Row>

      <Row gutter={[16, 16]}>
        <Col xs={24} lg={12}>
          <Card title="Alerts by Carrier" bordered={false}>
            <Column {...carrierColumnConfig} />
          </Card>
        </Col>
        <Col xs={24} lg={12}>
          <Card title="Top Targeted Numbers" bordered={false}>
            <Table
              dataSource={[
                { key: 1, number: '+234 812 345 6789', alerts: 23, carrier: 'MTN' },
                { key: 2, number: '+234 803 456 7890', alerts: 18, carrier: 'Airtel' },
                { key: 3, number: '+234 705 567 8901', alerts: 15, carrier: 'Glo' },
                { key: 4, number: '+234 809 678 9012', alerts: 12, carrier: '9mobile' },
                { key: 5, number: '+234 811 789 0123', alerts: 9, carrier: 'MTN' },
              ]}
              columns={[
                { title: 'Number', dataIndex: 'number', key: 'number' },
                { title: 'Alerts', dataIndex: 'alerts', key: 'alerts', width: 80 },
                { title: 'Carrier', dataIndex: 'carrier', key: 'carrier', width: 100 },
              ]}
              pagination={false}
              size="small"
            />
          </Card>
        </Col>
      </Row>
    </div>
  );
};

export default AnalyticsPage;
