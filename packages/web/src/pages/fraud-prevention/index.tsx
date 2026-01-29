import React from 'react';
import { useList, useSubscription } from '@refinedev/core';
import { List, useTable } from '@refinedev/antd';
import { Card, Row, Col, Statistic, Table, Tag, Progress, Space, Typography, Alert } from 'antd';
import {
    AlertOutlined,
    SafetyOutlined,
    DollarOutlined,
    PhoneOutlined,
    GlobalOutlined,
    WarningOutlined,
    CheckCircleOutlined,
} from '@ant-design/icons';

const { Title, Text } = Typography;

// Risk level colors
const RISK_COLORS = {
    CRITICAL: '#cf1322',
    HIGH: '#fa541c',
    MEDIUM: '#faad14',
    LOW: '#52c41a',
};

// Fraud type icons and colors
const FRAUD_TYPE_CONFIG = {
    CLI_SPOOFING: { color: '#cf1322', icon: <SafetyOutlined /> },
    IRSF: { color: '#fa541c', icon: <DollarOutlined /> },
    WANGIRI: { color: '#1890ff', icon: <PhoneOutlined /> },
    PREMIUM_RATE: { color: '#722ed1', icon: <DollarOutlined /> },
    CALLBACK_FRAUD: { color: '#eb2f96', icon: <PhoneOutlined /> },
};

// Summary Card Component
const FraudSummaryCard: React.FC<{
    title: string;
    value: number;
    icon: React.ReactNode;
    color: string;
    trend?: number;
}> = ({ title, value, icon, color, trend }) => (
    <Card hoverable>
        <Statistic
            title={title}
            value={value}
            valueStyle={{ color }}
            prefix={icon}
            suffix={
                trend !== undefined && (
                    <Text type={trend > 0 ? 'danger' : 'success'} style={{ fontSize: 14 }}>
                        {trend > 0 ? '+' : ''}{trend}%
                    </Text>
                )
            }
        />
    </Card>
);

// Real-time Alert Banner
const RealTimeAlertBanner: React.FC = () => {
    const { data: latestAlert } = useSubscription({
        channel: 'fraud_events',
        types: ['insert'],
        onLiveEvent: (event) => {
            console.log('New fraud event:', event);
        },
    });

    if (!latestAlert) return null;

    return (
        <Alert
            message="Real-time Fraud Alert"
            description={`New ${latestAlert.event_type} detected`}
            type="warning"
            showIcon
            closable
            style={{ marginBottom: 16 }}
        />
    );
};

