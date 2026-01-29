import { List, useTable, FilterDropdown } from '@refinedev/antd';
import { Table, Tag, Space, Typography, Input, Select, Button, Card, Image, Rate } from 'antd';
import { EyeOutlined, SearchOutlined, EnvironmentOutlined } from '@ant-design/icons';
import { useNavigation } from '@refinedev/core';

import type { MarketplaceListing, ListingStatus, PricingType } from '@/types';

const { Text, Paragraph } = Typography;

const statusColors: Record<ListingStatus, string> = {
    DRAFT: 'default',
    ACTIVE: 'success',
    PAUSED: 'warning',
    SOLD: 'purple',
    EXPIRED: 'error',
};

export const ListingList: React.FC = () => {
    const { show } = useNavigation();

    const { tableProps } = useTable<MarketplaceListing>({
        resource: 'marketplace_listings',
        sorters: {
            initial: [{ field: 'created_at', order: 'desc' }],
        },
        meta: {
            fields: [
                'id',
                'title',
                'slug',
                'description',
                'pricing_type',
                'price_ngn',
                'price_min_ngn',
                'price_max_ngn',
                'images',
                'status',
                'is_featured',
                'is_diaspora_friendly',
                'view_count',
                'order_count',
                'created_at',
                { provider: ['business_name', 'average_rating', 'total_reviews'] },
                { category: ['name'] },
                { state: ['name'] },
            ],
        },
    });

    const columns = [
        {
            title: 'Listing',
            key: 'listing',
            width: 350,
            filterDropdown: (props: any) => (
                <FilterDropdown {...props}>
                    <Input placeholder="Search title" prefix={<SearchOutlined />} />
                </FilterDropdown>
            ),
            render: (_: unknown, record: any) => (
                <Space>
                    {record.images?.[0] && (
                        <Image
                            src={record.images[0]}
                            width={60}
                            height={60}
                            style={{ objectFit: 'cover', borderRadius: 4 }}
                            preview={false}
                            fallback="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="
                        />
                    )}
                    <Space direction="vertical" size={0}>
                        <Text strong ellipsis style={{ maxWidth: 250 }}>{record.title}</Text>
                        <Text type="secondary" style={{ fontSize: 11 }}>{record.category?.name}</Text>
                        <Space size="small">
                            {record.is_featured && <Tag color="gold">Featured</Tag>}
                            {record.is_diaspora_friendly && <Tag color="blue">Diaspora</Tag>}
                        </Space>
                    </Space>
                </Space>
            ),
        },
        {
            title: 'Provider',
            key: 'provider',
            render: (_: unknown, record: any) => (
                <Space direction="vertical" size={0}>
                    <Text>{record.provider?.business_name}</Text>
                    <Space size={4}>
                        <Rate disabled defaultValue={record.provider?.average_rating || 0} style={{ fontSize: 12 }} />
                        <Text type="secondary" style={{ fontSize: 11 }}>({record.provider?.total_reviews || 0})</Text>
                    </Space>
                </Space>
            ),
        },
        {
            title: 'Price',
            key: 'price',
            render: (_: unknown, record: any) => {
                if (record.pricing_type === 'NEGOTIABLE' || record.pricing_type === 'QUOTE') {
                    return <Tag>{record.pricing_type}</Tag>;
                }
                if (record.price_min_ngn && record.price_max_ngn) {
                    return (
                        <Text>₦{record.price_min_ngn?.toLocaleString()} - ₦{record.price_max_ngn?.toLocaleString()}</Text>
                    );
                }
                return <Text strong>₦{record.price_ngn?.toLocaleString()}</Text>;
            },
        },
        {
            title: 'Location',
            key: 'location',
            render: (_: unknown, record: any) => (
                <Space>
                    <EnvironmentOutlined />
                    <Text>{record.state?.name || 'Nationwide'}</Text>
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
                        style={{ width: 150 }}
                        options={Object.keys(statusColors).map((s) => ({ label: s, value: s }))}
                    />
                </FilterDropdown>
            ),
            render: (value: ListingStatus) => (
                <Tag color={statusColors[value]}>{value}</Tag>
            ),
        },
        {
            title: 'Stats',
            key: 'stats',
            render: (_: unknown, record: any) => (
                <Space direction="vertical" size={0}>
                    <Text style={{ fontSize: 12 }}>{record.view_count} views</Text>
                    <Text style={{ fontSize: 12 }}>{record.order_count} orders</Text>
                </Space>
            ),
        },
        {
            title: 'Actions',
            key: 'actions',
            render: (_: unknown, record: MarketplaceListing) => (
                <Button
                    type="text"
                    icon={<EyeOutlined />}
                    onClick={() => show('listings', record.id)}
                />
            ),
        },
    ];

    return (
        <List title="Marketplace Listings">
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

export default ListingList;
