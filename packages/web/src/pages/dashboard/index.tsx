import { Row, Col, Card, Statistic, Typography, Space, Table, Tag, Badge, Button, Tooltip } from 'antd';
import {
  AlertOutlined,
  CheckCircleOutlined,
  ExclamationCircleOutlined,
  ClockCircleOutlined,
  LineChartOutlined,
  DatabaseOutlined,
  PhoneOutlined,
  AppstoreOutlined,
  ExportOutlined,
} from '@ant-design/icons';
import { useSubscription, useQuery } from '@apollo/client';
import { Link } from 'react-router-dom';
import dayjs from 'dayjs';
import relativeTime from 'dayjs/plugin/relativeTime';

import { UNRESOLVED_ALERTS_COUNT_SUBSCRIPTION } from '../../graphql/subscriptions';
import { GET_RECENT_ALERTS } from '../../graphql/queries';
import { VG_COLORS, severityColors, statusColors } from '../../config/antd-theme';
import { EXTERNAL_SERVICES, generateDeepLink } from '../../config/external-services';
import { AlertsTrendChart } from './components/AlertsTrendChart';
import { SeverityPieChart } from './components/SeverityPieChart';
import { TrafficAreaChart } from './components/TrafficAreaChart';

// Quick access external links for dashboard
const quickLinks = [
  {
    key: 'grafana',
    label: 'Grafana',
    icon: <LineChartOutlined />,
    url: 'http://localhost:3003',
    color: VG_COLORS.primary,
  },
  {
    key: 'prometheus',
    label: 'Prometheus',
    icon: <ExclamationCircleOutlined />,
    url: 'http://localhost:9091',
    color: VG_COLORS.warning,
  },
  {
    key: 'questdb',
    label: 'QuestDB',
    icon: <DatabaseOutlined />,
    url: 'http://localhost:9002',
    color: VG_COLORS.success,
  },
  {
    key: 'clickhouse',
    label: 'ClickHouse',
    icon: <DatabaseOutlined />,
    url: 'http://localhost:8123/play',
    color: VG_COLORS.info,
  },
  {
    key: 'yugabyte',
    label: 'YugabyteDB',
    icon: <DatabaseOutlined />,
    url: 'http://localhost:9005',
    color: VG_COLORS.medium,
  },
  {
    key: 'homer',
    label: 'Homer SIP',
    icon: <PhoneOutlined />,
    url: 'http://localhost:9080',
    color: VG_COLORS.high,
  },
];

dayjs.extend(relativeTime);

const { Title, Text } = Typography;

interface Alert {
  id: string;
  b_number: string;
  a_number: string;
  severity: string;
  status: string;
  threat_score: number;
  carrier_name: string;
  created_at: string;
}