// Main Fraud Prevention Dashboard
export const FraudPreventionDashboard: React.FC = () => {
    // Fetch summary statistics
    const { data: cliStats } = useList({
        resource: 'cli_verifications',
        filters: [{ field: 'spoofing_detected', operator: 'eq', value: true }],
        pagination: { mode: 'off' },
        meta: { count: 'exact' },
    });

    const { data: irsfStats } = useList({
        resource: 'irsf_incidents',
        pagination: { mode: 'off' },
        meta: { count: 'exact' },
    });

    const { data: wangiriStats } = useList({
        resource: 'wangiri_incidents',
        pagination: { mode: 'off' },
        meta: { count: 'exact' },
    });

    const { data: callbackStats } = useList({
        resource: 'callback_fraud_incidents',
        pagination: { mode: 'off' },
        meta: { count: 'exact' },
    });

    // Recent incidents table
    const { tableProps: recentIncidents } = useTable({
        resource: 'fraud_events',
        sorters: { initial: [{ field: 'occurred_at', order: 'desc' }] },
        pagination: { pageSize: 10 },
    });

    return (
        <div style={{ padding: 24 }}>
            <Title level={2}>
                <SafetyOutlined /> Fraud Prevention Dashboard
            </Title>

            <RealTimeAlertBanner />

            {/* Summary Cards */}
            <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
                <Col xs={24} sm={12} md={6}>
                    <FraudSummaryCard
                        title="CLI Spoofing Blocked"
                        value={cliStats?.total ?? 0}
                        icon={<SafetyOutlined />}
                        color={RISK_COLORS.CRITICAL}
                    />
                </Col>
                <Col xs={24} sm={12} md={6}>
                    <FraudSummaryCard
                        title="IRSF Attempts"
                        value={irsfStats?.total ?? 0}
                        icon={<GlobalOutlined />}
                        color={RISK_COLORS.HIGH}
                    />
                </Col>
                <Col xs={24} sm={12} md={6}>
                    <FraudSummaryCard
                        title="Wangiri Detected"
                        value={wangiriStats?.total ?? 0}
                        icon={<PhoneOutlined />}
                        color="#1890ff"
                    />
                </Col>
                <Col xs={24} sm={12} md={6}>
                    <FraudSummaryCard
                        title="Callback Fraud"
                        value={callbackStats?.total ?? 0}
                        icon={<WarningOutlined />}
                        color={RISK_COLORS.MEDIUM}
                    />
                </Col>
            </Row>

            {/* Detection Rates */}
            <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
                <Col xs={24} md={12}>
                    <Card title="Detection Accuracy by Type">
                        <Space direction="vertical" style={{ width: '100%' }}>
                            <div>
                                <Text>CLI Spoofing</Text>
                                <Progress percent={95} strokeColor="#cf1322" />
                            </div>
                            <div>
                                <Text>IRSF Detection</Text>
                                <Progress percent={92} strokeColor="#fa541c" />
                            </div>
                            <div>
                                <Text>Wangiri Detection</Text>
                                <Progress percent={88} strokeColor="#1890ff" />
                            </div>
                            <div>
                                <Text>Premium Rate Fraud</Text>
                                <Progress percent={90} strokeColor="#722ed1" />
                            </div>
                        </Space>
                    </Card>
                </Col>
                <Col xs={24} md={12}>
                    <Card title="Revenue Protected (Last 30 Days)">
                        <Statistic
                            title="Total Revenue Protected"
                            value={15420000}
                            precision={0}
                            prefix="₦"
                            valueStyle={{ color: '#3f8600', fontSize: 32 }}
                        />
                        <Space style={{ marginTop: 16 }}>
                            <Tag color="green">IRSF: ₦8.2M</Tag>
                            <Tag color="blue">Wangiri: ₦4.1M</Tag>
                            <Tag color="purple">Premium: ₦3.1M</Tag>
                        </Space>
                    </Card>
                </Col>
            </Row>

            {/* Recent Fraud Events */}
            <Card title="Recent Fraud Events">
                <Table
                    {...recentIncidents}
                    columns={[
                        {
                            title: 'Time',
                            dataIndex: 'occurred_at',
                            render: (date: string) => new Date(date).toLocaleString(),
                        },
                        {
                            title: 'Type',
                            dataIndex: 'event_type',
                            render: (type: string) => {
                                const config = FRAUD_TYPE_CONFIG[type as keyof typeof FRAUD_TYPE_CONFIG];
                                return (
                                    <Tag color={config?.color ?? 'default'} icon={config?.icon}>
                                        {type.replace('_', ' ')}
                                    </Tag>
                                );
                            },
                        },
                        {
                            title: 'Risk Level',
                            dataIndex: 'risk_level',
                            render: (level: string) => (
                                <Tag color={RISK_COLORS[level as keyof typeof RISK_COLORS]}>
                                    {level}
                                </Tag>
                            ),
                        },
                        {
                            title: 'Risk Score',
                            dataIndex: 'risk_score',
                            render: (score: number) => (
                                <Progress
                                    percent={Math.round(score * 100)}
                                    size="small"
                                    strokeColor={score > 0.7 ? '#cf1322' : score > 0.4 ? '#faad14' : '#52c41a'}
                                />
                            ),
                        },
                        {
                            title: 'Status',
                            dataIndex: 'processed_at',
                            render: (processed: string | null) =>
                                processed ? (
                                    <Tag icon={<CheckCircleOutlined />} color="success">Processed</Tag>
                                ) : (
                                    <Tag icon={<AlertOutlined />} color="warning">Pending</Tag>
                                ),
                        },
                    ]}
                    rowKey="id"
                    size="small"
                />
            </Card>
        </div>
    );
};

export default FraudPreventionDashboard;
