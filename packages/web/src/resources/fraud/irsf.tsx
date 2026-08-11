
import {
    List,
    useTable,
    ShowButton,
    DateField,
} from '@refinedev/antd';
import { Table, Space, Tag, Typography } from 'antd';
import { GlobalOutlined } from '@ant-design/icons';

const { Text } = Typography;

interface IRSFAlert {
    id: string;
    destination_country: string;
    destination_prefix: string;
    call_count: number;
    total_duration_min: number;
    estimated_cost: number;
    severity: 'critical' | 'high' | 'medium' | 'low';
    status: 'active' | 'investigating' | 'blocked';
    created_at: string;
}

export const IRSFList: React.FC = () => {
    const { tableProps } = useTable<IRSFAlert>({
        resource: 'acm_alerts',
        filters: {
            permanent: [
                {
                    field: 'detection_type',
                    operator: 'eq',
                    value: 'IRSF',
                },
            ],
        },
    });

    const columns = [
        {
            title: 'Destination',
            dataIndex: 'destination_country',
            key: 'destination_country',
            render: (value: string, record: IRSFAlert) => (
                <Space>
                    <GlobalOutlined />
                    <Text>{value} (+{record.destination_prefix})</Text>
                </Space>
            ),
        },
        {
            title: 'Volume',
            dataIndex: 'call_count',
            key: 'call_count',
            render: (value: number) => <Text strong>{value} calls</Text>,
        },
        {
            title: 'Duration (min)',
            dataIndex: 'total_duration_min',
            key: 'total_duration_min',
        },
        {
            title: 'Est. Loss',
            dataIndex: 'estimated_cost',
            key: 'estimated_cost',
            render: (value: number) => <Text type="danger">₦{value.toLocaleString()}</Text>,
        },
        {
            title: 'Severity',
            dataIndex: 'severity',
            key: 'severity',
            render: (value: string) => {
                const color = value === 'critical' ? 'red' : value === 'high' ? 'orange' : 'blue';
                return <Tag color={color}>{value.toUpperCase()}</Tag>;
            },
        },
        {
            title: 'Status',
            dataIndex: 'status',
            key: 'status',
            render: (value: string) => <Tag>{value.toUpperCase()}</Tag>,
        },
        {
            title: 'Detected At',
            dataIndex: 'created_at',
            key: 'created_at',
            render: (value: string) => <DateField value={value} format="YYYY-MM-DD HH:mm" />,
        },
        {
            title: 'Actions',
            key: 'actions',
            render: (_: unknown, record: IRSFAlert) => (
                <Space size="small">
                    <ShowButton hideText size="small" recordItemId={record.id} resource="acm_alerts" />
                </Space>
            ),
        },
    ];

    return (
        <List title="IRSF Detection" resource="acm_alerts">
            <Table {...tableProps} columns={columns} rowKey="id" />
        </List>
    );
};
