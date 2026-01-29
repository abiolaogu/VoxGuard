import { List, useTable, FilterDropdown, getDefaultSortOrder } from '@refinedev/antd';
import { Table, Tag, Space, Typography, Input, Select, DatePicker, Button, Tooltip } from 'antd';
import { EyeOutlined, SearchOutlined } from '@ant-design/icons';
import { useNavigation } from '@refinedev/core';
import dayjs from 'dayjs';

import type { Call, CallStatus } from '@/types';

const { Text } = Typography;
const { RangePicker } = DatePicker;

const statusColors: Record<CallStatus, string> = {
    RINGING: 'processing',
    ACTIVE: 'blue',
    COMPLETED: 'success',
    FAILED: 'error',
    BLOCKED: 'red',
};

export const CallList: React.FC = () => {
    const { show } = useNavigation();

    const { tableProps, sorters } = useTable<Call>({
        resource: 'call_verifications',
        sorters: {
            initial: [{ field: 'started_at', order: 'desc' }],
        },
        meta: {
            fields: [
                'id',
                'call_id',
                'a_number',
                'b_number',
                'source_ip',
                'status',
                'is_flagged',
                'masking_detected',
                'confidence_score',
                'started_at',
                'duration_seconds',
                { gateway: ['name'] },
            ],
        },
        liveMode: 'auto',
    });

    const columns = [
        {
            title: 'A-Number',
            dataIndex: 'a_number',
            key: 'a_number',
            filterDropdown: (props: any) => (
                <FilterDropdown {...props}>
                    <Input placeholder="Search A-Number" prefix={<SearchOutlined />} />
                </FilterDropdown>
            ),
            render: (value: string) => <Text copyable={{ text: value }}>{value}</Text>,
        },
        {
            title: 'B-Number',
            dataIndex: 'b_number',
            key: 'b_number',
            filterDropdown: (props: any) => (
                <FilterDropdown {...props}>
                    <Input placeholder="Search B-Number" prefix={<SearchOutlined />} />
                </FilterDropdown>
            ),
            render: (value: string) => <Text copyable={{ text: value }}>{value}</Text>,
        },
        {
            title: 'Gateway',
            key: 'gateway',
            render: (_: unknown, record: any) => record.gateway?.name || '-',
        },
        {
            title: 'Source IP',
            dataIndex: 'source_ip',
            key: 'source_ip',
            render: (value: string) => <Text code>{value}</Text>,
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
                        options={[
                            { label: 'Ringing', value: 'RINGING' },
                            { label: 'Active', value: 'ACTIVE' },
                            { label: 'Completed', value: 'COMPLETED' },
                            { label: 'Failed', value: 'FAILED' },
                            { label: 'Blocked', value: 'BLOCKED' },
                        ]}
                    />
                </FilterDropdown>
            ),
            render: (value: CallStatus) => (
                <Tag color={statusColors[value]}>{value}</Tag>
            ),
        },
        {
            title: 'Flagged',
            key: 'flagged',
            render: (_: unknown, record: any) => (
                <Space>
                    {record.is_flagged && <Tag color="warning">Flagged</Tag>}
                    {record.masking_detected && <Tag color="error">Masking</Tag>}
                </Space>
            ),
        },
        {
            title: 'Score',
            dataIndex: 'confidence_score',
            key: 'confidence_score',
            sorter: true,
            render: (value: number) =>
                value != null ? (
                    <Text
                        style={{
                            color: value >= 0.8 ? '#ff4d4f' : value >= 0.5 ? '#faad14' : '#52c41a',
                        }}
                    >
                        {(value * 100).toFixed(0)}%
                    </Text>
                ) : (
                    '-'
                ),
        },
        {
            title: 'Duration',
            dataIndex: 'duration_seconds',
            key: 'duration_seconds',
            render: (value: number) =>
                value != null ? `${Math.floor(value / 60)}:${String(value % 60).padStart(2, '0')}` : '-',
        },
        {
            title: 'Started',
            dataIndex: 'started_at',
            key: 'started_at',
            sorter: true,
            defaultSortOrder: getDefaultSortOrder('started_at', sorters),
            render: (value: string) => (
                <Tooltip title={dayjs(value).format('YYYY-MM-DD HH:mm:ss')}>
                    <Text>{dayjs(value).fromNow()}</Text>
                </Tooltip>
            ),
        },
        {
            title: 'Actions',
            key: 'actions',
            render: (_: unknown, record: Call) => (
                <Button
                    type="text"
                    icon={<EyeOutlined />}
                    onClick={() => show('calls', record.id)}
                />
            ),
        },
    ];

    return (
        <List title="Call Log">
            <Table
                {...tableProps}
                rowKey="id"
                columns={columns}
                pagination={{
                    ...tableProps.pagination,
                    showSizeChanger: true,
                    showTotal: (total) => `Total ${total} calls`,
                }}
                rowClassName={(record: any) =>
                    record.masking_detected ? 'ant-table-row-error' : ''
                }
            />
        </List>
    );
};

export default CallList;
