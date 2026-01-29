import React from 'react';
import { Skeleton, Card, Space, Row, Col } from 'antd';

/**
 * Loading skeleton for stat cards
 */
export const StatCardSkeleton: React.FC = () => (
    <Card style={{ borderRadius: 12 }}>
        <Skeleton.Input active size="small" style={{ width: 80, marginBottom: 12 }} />
        <Skeleton.Input active size="large" style={{ width: 120 }} />
    </Card>
);

/**
 * Loading skeleton for table rows
 */
export const TableRowSkeleton: React.FC<{ columns?: number }> = ({ columns = 5 }) => (
    <Space style={{ width: '100%', padding: '12px 0' }}>
        {Array.from({ length: columns }).map((_, i) => (
            <Skeleton.Input
                key={i}
                active
                size="small"
                style={{ width: 80 + Math.random() * 60 }}
            />
        ))}
    </Space>
);

/**
 * Loading skeleton for list items
 */
export const ListItemSkeleton: React.FC = () => (
    <div style={{ padding: '12px 0', borderBottom: '1px solid #f0f0f0' }}>
        <Space>
            <Skeleton.Avatar active size="small" />
            <Space direction="vertical" size={4}>
                <Skeleton.Input active size="small" style={{ width: 150 }} />
                <Skeleton.Input active size="small" style={{ width: 100, height: 12 }} />
            </Space>
        </Space>
    </div>
);

/**
 * Loading skeleton for dashboard
 */
export const DashboardSkeleton: React.FC = () => (
    <div style={{ padding: 24 }}>
        <Space direction="vertical" size="large" style={{ width: '100%' }}>
            {/* Header skeleton */}
            <Skeleton.Input active style={{ width: 200 }} />

            {/* Stats cards */}
            <Row gutter={[16, 16]}>
                {[1, 2, 3, 4].map((i) => (
                    <Col xs={24} sm={12} lg={6} key={i}>
                        <StatCardSkeleton />
                    </Col>
                ))}
            </Row>

            {/* Main content */}
            <Row gutter={[16, 16]}>
                <Col xs={24} lg={16}>
                    <Card style={{ borderRadius: 12 }}>
                        <Skeleton.Input active style={{ width: 150, marginBottom: 24 }} />
                        <Skeleton active paragraph={{ rows: 8 }} />
                    </Card>
                </Col>
                <Col xs={24} lg={8}>
                    <Card style={{ borderRadius: 12 }}>
                        <Skeleton.Input active style={{ width: 100, marginBottom: 16 }} />
                        {[1, 2, 3, 4, 5].map((i) => (
                            <ListItemSkeleton key={i} />
                        ))}
                    </Card>
                </Col>
            </Row>
        </Space>
    </div>
);

/**
 * Loading skeleton for forms
 */
export const FormSkeleton: React.FC<{ fields?: number }> = ({ fields = 4 }) => (
    <Card style={{ borderRadius: 12 }}>
        {Array.from({ length: fields }).map((_, i) => (
            <div key={i} style={{ marginBottom: 24 }}>
                <Skeleton.Input active size="small" style={{ width: 100, marginBottom: 8 }} />
                <Skeleton.Input active style={{ width: '100%' }} />
            </div>
        ))}
        <Space>
            <Skeleton.Button active />
            <Skeleton.Button active />
        </Space>
    </Card>
);

/**
 * Shimmer effect for loading states
 */
export const ShimmerSkeleton: React.FC<{
    width?: number | string;
    height?: number;
    borderRadius?: number;
}> = ({ width = '100%', height = 20, borderRadius = 4 }) => (
    <div
        style={{
            width,
            height,
            borderRadius,
            background: 'linear-gradient(90deg, #f0f0f0 25%, #e0e0e0 50%, #f0f0f0 75%)',
            backgroundSize: '200% 100%',
            animation: 'shimmer 1.5s infinite',
        }}
    />
);

export default {
    StatCardSkeleton,
    TableRowSkeleton,
    ListItemSkeleton,
    DashboardSkeleton,
    FormSkeleton,
    ShimmerSkeleton,
};
