import { Show } from '@refinedev/antd';
import {
    Card,
    Descriptions,
    Tag,
    Space,
    Typography,
    Row,
    Col,
    Image,
    Rate,
    Button,
    Avatar,
    Divider,
    List as AntList,
} from 'antd';
import {
    EnvironmentOutlined,
    PhoneOutlined,
    GlobalOutlined,
    CheckCircleOutlined,
} from '@ant-design/icons';
import { useShow } from '@refinedev/core';

import type { MarketplaceListing, ListingStatus, PricingType } from '@/types';

const { Title, Text, Paragraph } = Typography;

const statusColors: Record<ListingStatus, string> = {
    DRAFT: 'default',
    ACTIVE: 'success',
    PAUSED: 'warning',
    SOLD: 'purple',
    EXPIRED: 'error',
};

export const ListingShow: React.FC = () => {
    const { queryResult } = useShow<MarketplaceListing>({
        meta: {
            fields: [
                'id',
                'title',
                'slug',
                'description',
                'features',
                'pricing_type',
                'price_ngn',
                'price_min_ngn',
                'price_max_ngn',
                'price_usd',
                'images',
                'videos',
                'is_remote_available',
                'is_diaspora_friendly',
                'status',
                'is_featured',
                'view_count',
                'inquiry_count',
                'order_count',
                'favorite_count',
                'tags',
                'meta_title',
                'meta_description',
                'published_at',
                'created_at',
                {
                    provider: [
                        'id',
                        'business_name',
                        'description',
                        'logo_url',
                        'phone_primary',
                        'email',
                        'website',
                        'average_rating',
                        'total_reviews',
                        'total_orders',
                        'verification_status',
                        'tier',
                    ],
                },
                { category: ['id', 'name', 'icon'] },
                { state: ['id', 'name'] },
            ],
        },
    });

    const { data, isLoading } = queryResult;
    const record = data?.data as any;

    const formatPrice = () => {
        if (!record) return '-';
        if (record.pricing_type === 'NEGOTIABLE') return 'Negotiable';
        if (record.pricing_type === 'QUOTE') return 'Request Quote';
        if (record.price_min_ngn && record.price_max_ngn) {
            return `₦${record.price_min_ngn.toLocaleString()} - ₦${record.price_max_ngn.toLocaleString()}`;
        }
        return `₦${record.price_ngn?.toLocaleString()}`;
    };

    return (
        <Show isLoading={isLoading}>
            <Row gutter={16}>
                <Col span={16}>
                    {/* Images */}
                    {record?.images?.length > 0 && (
                        <Card style={{ marginBottom: 16 }}>
                            <Image.PreviewGroup>
                                <Space size="small" wrap>
                                    {record.images.map((img: string, i: number) => (
                                        <Image
                                            key={i}
                                            src={img}
                                            width={200}
                                            height={150}
                                            style={{ objectFit: 'cover', borderRadius: 8 }}
                                        />
                                    ))}
                                </Space>
                            </Image.PreviewGroup>
                        </Card>
                    )}

                    {/* Main Info */}
                    <Card>
                        <Space direction="vertical" size="middle" style={{ width: '100%' }}>
                            <Space>
                                <Tag color={statusColors[record?.status as ListingStatus]}>{record?.status}</Tag>
                                {record?.is_featured && <Tag color="gold">Featured</Tag>}
                                {record?.is_diaspora_friendly && <Tag color="blue">Diaspora Friendly</Tag>}
                                {record?.is_remote_available && <Tag color="cyan">Remote Available</Tag>}
                            </Space>

                            <Title level={3} style={{ margin: 0 }}>{record?.title}</Title>

                            <Space>
                                <Tag>{record?.category?.name}</Tag>
                                <Space>
                                    <EnvironmentOutlined />
                                    <Text>{record?.state?.name || 'Nationwide'}</Text>
                                </Space>
                            </Space>

                            <Title level={4} style={{ color: '#52c41a', margin: 0 }}>
                                {formatPrice()}
                            </Title>

                            <Divider />

                            <div>
                                <Title level={5}>Description</Title>
                                <Paragraph>{record?.description}</Paragraph>
                            </div>

                            {record?.features?.length > 0 && (
                                <div>
                                    <Title level={5}>Features</Title>
                                    <AntList
                                        dataSource={record.features}
                                        renderItem={(item: string) => (
                                            <AntList.Item style={{ padding: '4px 0' }}>
                                                <Space>
                                                    <CheckCircleOutlined style={{ color: '#52c41a' }} />
                                                    <Text>{item}</Text>
                                                </Space>
                                            </AntList.Item>
                                        )}
                                    />
                                </div>
                            )}

                            {record?.tags?.length > 0 && (
                                <div>
                                    <Title level={5}>Tags</Title>
                                    <Space wrap>
                                        {record.tags.map((tag: string, i: number) => (
                                            <Tag key={i}>{tag}</Tag>
                                        ))}
                                    </Space>
                                </div>
                            )}
                        </Space>
                    </Card>

                    {/* Stats */}
                    <Card title="Statistics" style={{ marginTop: 16 }}>
                        <Descriptions column={4}>
                            <Descriptions.Item label="Views">{record?.view_count || 0}</Descriptions.Item>
                            <Descriptions.Item label="Inquiries">{record?.inquiry_count || 0}</Descriptions.Item>
                            <Descriptions.Item label="Orders">{record?.order_count || 0}</Descriptions.Item>
                            <Descriptions.Item label="Favorites">{record?.favorite_count || 0}</Descriptions.Item>
                        </Descriptions>
                    </Card>
                </Col>

                <Col span={8}>
                    {/* Provider Card */}
                    <Card title="Provider">
                        <Space direction="vertical" size="middle" style={{ width: '100%' }}>
                            <Space>
                                <Avatar
                                    size={64}
                                    src={record?.provider?.logo_url}
                                    style={{ backgroundColor: '#1890ff' }}
                                >
                                    {record?.provider?.business_name?.[0]}
                                </Avatar>
                                <Space direction="vertical" size={0}>
                                    <Text strong style={{ fontSize: 16 }}>{record?.provider?.business_name}</Text>
                                    <Space size={4}>
                                        <Rate disabled defaultValue={record?.provider?.average_rating || 0} style={{ fontSize: 12 }} />
                                        <Text type="secondary">({record?.provider?.total_reviews || 0} reviews)</Text>
                                    </Space>
                                    <Space>
                                        {record?.provider?.verification_status === 'VERIFIED' && (
                                            <Tag color="success">Verified</Tag>
                                        )}
                                        <Tag>{record?.provider?.tier}</Tag>
                                    </Space>
                                </Space>
                            </Space>

                            <Paragraph ellipsis={{ rows: 2 }}>{record?.provider?.description}</Paragraph>

                            <Space direction="vertical" size={4}>
                                {record?.provider?.phone_primary && (
                                    <Space>
                                        <PhoneOutlined />
                                        <Text>{record.provider.phone_primary}</Text>
                                    </Space>
                                )}
                                {record?.provider?.website && (
                                    <Space>
                                        <GlobalOutlined />
                                        <a href={record.provider.website} target="_blank" rel="noopener noreferrer">
                                            Website
                                        </a>
                                    </Space>
                                )}
                            </Space>

                            <Button type="primary" block>
                                Contact Provider
                            </Button>
                        </Space>
                    </Card>
                </Col>
            </Row>
        </Show>
    );
};

export default ListingShow;
