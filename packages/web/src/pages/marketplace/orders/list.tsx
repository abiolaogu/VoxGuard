import { List, useTable, FilterDropdown } from '@refinedev/antd';
import { Table, Tag, Space, Typography, Select, Button, Tooltip } from 'antd';
import { EyeOutlined } from '@ant-design/icons';
import { useNavigation } from '@refinedev/core';
import dayjs from 'dayjs';

import type { MarketplaceOrder, OrderStatus } from '@/types';

const { Text } = Typography;

const statusColors: Record<OrderStatus, string> = {
    INQUIRY: 'default',
    QUOTED: 'processing',
    PENDING_PAYMENT: 'gold',
    PAID: 'cyan',
    IN_PROGRESS: 'blue',
    DELIVERED: 'geekblue',
    COMPLETED: 'success',
    DISPUTED: 'error',
    CANCELLED: 'default',
    REFUNDED: 'purple',
};

export const OrderList: React.FC = () => {
    const { show } = useNavigation();

    const { tableProps } = useTable<MarketplaceOrder>({
        resource: 'marketplace_orders',
        sorters: {
            initial: [{ field: 'created_at', order: 'desc' }],
        },
        meta: {
            fields: [
                'id',
                'reference',
                'status',
                'quoted_amount',
                'agreed_amount',
                'currency',
                'delivery_date',
                'customer_rating',
                'created_at',
                { listing: ['title'] },
                { provider: ['business_name'] },
            ],
        },
    });

    const columns = [
        {
            title: 'Reference',
            dataIndex: 'reference',
            key: 'reference',
            render: (value: string) => <Text strong copyable>{value}</Text>,
        },
        {
            title: 'Service',
            key: 'service',
            render: (_: unknown, record: any) => (
                <Space direction="vertical" size={0}>
                    <Text ellipsis style={{ maxWidth: 200 }}>{record.listing?.title || '-'}</Text>
                    <Text type="secondary" style={{ fontSize: 11 }}>{record.provider?.business_name}</Text>
                </Space>
            ),
        },
        {
            title: 'Amount',
            key: 'amount',
            render: (_: unknown, record: any) => (
                <Space direction="vertical" size={0}>
                    {record.agreed_amount ? (
                        <Text strong>₦{record.agreed_amount.toLocaleString()}</Text>
                    ) : record.quoted_amount ? (
                        <Text>₦{record.quoted_amount.toLocaleString()} (quoted)</Text>
                    ) : (
                        <Text type="secondary">Pending</Text>
                    )}
                </Space>
            ),
        },
        {
            title: 'Status',
            dataIndex: 'status',
            key: 'status',
            filterDropdown: (props: any) => (
                <FilterDropdown {...props}>
                    <Select
                        mode="multiple"
                        placeholder="Select status"
                        style={{ width: 180 }}
                        options={Object.keys(statusColors).map((s) => ({
                            label: s.replace(/_/g, ' '),
                            value: s,
                        }))}
                    />
                </FilterDropdown>
            ),
            render: (value: OrderStatus) => (
                <Tag color={statusColors[value]}>{value.replace(/_/g, ' ')}</Tag>
            ),
        },
        {
            title: 'Delivery',
            dataIndex: 'delivery_date',
            key: 'delivery_date',
            render: (value: string) => value ? dayjs(value).format('MMM D, YYYY') : '-',
        },
        {
            title: 'Created',
            dataIndex: 'created_at',
            key: 'created_at',
            sorter: true,
            render: (value: string) => (
                <Tooltip title={dayjs(value).format('YYYY-MM-DD HH:mm')}>
                    <Text>{dayjs(value).fromNow()}</Text>
                </Tooltip>
            ),
        },
        {
            title: 'Actions',
            key: 'actions',
            render: (_: unknown, record: MarketplaceOrder) => (
                <Button
                    type="text"
                    icon={<EyeOutlined />}
                    onClick={() => show('orders', record.id)}
                />
            ),
        },
    ];

    return (
        <List title="Marketplace Orders">
            <Table
                {...tableProps}
                rowKey="id"
                columns={columns}
                pagination={{
                    ...tableProps.pagination,
                    showSizeChanger: true,
                }}
            />
        </List>
    );
};

export default OrderList;
