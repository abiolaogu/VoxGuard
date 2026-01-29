import { Row, Col, Card, Statistic, Typography, Space, Tag } from 'antd';
import {
    AlertOutlined,
    PhoneOutlined,
    WarningOutlined,
    CheckCircleOutlined,
    ArrowUpOutlined,
    ArrowDownOutlined,
} from '@ant-design/icons';
import { useCustom, useSubscription } from '@refinedev/core';

import { CallMaskingStats } from './widgets/CallMaskingStats';
import { FraudAlertsFeed } from './widgets/FraudAlertsFeed';
import { GatewayHealthGrid } from './widgets/GatewayHealthGrid';
import { RemittanceVolume } from './widgets/RemittanceVolume';
import { MarketplaceActivity } from './widgets/MarketplaceActivity';

import type { DashboardSummary } from '@/types';

const { Title, Text } = Typography;

const DASHBOARD_SUMMARY_QUERY = `
  query DashboardSummary {
    call_verifications_aggregate(where: { created_at: { _gte: "now() - interval '24 hours'" } }) {
      aggregate { count }
    }
    fraud_alerts_aggregate(where: { detected_at: { _gte: "now() - interval '24 hours'" } }) {
      aggregate { count }
    }
    pending_alerts: fraud_alerts_aggregate(where: { status: { _eq: "PENDING" } }) {
      aggregate { count }
    }
    critical_alerts: fraud_alerts_aggregate(where: { severity: { _eq: "CRITICAL" }, status: { _eq: "PENDING" } }) {
      aggregate { count }
    }
    resolved_alerts: fraud_alerts_aggregate(where: { status: { _eq: "RESOLVED" }, resolved_at: { _gte: "now() - interval '24 hours'" } }) {
      aggregate { count }
    }
  }
`;

export const Dashboard: React.FC = () => {
    const { data, isLoading, refetch } = useCustom<DashboardSummary>({
        url: '',
        method: 'get',
        meta: {
            gqlQuery: DASHBOARD_SUMMARY_QUERY,
        },
    });

    // Real-time subscription for new alerts
    useSubscription({
        channel: 'fraud_alerts',
        onLiveEvent: () => {
            refetch();
        },
    });

    const summary = data?.data;
    const totalCalls = (summary as any)?.call_verifications_aggregate?.aggregate?.count ?? 0;
    const totalAlerts = (summary as any)?.fraud_alerts_aggregate?.aggregate?.count ?? 0;
    const pendingAlerts = (summary as any)?.pending_alerts?.aggregate?.count ?? 0;
    const criticalAlerts = (summary as any)?.critical_alerts?.aggregate?.count ?? 0;
    const resolvedAlerts = (summary as any)?.resolved_alerts?.aggregate?.count ?? 0;

    const fraudRate = totalCalls > 0 ? ((totalAlerts / totalCalls) * 100).toFixed(2) : '0.00';

    return (
        <div style={{ padding: 24 }}>
            <Space direction="vertical" size="large" style={{ width: '100%' }}>
                {/* Header */}
                <div>
                    <Title level={3} style={{ margin: 0 }}>
                        Dashboard
                    </Title>
                    <Text type="secondary">Real-time fraud detection monitoring</Text>
                </div>

                {/* Stats Cards */}
                <Row gutter={[16, 16]}>
                    <Col xs={24} sm={12} lg={6}>
                        <Card>
                            <Statistic
                                title="Calls (24h)"
                                value={totalCalls}
                                prefix={<PhoneOutlined />}
                                loading={isLoading}
                            />
                        </Card>
                    </Col>
                    <Col xs={24} sm={12} lg={6}>
                        <Card>
                            <Statistic
                                title="Alerts (24h)"
                                value={totalAlerts}
                                prefix={<AlertOutlined style={{ color: '#faad14' }} />}
                                loading={isLoading}
                            />
                        </Card>
                    </Col>
                    <Col xs={24} sm={12} lg={6}>
                        <Card>
                            <Statistic
                                title="Pending Alerts"
                                value={pendingAlerts}
                                prefix={<WarningOutlined style={{ color: '#ff4d4f' }} />}
                                suffix={
                                    criticalAlerts > 0 && (
                                        <Tag color="red" style={{ marginLeft: 8 }}>
                                            {criticalAlerts} critical
                                        </Tag>
                                    )
                                }
                                loading={isLoading}
                            />
                        </Card>
                    </Col>
                    <Col xs={24} sm={12} lg={6}>
                        <Card>
                            <Statistic
                                title="Fraud Rate"
                                value={fraudRate}
                                suffix="%"
                                prefix={
                                    parseFloat(fraudRate) < 1 ? (
                                        <ArrowDownOutlined style={{ color: '#52c41a' }} />
                                    ) : (
                                        <ArrowUpOutlined style={{ color: '#ff4d4f' }} />
                                    )
                                }
                                valueStyle={{
                                    color: parseFloat(fraudRate) < 1 ? '#52c41a' : '#ff4d4f',
                                }}
                                loading={isLoading}
                            />
                        </Card>
                    </Col>
                </Row>

                {/* Main Dashboard Content */}
                <Row gutter={[16, 16]}>
                    {/* Call Masking Stats */}
                    <Col xs={24} lg={16}>
                        <Card title="Call Masking Detection" style={{ height: '100%' }}>
                            <CallMaskingStats />
                        </Card>
                    </Col>

                    {/* Live Alerts Feed */}
                    <Col xs={24} lg={8}>
                        <Card
                            title={
                                <Space>
                                    <span>Live Alerts</span>
                                    <Tag color="processing">Real-time</Tag>
                                </Space>
                            }
                            style={{ height: '100%' }}
                        >
                            <FraudAlertsFeed />
                        </Card>
                    </Col>
                </Row>

                {/* Gateway Health & Secondary Widgets */}
                <Row gutter={[16, 16]}>
                    <Col xs={24} lg={12}>
                        <Card title="Gateway Health">
                            <GatewayHealthGrid />
                        </Card>
                    </Col>

                    <Col xs={24} lg={6}>
                        <Card title="Remittance (24h)">
                            <RemittanceVolume />
                        </Card>
                    </Col>

                    <Col xs={24} lg={6}>
                        <Card title="Marketplace Activity">
                            <MarketplaceActivity />
                        </Card>
                    </Col>
                </Row>
            </Space>
        </div>
    );
};

export default Dashboard;
