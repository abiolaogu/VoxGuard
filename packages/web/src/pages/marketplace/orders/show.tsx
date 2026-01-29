import { Show } from '@refinedev/antd';
import { Card, Descriptions, Tag, Space, Typography, Row, Col, Steps, Rate, Divider } from 'antd';
import {
    MessageOutlined,
    FileTextOutlined,
    DollarOutlined,
    RocketOutlined,
    CheckCircleOutlined,
} from '@ant-design/icons';
import { useShow } from '@refinedev/core';
import dayjs from 'dayjs';

import type { MarketplaceOrder, OrderStatus } from '@/types';

const { Title, Text, Paragraph } = Typography;

const statusStepMap: Record<OrderStatus, number> = {
    INQUIRY: 0,
    QUOTED: 1,
    PENDING_PAYMENT: 2,
    PAID: 3,
    IN_PROGRESS: 4,
    DELIVERED: 5,
    COMPLETED: 6,
    DISPUTED: -1,
    CANCELLED: -1,
    REFUNDED: -1,
};

export const OrderShow: React.FC = () => {
    const { queryResult } = useShow<MarketplaceOrder>({
        meta: {
            fields: [
                'id',
                'reference',
                'status',
                'requirements',
                'quoted_amount',
                'agreed_amount',
                'currency',
                'delivery_date',
                'delivered_at',
                'delivery_notes',
                'payment_status',
                'payment_reference',
                'paid_at',
                'customer_rating',
                'customer_review',
                'reviewed_at',
                'last_message_at',
                'message_count',
                'created_at',
                'updated_at',
                {
                    listing: ['id', 'title', 'images'],
                },
                {
                    provider: ['id', 'business_name', 'logo_url', 'phone_primary', 'email'],
                },
            ],
        },
    });

    const { data, isLoading } = queryResult;
    const record = data?.data as any;

    const currentStep = statusStepMap[record?.status as OrderStatus] ?? 0;
    const isFailed = ['DISPUTED', 'CANCELLED', 'REFUNDED'].includes(record?.status);

    return (
        <Show isLoading={isLoading}>
            <Space direction="vertical" size="large" style={{ width: '100%' }}>
                {/* Status Steps */}
                <Card>
                    <Steps
                        current={currentStep}
                        status={isFailed ? 'error' : undefined}
                        items={[
                            { title: 'Inquiry', icon: <MessageOutlined /> },
                            { title: 'Quoted', icon: <FileTextOutlined /> },
                            { title: 'Payment', icon: <DollarOutlined /> },
                            { title: 'Paid', icon: <DollarOutlined /> },
                            { title: 'In Progress', icon: <RocketOutlined /> },
                            { title: 'Delivered', icon: <RocketOutlined /> },
                            { title: 'Completed', icon: <CheckCircleOutlined /> },
                        ]}
                    />
                </Card>

                <Row gutter={16}>
                    <Col span={16}>
                        {/* Order Details */}
                        <Card title="Order Details">
                            <Descriptions column={2}>
                                <Descriptions.Item label="Reference">
                                    <Text strong copyable>{record?.reference}</Text>
                                </Descriptions.Item>
                                <Descriptions.Item label="Status">
                                    <Tag color={isFailed ? 'error' : 'processing'}>
                                        {record?.status?.replace(/_/g, ' ')}
                                    </Tag>
                                </Descriptions.Item>
                                <Descriptions.Item label="Service">
                                    {record?.listing?.title}
                                </Descriptions.Item>
                                <Descriptions.Item label="Provider">
                                    {record?.provider?.business_name}
                                </Descriptions.Item>
                                <Descriptions.Item label="Created">
                                    {dayjs(record?.created_at).format('YYYY-MM-DD HH:mm')}
                                </Descriptions.Item>
                                <Descriptions.Item label="Delivery Date">
                                    {record?.delivery_date ? dayjs(record.delivery_date).format('YYYY-MM-DD') : '-'}
                                </Descriptions.Item>
                            </Descriptions>
                        </Card>

                        {/* Requirements */}
                        {record?.requirements && (
                            <Card title="Requirements" style={{ marginTop: 16 }}>
                                <Paragraph>{record.requirements}</Paragraph>
                            </Card>
                        )}

                        {/* Payment */}
                        <Card title="Payment" style={{ marginTop: 16 }}>
                            <Descriptions column={2}>
                                <Descriptions.Item label="Quoted Amount">
                                    {record?.quoted_amount ? `₦${record.quoted_amount.toLocaleString()}` : '-'}
                                </Descriptions.Item>
                                <Descriptions.Item label="Agreed Amount">
                                    {record?.agreed_amount ? (
                                        <Text strong style={{ fontSize: 16 }}>₦{record.agreed_amount.toLocaleString()}</Text>
                                    ) : '-'}
                                </Descriptions.Item>
                                <Descriptions.Item label="Payment Status">
                                    <Tag color={record?.payment_status === 'PAID' ? 'success' : 'default'}>
                                        {record?.payment_status || 'PENDING'}
                                    </Tag>
                                </Descriptions.Item>
                                <Descriptions.Item label="Paid At">
                                    {record?.paid_at ? dayjs(record.paid_at).format('YYYY-MM-DD HH:mm') : '-'}
                                </Descriptions.Item>
                            </Descriptions>
                        </Card>

                        {/* Review */}
                        {record?.customer_rating && (
                            <Card title="Customer Review" style={{ marginTop: 16 }}>
                                <Space direction="vertical">
                                    <Rate disabled defaultValue={record.customer_rating} />
                                    {record.customer_review && <Paragraph>{record.customer_review}</Paragraph>}
                                    <Text type="secondary">
                                        Reviewed on {dayjs(record.reviewed_at).format('YYYY-MM-DD')}
                                    </Text>
                                </Space>
                            </Card>
                        )}
                    </Col>

                    <Col span={8}>
                        {/* Provider Card */}
                        <Card title="Provider">
                            <Space direction="vertical" style={{ width: '100%' }}>
                                <Text strong>{record?.provider?.business_name}</Text>
                                {record?.provider?.phone_primary && (
                                    <Text>📞 {record.provider.phone_primary}</Text>
                                )}
                                {record?.provider?.email && (
                                    <Text>📧 {record.provider.email}</Text>
                                )}
                            </Space>
                        </Card>

                        {/* Communication */}
                        <Card title="Communication" style={{ marginTop: 16 }}>
                            <Descriptions column={1}>
                                <Descriptions.Item label="Messages">
                                    {record?.message_count || 0}
                                </Descriptions.Item>
                                <Descriptions.Item label="Last Message">
                                    {record?.last_message_at
                                        ? dayjs(record.last_message_at).fromNow()
                                        : 'No messages'}
                                </Descriptions.Item>
                            </Descriptions>
                        </Card>
                    </Col>
                </Row>
            </Space>
        </Show>
    );
};

export default OrderShow;
