
import {
    List,
    useTable,
    ShowButton,
    DateField,
} from '@refinedev/antd';
import { Table, Space, Tag, Typography } from 'antd';

const { Text } = Typography;

interface WangiriAlert {
    id: string;
    b_number: string;
    a_number_range: string;
    missed_calls: number;
    avg_ring_duration_sec: number;
    callbacks_count: number;
    severity: 'critical' | 'high' | 'medium';
    status: 'active' | 'blocked';
    created_at: string;
}

export const WangiriList: React.FC = () => {
    const { tableProps } = useTable<WangiriAlert>({
        resource: 'acm_alerts',
        filters: {
            permanent: [
                {
                    field: 'detection_type',
                    operator: 'eq',
                    value: 'WANGIRI',
                },
            ],
        },
    });

    const columns = [
        {
            title: 'Target Range (A-Num)',
            dataIndex: 'a_number_range',
            key: 'a_number_range',
            render: (value: string) => <Text code>{value}</Text>,
        },
        {
            title: 'Missed Calls',
            dataIndex: 'missed_calls',
            key: 'missed_calls',
            render: (value: number) => <Text strong>{value}</Text>,
        },
        {
            title: 'Avg Ring (sec)',
            dataIndex: 'avg_ring_duration_sec',
            key: 'avg_ring_duration_sec',
            render: (value: number) => (
                <Text type={value < 2 ? 'danger' : 'warning'}>{value}s</Text>
            ),
        },
        {
            title: 'Callbacks',
            dataIndex: 'callbacks_count',
            key: 'callbacks_count',
            render: (value: number) => <Text>{value}</Text>,
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
            render: (_: unknown, record: WangiriAlert) => (
                <Space size="small">
                    <ShowButton hideText size="small" recordItemId={record.id} resource="acm_alerts" />
                </Space>
            ),
        },
    ];

    return (
        <List title="Wangiri Campaigns" resource="acm_alerts">
            <Table {...tableProps} columns={columns} rowKey="id" />
        </List>
    );
};
