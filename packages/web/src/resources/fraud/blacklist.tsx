
import {
    List,
    useTable,
    DeleteButton,
    CreateButton,
    DateField,
} from '@refinedev/antd';
import { Table, Space, Tag, Typography } from 'antd';
import { StopOutlined } from '@ant-design/icons';

const { Text } = Typography;

interface BlacklistEntry {
    id: string;
    number: string;
    reason: string;
    added_by: string;
    created_at: string;
    source: string;
}

export const BlacklistList: React.FC = () => {
    const { tableProps } = useTable<BlacklistEntry>({
        resource: 'blacklist',
    });

    const columns = [
        {
            title: 'Blocked Number',
            dataIndex: 'number',
            key: 'number',
            render: (value: string) => (
                <Space>
                    <StopOutlined style={{ color: 'red' }} />
                    <Text strong delete>{value}</Text>
                </Space>
            ),
        },
        {
            title: 'Reason',
            dataIndex: 'reason',
            key: 'reason',
            render: (value: string) => <Tag color="red">{value}</Tag>,
        },
        {
            title: 'Source',
            dataIndex: 'source',
            key: 'source',
            render: (value: string) => <Tag>{value}</Tag>,
        },
        {
            title: 'Date Added',
            dataIndex: 'created_at',
            key: 'created_at',
            render: (value: string) => <DateField value={value} format="YYYY-MM-DD HH:mm" />,
        },
        {
            title: 'Actions',
            key: 'actions',
            render: (_: unknown, record: BlacklistEntry) => (
                <Space size="small">
                    <DeleteButton hideText size="small" recordItemId={record.id} />
                </Space>
            ),
        },
    ];

    return (
        <List
            title="Blacklisted Numbers"
            resource="blacklist"
            headerButtons={({ createButtonProps }) => (
                <CreateButton {...createButtonProps}>Block Number</CreateButton>
            )}
        >
            <Table {...tableProps} columns={columns} rowKey="id" />
        </List>
    );
};
