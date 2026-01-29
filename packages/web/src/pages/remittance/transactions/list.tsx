import { List, useTable, FilterDropdown } from '@refinedev/antd';
import { Table, Tag, Space, Typography, Input, Select, Button, Tooltip } from 'antd';
import { EyeOutlined, SearchOutlined } from '@ant-design/icons';
import { useNavigation } from '@refinedev/core';
import dayjs from 'dayjs';

import type { RemittanceTransaction, TransferStatus } from '@/types';

const { Text } = Typography;

const statusColors: Record<TransferStatus, string> = {
    PENDING: 'default',
    AWAITING_PAYMENT: 'gold',
    PAYMENT_RECEIVED: 'cyan',
    PROCESSING: 'processing',
    SENT_TO_BANK: 'blue',
    COMPLETED: 'success',
    FAILED: 'error',
    REFUNDED: 'purple',
    CANCELLED: 'default',
};

export const TransactionList: React.FC = () => {
    const { show } = useNavigation();

    const { tableProps, sorters } = useTable<RemittanceTransaction>({
        resource: 'remittance_transactions',
        sorters: {
            initial: [{ field: 'initiated_at', order: 'desc' }],
        },
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
                'status',
                'purpose',
                'recipient_account_name',
                'recipient_bank_code',
                'initiated_at',
                'completed_at',
            ],
        },
    });

    const columns = [
        {
            title: 'Reference',
            dataIndex: 'reference',
            key: 'reference',
            filterDropdown: (props: any) => (
                <FilterDropdown {...props}>
                    <Input placeholder="Search reference" prefix={<SearchOutlined />} />
                </FilterDropdown>
            ),
            render: (value: string) => <Text strong copyable>{value}</Text>,
        },
        {
            title: 'Amount Sent',
            key: 'amount_sent',
            render: (_: unknown, record: any) => (
                <Text strong>
                    {record.currency_sent} {record.amount_sent?.toLocaleString(undefined, { minimumFractionDigits: 2 })}
                </Text>
            ),
        },
        {
            title: 'Amount Received',
            key: 'amount_received',
            render: (_: unknown, record: any) => (
                <Text type="success">
                    ₦{record.amount_received?.toLocaleString(undefined, { minimumFractionDigits: 2 })}
                </Text>
            ),
        },
        {
            title: 'Recipient',
            key: 'recipient',
            render: (_: unknown, record: any) => (
                <Space direction="vertical" size={0}>
                    <Text>{record.recipient_account_name}</Text>
                    <Text type="secondary" style={{ fontSize: 11 }}>{record.recipient_bank_code}</Text>
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
                        options={Object.keys(statusColors).map((s) => ({ label: s.replace('_', ' '), value: s }))}
                    />
                </FilterDropdown>
            ),
            render: (value: TransferStatus) => (
                <Tag color={statusColors[value]}>{value.replace(/_/g, ' ')}</Tag>
            ),
        },
        {
            title: 'Purpose',
            dataIndex: 'purpose',
            key: 'purpose',
            render: (value: string) => <Tag>{value?.replace('_', ' ')}</Tag>,
        },
        {
            title: 'Date',
            dataIndex: 'initiated_at',
            key: 'initiated_at',
            sorter: true,
            render: (value: string) => (
                <Tooltip title={dayjs(value).format('YYYY-MM-DD HH:mm:ss')}>
                    <Text>{dayjs(value).fromNow()}</Text>
                </Tooltip>
            ),
        },
        {
            title: 'Actions',
            key: 'actions',
            render: (_: unknown, record: RemittanceTransaction) => (
                <Button
                    type="text"
                    icon={<EyeOutlined />}
                    onClick={() => show('transactions', record.id)}
                />
            ),
        },
    ];

    return (
        <List title="Remittance Transactions">
            <Table
                {...tableProps}
                rowKey="id"
                columns={columns}
                pagination={{
                    ...tableProps.pagination,
                    showSizeChanger: true,
                    showTotal: (total) => `Total ${total} transactions`,
                }}
            />
        </List>
    );
};

export default TransactionList;
