import { List, useTable } from '@refinedev/antd';
import { Table, Tag, Space, Typography, Card, Statistic, Row, Col } from 'antd';
import { ArrowRightOutlined } from '@ant-design/icons';

import type { RemittanceCorridor } from '@/types';

const { Text } = Typography;

export const CorridorList: React.FC = () => {
    const { tableProps } = useTable<RemittanceCorridor>({
        resource: 'remittance_corridors',
        filters: {
            initial: [{ field: 'is_active', operator: 'eq', value: true }],
        },
        meta: {
            fields: [
                'id',
                'source_country',
                'destination_country',
                'source_currency',
                'destination_currency',
                'exchange_rate',
                'fee_structure',
                'min_amount',
                'max_amount',
                'processing_time_hours',
                'is_active',
            ],
        },
    });

    const columns = [
        {
            title: 'Corridor',
            key: 'corridor',
            render: (_: unknown, record: any) => (
                <Space>
                    <Tag color="blue">{record.source_country}</Tag>
                    <ArrowRightOutlined />
                    <Tag color="green">{record.destination_country}</Tag>
                </Space>
            ),
        },
        {
            title: 'Currencies',
            key: 'currencies',
            render: (_: unknown, record: any) => (
                <Space>
                    <Text strong>{record.source_currency}</Text>
                    <ArrowRightOutlined />
                    <Text strong>{record.destination_currency}</Text>
                </Space>
            ),
        },
        {
            title: 'Exchange Rate',
            dataIndex: 'exchange_rate',
            key: 'exchange_rate',
            render: (value: number, record: any) => (
                <Space direction="vertical" size={0}>
                    <Text strong>1 {record.source_currency} = {value.toLocaleString()} {record.destination_currency}</Text>
                </Space>
            ),
        },
        {
            title: 'Fees',
            key: 'fees',
            render: (_: unknown, record: any) => {
                const fees = record.fee_structure;
                return (
                    <Space direction="vertical" size={0}>
                        <Text>Flat: ${fees?.flat_fee || 0}</Text>
                        <Text type="secondary">{((fees?.percentage_fee || 0) * 100).toFixed(1)}% (max ${fees?.max_fee || '-'})</Text>
                    </Space>
                );
            },
        },
        {
            title: 'Limits',
            key: 'limits',
            render: (_: unknown, record: any) => (
                <Space direction="vertical" size={0}>
                    <Text>Min: ${record.min_amount}</Text>
                    <Text>Max: ${record.max_amount?.toLocaleString()}</Text>
                </Space>
            ),
        },
        {
            title: 'Processing',
            dataIndex: 'processing_time_hours',
            key: 'processing_time_hours',
            render: (value: number) => (
                <Tag color={value <= 1 ? 'green' : value <= 24 ? 'blue' : 'orange'}>
                    {value <= 1 ? 'Instant' : value < 24 ? `${value}h` : `${Math.round(value / 24)}d`}
                </Tag>
            ),
        },
        {
            title: 'Status',
            dataIndex: 'is_active',
            key: 'is_active',
            render: (value: boolean) => (
                <Tag color={value ? 'success' : 'default'}>{value ? 'Active' : 'Inactive'}</Tag>
            ),
        },
    ];

    return (
        <List title="Remittance Corridors">
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

export default CorridorList;
