import React from 'react';
import { useList, useShow } from '@refinedev/core';
import { List, useTable, Show, CreateButton } from '@refinedev/antd';
import { Table, Tag, Card, Space, Typography, Descriptions, Row, Col, Statistic, Progress, Alert, Tooltip } from 'antd';
import {
    GlobalOutlined,
    DollarOutlined,
    WarningOutlined,
    StopOutlined,
    EyeOutlined,
} from '@ant-design/icons';

const { Text, Title } = Typography;

// Risk level colors
const RISK_COLORS: Record<string, string> = {
    CRITICAL: '#cf1322',
    HIGH: '#fa541c',
    MEDIUM: '#faad14',
    LOW: '#52c41a',
};

// IRSF Incidents List
export const IRSFIncidentsList: React.FC = () => {
    const { tableProps } = useTable({
        resource: 'irsf_incidents',
        sorters: { initial: [{ field: 'created_at', order: 'desc' }] },
    });

    return (
        <List
            title={<><GlobalOutlined /> IRSF Incidents</>}
            headerProps={{
                extra: (
                    <Space>
                        <Tag color="error">Today: 12</Tag>
                        <Tag color="warning">This Week: 47</Tag>
                    </Space>
                ),
            }}
        >
            <Alert
                message="International Revenue Share Fraud (IRSF)"
                description="Fraudsters generate calls to high-cost international destinations to collect revenue share."
                type="info"
                showIcon
                style={{ marginBottom: 16 }}
            />
            <Table
                {...tableProps}
                rowKey="id"
                columns={[
                    {
                        title: 'Source',
                        dataIndex: 'source_number',
                        render: (num: string) => <Text code>{num}</Text>,
                    },
                    {
                        title: 'Destination',
                        dataIndex: 'destination_number',
                        render: (num: string, record: any) => (
                            <Space direction="vertical" size={0}>
                                <Text code>{num}</Text>
                                <Text type="secondary" style={{ fontSize: 12 }}>
                                    {record.destination_country}
                                </Text>
                            </Space>
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
                                format={(percent) => `${percent}%`}
                            />
                        ),
                        sorter: true,
                        width: 150,
                    },
                    {
                        title: 'Estimated Loss',
                        dataIndex: 'estimated_loss',
                        render: (loss: number | null) =>
                            loss ? (
                                <Text type="danger" strong>₦{loss.toLocaleString()}</Text>
                            ) : '—',
                        sorter: true,
                    },
                    {
                        title: 'Duration',
                        dataIndex: 'call_duration_seconds',
                        render: (sec: number | null) =>
                            sec ? `${Math.floor(sec / 60)}m ${sec % 60}s` : '—',
                    },
                    {
                        title: 'Action',
                        dataIndex: 'action_taken',
                        render: (action: string | null) => {
                            if (!action) return <Tag>Pending</Tag>;
                            return action === 'BLOCKED' ? (
                                <Tag icon={<StopOutlined />} color="error">Blocked</Tag>
                            ) : (
                                <Tag icon={<EyeOutlined />} color="warning">Monitored</Tag>
                            );
                        },
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

// IRSF High-Risk Destinations
export const IRSFDestinationsList: React.FC = () => {
    const { tableProps } = useTable({
        resource: 'irsf_destinations',
        sorters: { initial: [{ field: 'risk_level', order: 'asc' }] },
    });

    return (
        <List
            title={<><GlobalOutlined /> High-Risk Destinations</>}
            headerProps={{
                extra: <CreateButton>Add Destination</CreateButton>,
            }}
        >
            <Row gutter={[16, 16]} style={{ marginBottom: 16 }}>
                <Col span={6}>
                    <Card size="small">
                        <Statistic title="Critical" value={5} valueStyle={{ color: RISK_COLORS.CRITICAL }} />
                    </Card>
                </Col>
                <Col span={6}>
                    <Card size="small">
                        <Statistic title="High" value={12} valueStyle={{ color: RISK_COLORS.HIGH }} />
                    </Card>
                </Col>
                <Col span={6}>
                    <Card size="small">
                        <Statistic title="Medium" value={8} valueStyle={{ color: RISK_COLORS.MEDIUM }} />
                    </Card>
                </Col>
                <Col span={6}>
                    <Card size="small">
                        <Statistic title="Blacklisted" value={3} valueStyle={{ color: '#000' }} />
                    </Card>
                </Col>
            </Row>
            <Table
                {...tableProps}
                rowKey="id"
                columns={[
                    {
                        title: 'Country',
                        dataIndex: 'country_name',
                        render: (name: string, record: any) => (
                            <Space>
                                <span>{name}</span>
                                <Text code>{record.country_code}</Text>
                            </Space>
                        ),
                    },
                    {
                        title: 'Prefix',
                        dataIndex: 'prefix',
                        render: (prefix: string) => <Text code>+{prefix}</Text>,
                    },
                    {
                        title: 'Risk Level',
                        dataIndex: 'risk_level',
                        render: (level: string) => (
                            <Tag color={RISK_COLORS[level]}>{level}</Tag>
                        ),
                        filters: [
                            { text: 'Critical', value: 'CRITICAL' },
                            { text: 'High', value: 'HIGH' },
                            { text: 'Medium', value: 'MEDIUM' },
                            { text: 'Low', value: 'LOW' },
                        ],
                    },
                    {
                        title: 'Fraud Types',
                        dataIndex: 'fraud_types',
                        render: (types: string[]) => (
                            <Space>
                                {types?.map((type) => (
                                    <Tag key={type}>{type}</Tag>
                                ))}
                            </Space>
                        ),
                    },
                    {
                        title: 'Incidents',
                        dataIndex: 'incident_count',
                        render: (count: number) => count || 0,
                        sorter: true,
                    },
                    {
                        title: 'Status',
                        render: (_: any, record: any) => (
                            <Space>
                                {record.is_blacklisted && (
                                    <Tag icon={<StopOutlined />} color="error">Blacklisted</Tag>
                                )}
                                {record.is_monitored && !record.is_blacklisted && (
                                    <Tag icon={<EyeOutlined />} color="blue">Monitored</Tag>
                                )}
                            </Space>
                        ),
                    },
                ]}
            />
        </List>
    );
};
