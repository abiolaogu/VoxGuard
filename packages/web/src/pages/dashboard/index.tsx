import React from 'react';
import { Row, Col, Card, Typography, Space, Badge, Tooltip, Button, Tabs } from 'antd';
import { motion, AnimatePresence } from 'framer-motion';
import {
    AlertOutlined,
    PhoneOutlined,
    DollarOutlined,
    ShopOutlined,
    ArrowUpOutlined,
    ArrowDownOutlined,
    ReloadOutlined,
    SettingOutlined,
} from '@ant-design/icons';
import { useList, useSubscription } from '@refinedev/core';

import { StatCard, StaggerList, StaggerItem, AnimatedCounter, FadeIn } from '@/components/animations';
import { RealTimeIndicator } from '@/components/shared';
import { DashboardSkeleton } from '@/components/feedback';
import { NairaDisplay, formatNaira } from '@/components/nigerian';
import { staggerContainer, staggerItem } from '@/theme/animations';

import CallMaskingStats from './widgets/CallMaskingStats';
import FraudAlertsFeed from './widgets/FraudAlertsFeed';
import GatewayHealthGrid from './widgets/GatewayHealthGrid';
import RemittanceVolume from './widgets/RemittanceVolume';
import MarketplaceActivity from './widgets/MarketplaceActivity';

const { Title, Text } = Typography;

// Quick stats configuration
const useQuickStats = () => {
    const { data: alertsData, isLoading: alertsLoading } = useList({
        resource: 'fraud_alerts',
        filters: [{ field: 'status', operator: 'eq', value: 'PENDING' }],
        meta: { fields: ['id'] },
    });

    const { data: callsData, isLoading: callsLoading } = useList({
        resource: 'call_verifications',
        filters: [{ field: 'masking_detected', operator: 'eq', value: true }],
        meta: { fields: ['id'] },
        pagination: { current: 1, pageSize: 1 },
    });

    const { data: txData, isLoading: txLoading } = useList({
        resource: 'remittance_transactions',
        filters: [{ field: 'status', operator: 'eq', value: 'COMPLETED' }],
        pagination: { current: 1, pageSize: 100 },
        meta: { fields: ['id', 'amount_received'] },
    });

    const { data: listingsData, isLoading: listingsLoading } = useList({
        resource: 'marketplace_listings',
        filters: [{ field: 'status', operator: 'eq', value: 'ACTIVE' }],
        meta: { fields: ['id'] },
    });

    const pendingAlerts = alertsData?.total || 0;
    const maskedCalls = callsData?.total || 0;
    const totalRemitted = (txData?.data || []).reduce(
        (sum: number, tx: any) => sum + (tx.amount_received || 0),
        0
    );
    const activeListings = listingsData?.total || 0;

    return {
        pendingAlerts,
        maskedCalls,
        totalRemitted,
        activeListings,
        isLoading: alertsLoading || callsLoading || txLoading || listingsLoading,
    };
};

