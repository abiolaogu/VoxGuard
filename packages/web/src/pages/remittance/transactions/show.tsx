import { Show } from '@refinedev/antd';
import { Card, Descriptions, Tag, Typography, Row, Col, Timeline, Steps, Divider } from 'antd';
import {
    ClockCircleOutlined,
    DollarOutlined,
    BankOutlined,
    CheckCircleOutlined,
    LoadingOutlined,
} from '@ant-design/icons';
import { useShow } from '@refinedev/core';
import dayjs from 'dayjs';

import type { RemittanceTransaction, TransferStatus } from '@/types';

const { Text, Title } = Typography;

const statusStepMap: Record<TransferStatus, number> = {
    PENDING: 0,
    AWAITING_PAYMENT: 1,
    PAYMENT_RECEIVED: 2,
    PROCESSING: 3,
    SENT_TO_BANK: 4,
    COMPLETED: 5,
    FAILED: -1,
    REFUNDED: -1,
    CANCELLED: -1,
};

export const TransactionShow: React.FC = () => {
    const { queryResult } = useShow<RemittanceTransaction>({
        meta: {
            fields: [
                'id',
                'reference',
                'amount_sent',
                'currency_sent',
                'amount_received',
                'currency_received',
                'exchange_rate',
                'fee_amount',
                'total_paid',
                'status',
                'purpose',
                'narration',
                'recipient_bank_code',
                'recipient_account_number',
                'recipient_account_name',
                'recipient_phone',
                'payment_method',
                'payment_reference',
                'payment_received_at',
                'payout_reference',
                'initiated_at',
                'processing_at',
                'completed_at',
                'failed_at',
                'failure_reason',
                { beneficiary: ['first_name', 'last_name', 'relationship'] },
                { corridor: ['source_country', 'destination_country'] },
            ],
        },
    });

    const { data, isLoading } = queryResult;
    const record = data?.data as any;

    const currentStep = statusStepMap[record?.status as TransferStatus] ?? 0;
    const isFailed = ['FAILED', 'REFUNDED', 'CANCELLED'].includes(record?.status);

    return (
        <Show isLoading={isLoading}>
            {/* Status Steps */}
            <Card style={{ marginBottom: 16 }}>
                <Steps
                    current={currentStep}
                    status={isFailed ? 'error' : undefined}
                    items={[
                        { title: 'Initiated', icon: <ClockCircleOutlined /> },
                        { title: 'Awaiting Payment', icon: <DollarOutlined /> },
                        { title: 'Payment Received', icon: <DollarOutlined /> },
                        { title: 'Processing', icon: <LoadingOutlined /> },
                        { title: 'Sent to Bank', icon: <BankOutlined /> },
                        { title: 'Completed', icon: <CheckCircleOutlined /> },
                    ]}
                />
            </Card>

            <Row gutter={16}>
                <Col span={12}>
                    <Card title="Transfer Details">
                        <Descriptions column={1}>
                            <Descriptions.Item label="Reference">
                                <Text strong copyable style={{ fontSize: 16 }}>{record?.reference}</Text>
                            </Descriptions.Item>
                            <Descriptions.Item label="Status">
                                <Tag color={isFailed ? 'error' : 'processing'} style={{ fontSize: 14 }}>
                                    {record?.status?.replace(/_/g, ' ')}
                                </Tag>
                            </Descriptions.Item>
                            <Descriptions.Item label="Purpose">
                                <Tag>{record?.purpose?.replace('_', ' ')}</Tag>
                            </Descriptions.Item>
                            <Descriptions.Item label="Narration">
                                {record?.narration || '-'}
                            </Descriptions.Item>
                        </Descriptions>
                    </Card>

                    <Card title="Amounts" style={{ marginTop: 16 }}>
                        <Descriptions column={1}>
                            <Descriptions.Item label="Amount Sent">
                                <Text strong style={{ fontSize: 18 }}>
                                    {record?.currency_sent} {record?.amount_sent?.toLocaleString(undefined, { minimumFractionDigits: 2 })}
                                </Text>
                            </Descriptions.Item>
                            <Descriptions.Item label="Fee">
                                {record?.currency_sent} {record?.fee_amount?.toLocaleString(undefined, { minimumFractionDigits: 2 })}
                            </Descriptions.Item>
                            <Descriptions.Item label="Total Paid">
                                <Text strong>
                                    {record?.currency_sent} {record?.total_paid?.toLocaleString(undefined, { minimumFractionDigits: 2 })}
                                </Text>
                            </Descriptions.Item>
                            <Descriptions.Item label="Exchange Rate">
                                1 {record?.currency_sent} = {record?.exchange_rate?.toLocaleString()} {record?.currency_received}
                            </Descriptions.Item>
                            <Descriptions.Item label="Amount Received">
                                <Text type="success" style={{ fontSize: 18 }}>
                                    ₦{record?.amount_received?.toLocaleString(undefined, { minimumFractionDigits: 2 })}
                                </Text>
                            </Descriptions.Item>
                        </Descriptions>
                    </Card>
                </Col>

                <Col span={12}>
                    <Card title="Recipient Details">
                        <Descriptions column={1}>
                            <Descriptions.Item label="Account Name">
                                <Text strong>{record?.recipient_account_name}</Text>
                            </Descriptions.Item>
                            <Descriptions.Item label="Account Number">
                                <Text copyable>{record?.recipient_account_number}</Text>
                            </Descriptions.Item>
                            <Descriptions.Item label="Bank">
                                {record?.recipient_bank_code}
                            </Descriptions.Item>
                            <Descriptions.Item label="Phone">
                                {record?.recipient_phone || '-'}
                            </Descriptions.Item>
                            {record?.beneficiary && (
                                <>
                                    <Descriptions.Item label="Beneficiary">
                                        {record.beneficiary.first_name} {record.beneficiary.last_name}
                                    </Descriptions.Item>
                                    <Descriptions.Item label="Relationship">
                                        {record.beneficiary.relationship || '-'}
                                    </Descriptions.Item>
                                </>
                            )}
                        </Descriptions>
                    </Card>

                    <Card title="Timeline" style={{ marginTop: 16 }}>
                        <Timeline
                            items={[
                                {
                                    color: 'blue',
                                    children: `Initiated: ${dayjs(record?.initiated_at).format('YYYY-MM-DD HH:mm')}`,
                                },
                                ...(record?.payment_received_at
                                    ? [{
                                        color: 'cyan',
                                        children: `Payment Received: ${dayjs(record.payment_received_at).format('YYYY-MM-DD HH:mm')}`,
                                    }]
                                    : []),
                                ...(record?.processing_at
                                    ? [{
                                        color: 'blue',
                                        children: `Processing Started: ${dayjs(record.processing_at).format('YYYY-MM-DD HH:mm')}`,
                                    }]
                                    : []),
                                ...(record?.completed_at
                                    ? [{
                                        color: 'green',
                                        children: `Completed: ${dayjs(record.completed_at).format('YYYY-MM-DD HH:mm')}`,
                                    }]
                                    : []),
                                ...(record?.failed_at
                                    ? [{
                                        color: 'red',
                                        children: `Failed: ${dayjs(record.failed_at).format('YYYY-MM-DD HH:mm')} - ${record.failure_reason}`,
                                    }]
                                    : []),
                            ]}
                        />
                    </Card>
                </Col>
            </Row>
        </Show>
    );
};

export default TransactionShow;
