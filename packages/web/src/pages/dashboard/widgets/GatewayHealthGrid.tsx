import { Row, Col, Card, Progress, Typography, Space, Tag, Tooltip, Empty, Spin } from 'antd';
import { useList } from '@refinedev/core';
import type { Gateway } from '@/types';

const { Text } = Typography;

export const GatewayHealthGrid: React.FC = () => {
    const { data, isLoading } = useList<Gateway>({
        resource: 'gateways',
        pagination: { current: 1, pageSize: 12 },
        filters: [{ field: 'is_active', operator: 'eq', value: true }],
        sorters: [{ field: 'total_calls', order: 'desc' }],
        meta: {
            fields: [
                'id',
                'name',
                'ip_address',
                'carrier_name',
                'is_blacklisted',
                'fraud_threshold',
                'total_calls',
                'fraud_calls',
            ],
        },
    });

    if (isLoading) {
        return (
            <div style={{ height: 200, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Spin />
            </div>
        );
    }

    const gateways = data?.data?.map((gw: any) => ({
        ...gw,
        ipAddress: gw.ip_address,
        carrierName: gw.carrier_name,
        isBlacklisted: gw.is_blacklisted,
        fraudThreshold: gw.fraud_threshold,
        totalCalls: gw.total_calls,
        fraudCalls: gw.fraud_calls,
    })) || [];

    if (gateways.length === 0) {
        return <Empty description="No active gateways" />;
    }

    return (
        <Row gutter={[12, 12]}>
            {gateways.map((gateway) => {
                const fraudRate = gateway.totalCalls > 0
                    ? (gateway.fraudCalls / gateway.totalCalls) * 100
                    : 0;
                const healthPercent = Math.max(0, 100 - fraudRate * 10);
                const isHealthy = fraudRate < gateway.fraudThreshold * 100;

                return (
                    <Col xs={24} sm={12} md={8} key={gateway.id}>
                        <Card
                            size="small"
                            style={{
                                borderColor: gateway.isBlacklisted
                                    ? '#ff4d4f'
                                    : isHealthy
                                        ? '#52c41a'
                                        : '#faad14',
                            }}
                        >
                            <Space direction="vertical" size={4} style={{ width: '100%' }}>
                                <Space style={{ justifyContent: 'space-between', width: '100%' }}>
                                    <Tooltip title={gateway.ipAddress}>
                                        <Text strong ellipsis style={{ maxWidth: 100 }}>
                                            {gateway.name}
                                        </Text>
                                    </Tooltip>
                                    {gateway.isBlacklisted ? (
                                        <Tag color="error">Blacklisted</Tag>
                                    ) : isHealthy ? (
                                        <Tag color="success">Healthy</Tag>
                                    ) : (
                                        <Tag color="warning">At Risk</Tag>
                                    )}
                                </Space>

                                <Text type="secondary" style={{ fontSize: 11 }}>
                                    {gateway.carrierName || 'Unknown'}
                                </Text>

                                <Progress
                                    percent={healthPercent}
                                    size="small"
                                    strokeColor={
                                        healthPercent > 80
                                            ? '#52c41a'
                                            : healthPercent > 50
                                                ? '#faad14'
                                                : '#ff4d4f'
                                    }
                                    format={() => `${fraudRate.toFixed(1)}%`}
                                />

                                <Text type="secondary" style={{ fontSize: 11 }}>
                                    {gateway.totalCalls.toLocaleString()} calls · {gateway.fraudCalls} flagged
                                </Text>
                            </Space>
                        </Card>
                    </Col>
                );
            })}
        </Row>
    );
};

export default GatewayHealthGrid;