const Dashboard: React.FC = () => {
    const [lastUpdate, setLastUpdate] = React.useState(new Date());
    const [isConnected, setIsConnected] = React.useState(true);
    const { pendingAlerts, maskedCalls, totalRemitted, activeListings, isLoading } = useQuickStats();

    // Subscribe to real-time updates
    useSubscription({
        channel: 'fraud_alerts',
        types: ['created', 'updated'],
        onLiveEvent: () => {
            setLastUpdate(new Date());
        },
    });

    if (isLoading) {
        return <DashboardSkeleton />;
    }

    return (
        <motion.div
            initial="hidden"
            animate="visible"
            variants={staggerContainer}
            style={{ padding: 24 }}
        >
            {/* Header */}
            <motion.div variants={staggerItem}>
                <Row justify="space-between" align="middle" style={{ marginBottom: 24 }}>
                    <Col>
                        <Space direction="vertical" size={0}>
                            <Title level={3} style={{ margin: 0 }}>
                                Dashboard
                            </Title>
                            <Text type="secondary">
                                Welcome back! Here's what's happening today.
                            </Text>
                        </Space>
                    </Col>
                    <Col>
                        <Space>
                            <RealTimeIndicator isConnected={isConnected} lastUpdate={lastUpdate} />
                            <Button type="text" icon={<ReloadOutlined />} onClick={() => window.location.reload()}>
                                Refresh
                            </Button>
                            <Button type="text" icon={<SettingOutlined />} />
                        </Space>
                    </Col>
                </Row>
            </motion.div>

            {/* Quick Stats */}
            <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
                <Col xs={24} sm={12} lg={6}>
                    <motion.div variants={staggerItem}>
                        <StatCard
                            title="Pending Alerts"
                            value={pendingAlerts}
                            prefix={<AlertOutlined />}
                            color={pendingAlerts > 0 ? 'error' : 'success'}
                            trend={
                                pendingAlerts > 0
                                    ? { value: 12, direction: 'up' }
                                    : undefined
                            }
                        />
                    </motion.div>
                </Col>
                <Col xs={24} sm={12} lg={6}>
                    <motion.div variants={staggerItem}>
                        <StatCard
                            title="Masked Calls"
                            value={maskedCalls}
                            prefix={<PhoneOutlined />}
                            color={maskedCalls > 10 ? 'warning' : 'primary'}
                            trend={{ value: 8, direction: 'down' }}
                        />
                    </motion.div>
                </Col>
                <Col xs={24} sm={12} lg={6}>
                    <motion.div variants={staggerItem}>
                        <StatCard
                            title="Volume (NGN)"
                            value={formatNaira(totalRemitted, { decimals: 0 })}
                            prefix={<DollarOutlined />}
                            color="success"
                            trend={{ value: 23, direction: 'up' }}
                        />
                    </motion.div>
                </Col>
                <Col xs={24} sm={12} lg={6}>
                    <motion.div variants={staggerItem}>
                        <StatCard
                            title="Active Listings"
                            value={activeListings}
                            prefix={<ShopOutlined />}
                            color="primary"
                            trend={{ value: 5, direction: 'up' }}
                        />
                    </motion.div>
                </Col>
            </Row>

            {/* Main Content */}
            <Row gutter={[16, 16]}>
                {/* Left Column */}
                <Col xs={24} lg={16}>
                    <StaggerList staggerDelay={0.1}>
                        {/* Call Masking Stats */}
                        <StaggerItem>
                            <Card
                                title={
                                    <Space>
                                        <PhoneOutlined />
                                        <span>Call Masking Detection</span>
                                        <Badge
                                            count="Live"
                                            style={{
                                                backgroundColor: '#52c41a',
                                                fontSize: 10,
                                                height: 18,
                                                lineHeight: '18px',
                                            }}
                                        />
                                    </Space>
                                }
                                style={{ marginBottom: 16, borderRadius: 12 }}
                                bodyStyle={{ padding: 16 }}
                            >
                                <CallMaskingStats />
                            </Card>
                        </StaggerItem>

                        {/* Gateway Health */}
                        <StaggerItem>
                            <Card
                                title={
                                    <Space>
                                        <span>Gateway Health</span>
                                    </Space>
                                }
                                style={{ marginBottom: 16, borderRadius: 12 }}
                                bodyStyle={{ padding: 16 }}
                            >
                                <GatewayHealthGrid />
                            </Card>
                        </StaggerItem>

                        {/* Tabs for Remittance & Marketplace */}
                        <StaggerItem>
                            <Card style={{ borderRadius: 12 }} bodyStyle={{ padding: 0 }}>
                                <Tabs
                                    defaultActiveKey="remittance"
                                    style={{ padding: '0 16px' }}
                                    items={[
                                        {
                                            key: 'remittance',
                                            label: (
                                                <Space>
                                                    <DollarOutlined />
                                                    Remittance Volume
                                                </Space>
                                            ),
                                            children: (
                                                <div style={{ padding: '16px 0' }}>
                                                    <RemittanceVolume />
                                                </div>
                                            ),
                                        },
                                        {
                                            key: 'marketplace',
                                            label: (
                                                <Space>
                                                    <ShopOutlined />
                                                    Marketplace Activity
                                                </Space>
                                            ),
                                            children: (
                                                <div style={{ padding: '16px 0' }}>
                                                    <MarketplaceActivity />
                                                </div>
                                            ),
                                        },
                                    ]}
                                />
                            </Card>
                        </StaggerItem>
                    </StaggerList>
                </Col>

                {/* Right Column - Alerts Feed */}
                <Col xs={24} lg={8}>
                    <motion.div variants={staggerItem}>
                        <Card
                            title={
                                <Space>
                                    <AlertOutlined style={{ color: '#ff4d4f' }} />
                                    <span>Live Fraud Alerts</span>
                                    {pendingAlerts > 0 && (
                                        <Badge
                                            count={pendingAlerts}
                                            overflowCount={99}
                                            style={{ backgroundColor: '#ff4d4f' }}
                                        />
                                    )}
                                </Space>
                            }
                            style={{ borderRadius: 12, height: '100%' }}
                            bodyStyle={{ padding: 0, maxHeight: 600, overflow: 'auto' }}
                        >
                            <FraudAlertsFeed />
                        </Card>
                    </motion.div>
                </Col>
            </Row>
        </motion.div>
    );
};

export default Dashboard;
