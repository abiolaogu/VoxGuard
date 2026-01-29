import React from 'react';
import { useList } from '@refinedev/core';
import { List, useTable } from '@refinedev/antd';
import { Table, Tag, Card, Space, Typography, Row, Col, Statistic, Progress, Timeline, Badge, Alert } from 'antd';
import {
    PhoneOutlined,
    WarningOutlined,
    ClockCircleOutlined,
    TeamOutlined,
    StopOutlined,
    BellOutlined,
} from '@ant-design/icons';

const { Text, Title } = Typography;

// Wangiri Incidents List
export const WangiriIncidentsList: React.FC = () => {
    const { tableProps } = useTable({
        resource: 'wangiri_incidents',
        sorters: { initial: [{ field: 'created_at', order: 'desc' }] },
    });

    return (
        <List
            title={<><PhoneOutlined /> Wangiri Incidents</>}
            headerProps={{
                extra: (
                    <Space>
                        <Badge status="processing" text="Real-time Detection" />
                    </Space>
                ),
            }}
        >
            <Alert
                message="Wangiri (One-Ring) Fraud"
                description="Fraudsters make brief calls hoping victims call back premium-rate numbers. Ultra-short ring durations are key indicators."
                type="warning"
                showIcon
                style={{ marginBottom: 16 }}
            />

            <Row gutter={[16, 16]} style={{ marginBottom: 16 }}>
                <Col span={6}>
                    <Card size="small">
                        <Statistic
                            title="Detected Today"
                            value={47}
                            prefix={<PhoneOutlined />}
                            valueStyle={{ color: '#1890ff' }}
                        />
                    </Card>
                </Col>
                <Col span={6}>
                    <Card size="small">
                        <Statistic
                            title="Callbacks Blocked"
                            value={12}
                            prefix={<StopOutlined />}
                            valueStyle={{ color: '#52c41a' }}
                        />
                    </Card>
                </Col>
                <Col span={6}>
                    <Card size="small">
                        <Statistic
                            title="Warnings Sent"
                            value={35}
                            prefix={<BellOutlined />}
                            valueStyle={{ color: '#faad14' }}
                        />
                    </Card>
                </Col>
                <Col span={6}>
                    <Card size="small">
                        <Statistic
                            title="Active Campaigns"
                            value={3}
                            prefix={<TeamOutlined />}
                            valueStyle={{ color: '#cf1322' }}
                        />
                    </Card>
                </Col>
            </Row>

            <Table
                {...tableProps}
                rowKey="id"
                columns={[
                    {
                        title: 'Source Number',
                        dataIndex: 'source_number',
                        render: (num: string) => <Text code>{num}</Text>,
                    },
                    {
                        title: 'Target',
                        dataIndex: 'target_number',
                        render: (num: string) => <Text code>{num}</Text>,
                    },
                    {
                        title: 'Ring Duration',
                        dataIndex: 'ring_duration_ms',
                        render: (ms: number) => {
                            const seconds = ms / 1000;
                            const isShort = seconds < 3;
                            return (
                                <Tag
                                    icon={<ClockCircleOutlined />}
                                    color={isShort ? 'error' : 'default'}
                                >
                                    {seconds.toFixed(1)}s
                                </Tag>
                            );
                        },
                        sorter: true,
                    },
                    {
                        title: 'Confidence',
                        dataIndex: 'confidence_score',
                        render: (score: number) => (
                            <Progress
                                percent={Math.round(score * 100)}
                                size="small"
                                strokeColor={score > 0.7 ? '#cf1322' : score > 0.4 ? '#faad14' : '#52c41a'}
                            />
                        ),
                        sorter: true,
                        width: 150,
                    },
                    {
                        title: 'Callback',
                        dataIndex: 'callback_attempted',
                        render: (attempted: boolean, record: any) => {
                            if (record.callback_blocked) {
                                return <Tag icon={<StopOutlined />} color="success">Blocked</Tag>;
                            }
                            if (attempted) {
                                return <Tag color="error">Called Back ₦{record.callback_cost}</Tag>;
                            }
                            return <Tag color="default">No Callback</Tag>;
                        },
                    },
                    {
                        title: 'Warning',
                        dataIndex: 'warning_sent',
                        render: (sent: boolean) =>
                            sent ? (
                                <Tag icon={<BellOutlined />} color="blue">Sent</Tag>
                            ) : (
                                <Tag color="default">—</Tag>
                            ),
                    },
                    {
                        title: 'Time',
                        dataIndex: 'created_at',
                        render: (date: string) => new Date(date).toLocaleString(),
                        sorter: true,
                    },
                ]}
            />
        </List>
    );
};

// Wangiri Campaigns
export const WangiriCampaignsList: React.FC = () => {
    const { tableProps } = useTable({
        resource: 'wangiri_campaigns',
        sorters: { initial: [{ field: 'start_time', order: 'desc' }] },
    });

    return (
        <List title={<><TeamOutlined /> Wangiri Campaigns</>}>
            <Table
                {...tableProps}
                rowKey="id"
                columns={[
                    {
                        title: 'Status',
                        dataIndex: 'status',
                        render: (status: string) => {
                            const colors: Record<string, string> = {
                                ACTIVE: 'error',
                                MITIGATED: 'warning',
                                CLOSED: 'success',
                            };
                            return <Tag color={colors[status]}>{status}</Tag>;
                        },
                        filters: [
                            { text: 'Active', value: 'ACTIVE' },
                            { text: 'Mitigated', value: 'MITIGATED' },
                            { text: 'Closed', value: 'CLOSED' },
                        ],
                    },
                    {
                        title: 'Source Country',
                        dataIndex: 'source_country',
                        render: (code: string) => <Tag>{code}</Tag>,
                    },
                    {
                        title: 'Source Numbers',
                        dataIndex: 'source_numbers',
                        render: (nums: string[]) => (
                            <Text>{nums?.length ?? 0} numbers</Text>
                        ),
                    },
                    {
                        title: 'Call Attempts',
                        dataIndex: 'total_call_attempts',
                        render: (count: number) => (
                            <Text strong>{count.toLocaleString()}</Text>
                        ),
                        sorter: true,
                    },
                    {
                        title: 'Callbacks',
                        dataIndex: 'successful_callbacks',
                        render: (count: number) => (
                            <Text type="danger">{count}</Text>
                        ),
                    },
                    {
                        title: 'Est. Loss',
                        dataIndex: 'estimated_revenue_loss',
                        render: (loss: number) => (
                            <Text type="danger" strong>₦{loss?.toLocaleString() ?? 0}</Text>
                        ),
                        sorter: true,
                    },
                    {
                        title: 'Blocked',
                        dataIndex: 'blocked_numbers',
                        render: (nums: string[]) => (
                            <Tag color="success">{nums?.length ?? 0} blocked</Tag>
                        ),
                    },
                    {
                        title: 'Started',
                        dataIndex: 'start_time',
                        render: (date: string) => new Date(date).toLocaleString(),
                        sorter: true,
                    },
                ]}
            />
        </List>
    );
};
