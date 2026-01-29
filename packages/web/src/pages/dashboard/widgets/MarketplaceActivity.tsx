import { Statistic, Space, Typography, Badge, List, Spin } from 'antd';
import { ShopOutlined, ShoppingCartOutlined } from '@ant-design/icons';
import { useCustom } from '@refinedev/core';

const { Text } = Typography;

const MARKETPLACE_STATS_QUERY = `
  query MarketplaceStats {
    active_listings: marketplace_listings_aggregate(
      where: { status: { _eq: "ACTIVE" } }
    ) {
      aggregate { count }
    }
    new_orders: marketplace_orders_aggregate(
      where: { created_at: { _gte: "now() - interval '24 hours'" } }
    ) {
      aggregate { count }
    }
    recent_orders: marketplace_orders(
      limit: 5
      order_by: { created_at: desc }
    ) {
      id
      reference
      status
      agreed_amount
      created_at
      listing {
        title
      }
    }
  }
`;

export const MarketplaceActivity: React.FC = () => {
    const { data, isLoading } = useCustom({
        url: '',
        method: 'get',
        meta: {
            gqlQuery: MARKETPLACE_STATS_QUERY,
        },
    });

    if (isLoading) {
        return (
            <div style={{ height: 150, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Spin />
            </div>
        );
    }

    const stats = data?.data as any;
    const activeListings = stats?.active_listings?.aggregate?.count ?? 0;
    const newOrders = stats?.new_orders?.aggregate?.count ?? 0;
    const recentOrders = stats?.recent_orders ?? [];

    const statusMap: Record<string, { status: 'success' | 'processing' | 'default' | 'warning' | 'error'; text: string }> = {
        INQUIRY: { status: 'default', text: 'Inquiry' },
        QUOTED: { status: 'processing', text: 'Quoted' },
        IN_PROGRESS: { status: 'processing', text: 'In Progress' },
        COMPLETED: { status: 'success', text: 'Completed' },
        CANCELLED: { status: 'error', text: 'Cancelled' },
    };

    return (
        <Space direction="vertical" size="middle" style={{ width: '100%' }}>
            <Space size="large">
                <Statistic
                    title="Active Listings"
                    value={activeListings}
                    prefix={<ShopOutlined style={{ color: '#1890ff' }} />}
                    valueStyle={{ fontSize: 20 }}
                />
                <Statistic
                    title="New Orders (24h)"
                    value={newOrders}
                    prefix={<ShoppingCartOutlined style={{ color: '#52c41a' }} />}
                    valueStyle={{ fontSize: 20 }}
                />
            </Space>

            <div>
                <Text strong style={{ fontSize: 12, marginBottom: 8, display: 'block' }}>
                    Recent Orders
                </Text>
                <List
                    size="small"
                    dataSource={recentOrders.slice(0, 3)}
                    renderItem={(order: any) => (
                        <List.Item style={{ padding: '4px 0' }}>
                            <Space style={{ width: '100%', justifyContent: 'space-between' }}>
                                <Text ellipsis style={{ maxWidth: 120, fontSize: 12 }}>
                                    {order.listing?.title || order.reference}
                                </Text>
                                <Badge
                                    status={statusMap[order.status]?.status || 'default'}
                                    text={
                                        <Text style={{ fontSize: 11 }}>
                                            {statusMap[order.status]?.text || order.status}
                                        </Text>
                                    }
                                />
                            </Space>
                        </List.Item>
                    )}
                />
            </div>
        </Space>
    );
};

export default MarketplaceActivity;