export const DashboardPage: React.FC = () => {
  // Real-time alert counts
  const { data: alertCounts, loading: countsLoading } = useSubscription(
    UNRESOLVED_ALERTS_COUNT_SUBSCRIPTION
  );

  // Recent alerts
  const { data: recentAlertsData, loading: alertsLoading } = useQuery(GET_RECENT_ALERTS, {
    variables: { limit: 10 },
    pollInterval: 10000, // Poll every 10 seconds
  });

  const newCount = alertCounts?.new_count?.aggregate?.count || 0;
  const investigatingCount = alertCounts?.investigating_count?.aggregate?.count || 0;
  const confirmedCount = alertCounts?.confirmed_count?.aggregate?.count || 0;
  const criticalCount = alertCounts?.critical_count?.aggregate?.count || 0;
  const recentAlerts: Alert[] = recentAlertsData?.acm_alerts || [];

  const alertColumns = [
    {
      title: 'Time',
      dataIndex: 'created_at',
      key: 'created_at',
      width: 100,
      render: (date: string) => (
        <Text type="secondary" style={{ fontSize: 12 }}>
          {dayjs(date).fromNow()}
        </Text>
      ),
    },
    {
      title: 'B-Number',
      dataIndex: 'b_number',
      key: 'b_number',
      render: (text: string, record: Alert) => (
        <Link to={`/alerts/show/${record.id}`}>
          <Text strong>{text}</Text>
        </Link>
      ),
    },
    {
      title: 'Severity',
      dataIndex: 'severity',
      key: 'severity',
      width: 100,
      render: (severity: string) => {
        const colors = severityColors[severity] || severityColors.LOW;
        return (
          <Tag
            style={{
              backgroundColor: colors.background,
              color: colors.color,
              border: 'none',
            }}
          >
            {severity}
          </Tag>
        );
      },
    },
    {
      title: 'Status',
      dataIndex: 'status',
      key: 'status',
      width: 120,
      render: (status: string) => {
        const colors = statusColors[status] || statusColors.NEW;
        return (
          <Tag
            style={{
              backgroundColor: colors.background,
              color: colors.color,
              border: 'none',
            }}
          >
            {status.replace('_', ' ')}
          </Tag>
        );
      },
    },
    {
      title: 'Score',
      dataIndex: 'threat_score',
      key: 'threat_score',
      width: 80,
      render: (score: number) => (
        <Text
          style={{
            color: score >= 80 ? VG_COLORS.critical : score >= 60 ? VG_COLORS.high : VG_COLORS.medium,
            fontWeight: 600,
          }}
        >
          {score}%
        </Text>
      ),
    },
  ];

  return (
    <div className="acm-fade-in">
      <div className="acm-page-header">
        <Title level={3} style={{ marginBottom: 4 }}>
          Dashboard
        </Title>
        <Text type="secondary">Real-time monitoring of call masking detection</Text>
      </div>

      {/* Stats Cards */}
      <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
        <Col xs={24} sm={12} lg={6}>
          <Card className="acm-stats-card" bordered={false}>
            <Statistic
              title="New Alerts"
              value={newCount}
              loading={countsLoading}
              prefix={<AlertOutlined style={{ color: VG_COLORS.info }} />}
              valueStyle={{ color: VG_COLORS.info }}
            />
          </Card>
        </Col>

        <Col xs={24} sm={12} lg={6}>
          <Card className="acm-stats-card" bordered={false}>
            <Statistic
              title="Critical Alerts"
              value={criticalCount}
              loading={countsLoading}
              prefix={<ExclamationCircleOutlined style={{ color: VG_COLORS.critical }} />}
              valueStyle={{ color: VG_COLORS.critical }}
              suffix={
                criticalCount > 0 && (
                  <Badge status="processing" style={{ marginLeft: 8 }} />
                )
              }
            />
          </Card>
        </Col>

        <Col xs={24} sm={12} lg={6}>
          <Card className="acm-stats-card" bordered={false}>
            <Statistic
              title="Investigating"
              value={investigatingCount}
              loading={countsLoading}
              prefix={<ClockCircleOutlined style={{ color: VG_COLORS.warning }} />}
              valueStyle={{ color: VG_COLORS.warning }}
            />
          </Card>
        </Col>

        <Col xs={24} sm={12} lg={6}>
          <Card className="acm-stats-card" bordered={false}>
            <Statistic
              title="Confirmed"
              value={confirmedCount}
              loading={countsLoading}
              prefix={<CheckCircleOutlined style={{ color: VG_COLORS.error }} />}
              valueStyle={{ color: VG_COLORS.error }}
            />
          </Card>
        </Col>
      </Row>

      {/* Quick Access Links */}
      <Card
        size="small"
        bordered={false}
        style={{ marginBottom: 24 }}
        bodyStyle={{ padding: '12px 16px' }}
      >
        <Space size="middle" wrap>
          <Text type="secondary" style={{ fontSize: 12 }}>
            <AppstoreOutlined /> Quick Access:
          </Text>
          {quickLinks.map((link) => (
            <Tooltip key={link.key} title={`Open ${link.label} in new tab`}>
              <Button
                size="small"
                icon={link.icon}
                onClick={() => window.open(link.url, '_blank')}
                style={{ borderColor: link.color, color: link.color }}
              >
                {link.label} <ExportOutlined style={{ fontSize: 10 }} />
              </Button>
            </Tooltip>
          ))}
        </Space>
      </Card>

      {/* Charts Row */}
      <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
        <Col xs={24} lg={16}>
          <Card
            title="Alert Trends (24h)"
            bordered={false}
            extra={
              <Space>
                <Badge color={VG_COLORS.critical} text="Critical" />
                <Badge color={VG_COLORS.high} text="High" />
                <Badge color={VG_COLORS.medium} text="Medium" />
              </Space>
            }
          >
            <AlertsTrendChart />
          </Card>
        </Col>

        <Col xs={24} lg={8}>
          <Card title="Alerts by Severity" bordered={false}>
            <SeverityPieChart />
          </Card>
        </Col>
      </Row>

      {/* Traffic and Recent Alerts */}
      <Row gutter={[16, 16]}>
        <Col xs={24} lg={12}>
          <Card title="Traffic Overview" bordered={false}>
            <TrafficAreaChart />
          </Card>
        </Col>

        <Col xs={24} lg={12}>
          <Card
            title="Recent Alerts"
            bordered={false}
            extra={
              <Link to="/alerts">
                <Text type="secondary" style={{ fontSize: 12 }}>
                  View All &rarr;
                </Text>
              </Link>
            }
          >
            <Table
              dataSource={recentAlerts}
              columns={alertColumns}
              rowKey="id"
              pagination={false}
              size="small"
              loading={alertsLoading}
              scroll={{ x: true }}
            />
          </Card>
        </Col>
      </Row>
    </div>
  );
};

export default DashboardPage;
