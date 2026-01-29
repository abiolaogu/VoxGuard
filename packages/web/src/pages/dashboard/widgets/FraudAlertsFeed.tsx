import { useEffect, useState } from 'react';
import { List, Tag, Typography, Space, Badge, Empty, Spin } from 'antd';
import { AlertOutlined, ClockCircleOutlined } from '@ant-design/icons';
import { useList, useSubscription } from '@refinedev/core';
import dayjs from 'dayjs';
import relativeTime from 'dayjs/plugin/relativeTime';

import type { FraudAlert, Severity, AlertStatus } from '@/types';

dayjs.extend(relativeTime);

const { Text } = Typography;

const severityColors: Record<Severity, string> = {
    LOW: 'blue',
    MEDIUM: 'gold',
    HIGH: 'orange',
    CRITICAL: 'red',
};

const statusColors: Record<AlertStatus, string> = {
    PENDING: 'default',
    ACKNOWLEDGED: 'processing',
    INVESTIGATING: 'warning',
    RESOLVED: 'success',
    REPORTED_NCC: 'purple',
};

export const FraudAlertsFeed: React.FC = () => {
    const [alerts, setAlerts] = useState<FraudAlert[]>([]);

    const { data, isLoading, refetch } = useList<FraudAlert>({
        resource: 'fraud_alerts',
        pagination: { current: 1, pageSize: 10 },
        sorters: [{ field: 'detected_at', order: 'desc' }],
        filters: [
            {
                field: 'status',
                operator: 'in',
                value: ['PENDING', 'ACKNOWLEDGED', 'INVESTIGATING'],
            },
        ],
        meta: {
            fields: [
                'id',
                'b_number',
                'fraud_type',
                'score',
                'severity',
                'distinct_callers',
                'status',
                'detected_at',
            ],
        },
        liveMode: 'auto',
    });

    // Subscribe to real-time updates
    useSubscription({
        channel: 'fraud_alerts',
        types: ['created', 'updated'],
        onLiveEvent: (event) => {
            refetch();
        },
    });

    useEffect(() => {
        if (data?.data) {
            setAlerts(data.data.map((alert: any) => ({
                ...alert,
                bNumber: alert.b_number,
                fraudType: alert.fraud_type,
                distinctCallers: alert.distinct_callers,
                detectedAt: alert.detected_at,
            })));
        }
    }, [data]);

    if (isLoading) {
        return (
            <div style={{ height: 300, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Spin />
            </div>
        );
    }

    if (alerts.length === 0) {
        return <Empty description="No pending alerts" />;
    }

    return (
        <List
            size="small"
            dataSource={alerts}
            style={{ maxHeight: 350, overflow: 'auto' }}
            renderItem={(alert) => (
                <List.Item
                    key={alert.id}
                    style={{
                        padding: '12px 8px',
                        borderLeft: `3px solid ${alert.severity === 'CRITICAL'
                                ? '#ff4d4f'
                                : alert.severity === 'HIGH'
                                    ? '#fa8c16'
                                    : '#faad14'
                            }`,
                        marginBottom: 8,
                        background: alert.severity === 'CRITICAL' ? 'rgba(255,77,79,0.05)' : undefined,
                        borderRadius: 4,
                    }}
                >
                    <List.Item.Meta
                        avatar={
                            <Badge
                                status={alert.severity === 'CRITICAL' ? 'error' : 'warning'}
                                text={<AlertOutlined style={{ fontSize: 18 }} />}
                            />
                        }
                        title={
                            <Space size="small">
                                <Text strong>{alert.bNumber}</Text>
                                <Tag color={severityColors[alert.severity]}>{alert.severity}</Tag>
                            </Space>
                        }
                        description={
                            <Space direction="vertical" size={0}>
                                <Space>
                                    <Tag>{alert.fraudType.replace('_', ' ')}</Tag>
                                    <Text type="secondary">
                                        {alert.distinctCallers} distinct callers
                                    </Text>
                                </Space>
                                <Space>
                                    <ClockCircleOutlined style={{ fontSize: 12 }} />
                                    <Text type="secondary" style={{ fontSize: 12 }}>
                                        {dayjs(alert.detectedAt).fromNow()}
                                    </Text>
                                    <Tag color={statusColors[alert.status]}>{alert.status}</Tag>
                                </Space>
                            </Space>
                        }
                    />
                </List.Item>
            )}
        />
    );
};

export default FraudAlertsFeed;
