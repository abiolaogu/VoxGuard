import { List, useTable, FilterDropdown, getDefaultSortOrder } from '@refinedev/antd';
import { Table, Tag, Space, Typography, Input, Select, DatePicker, Button, Tooltip } from 'antd';
import { EyeOutlined, SearchOutlined, ReloadOutlined } from '@ant-design/icons';
import { useNavigation, useSubscription } from '@refinedev/core';
import dayjs from 'dayjs';

import type { FraudAlert, Severity, AlertStatus, FraudType } from '@/types';

const { Text } = Typography;
const { RangePicker } = DatePicker;

const severityColors: Record<Severity, string> = {
    LOW: 'blue',
    MEDIUM: 'gold',
    HIGH: 'orange',
    CRITICAL: 'red',
};

const statusColors: Record<AlertStatus, string> = {
    PENDING: 'default',
    ACKNOWLEDGED: 'processing',
    INVESTIGATING: 'warning',
    RESOLVED: 'success',
    REPORTED_NCC: 'purple',
};

export const FraudAlertList: React.FC = () => {
    const { show } = useNavigation();

    const { tableProps, sorters, filters, setFilters, tableQueryResult } = useTable<FraudAlert>({
        resource: 'fraud_alerts',
        sorters: {
            initial: [{ field: 'detected_at', order: 'desc' }],
        },
        meta: {
            fields: [
                'id',
                'b_number',
                'fraud_type',
                'score',
                'severity',
                'distinct_callers',
                'status',
                'ncc_reported',
                'detected_at',
                'updated_at',
            ],
        },
        liveMode: 'auto',
    });

    // Real-time subscription
    useSubscription({
        channel: 'fraud_alerts',
        onLiveEvent: () => {
            tableQueryResult.refetch();
        },
    });

    const columns = [
        {
            title: 'B-Number',
            dataIndex: 'b_number',
            key: 'b_number',
            filterDropdown: (props: any) => (
                <FilterDropdown {...props}>
                    <Input placeholder="Search B-Number" prefix={<SearchOutlined />} />
                </FilterDropdown>
            ),
            render: (value: string) => <Text strong copyable>{value}</Text>,
        },
        {
            title: 'Type',
            dataIndex: 'fraud_type',
            key: 'fraud_type',
            filterDropdown: (props: any) => (
                <FilterDropdown {...props}>
                    <Select
                        mode="multiple"
                        placeholder="Select type"
                        style={{ width: 200 }}
                        options={[
                            { label: 'CLI Masking', value: 'CLI_MASKING' },
                            { label: 'SIM Box', value: 'SIMBOX' },
                            { label: 'Wangiri', value: 'WANGIRI' },
                            { label: 'IRSF', value: 'IRSF' },
                            { label: 'PBX Hacking', value: 'PBX_HACKING' },
                        ]}
                    />
                </FilterDropdown>
            ),
            render: (value: FraudType) => (
                <Tag>{value.replace('_', ' ')}</Tag>
            ),
        },
        {
            title: 'Score',
            dataIndex: 'score',
            key: 'score',
            sorter: true,
            defaultSortOrder: getDefaultSortOrder('score', sorters),
            render: (value: number) => (
                <Text
                    style={{
                        color: value >= 0.8 ? '#ff4d4f' : value >= 0.5 ? '#faad14' : '#52c41a',
                    }}
                >
                    {(value * 100).toFixed(0)}%
                </Text>
            ),
        },
        {
            title: 'Severity',
            dataIndex: 'severity',
            key: 'severity',
            filterDropdown: (props: any) => (
                <FilterDropdown {...props}>
                    <Select
                        mode="multiple"
                        placeholder="Select severity"
                        style={{ width: 150 }}
                        options={[
                            { label: 'Low', value: 'LOW' },
                            { label: 'Medium', value: 'MEDIUM' },
                            { label: 'High', value: 'HIGH' },
                            { label: 'Critical', value: 'CRITICAL' },
                        ]}
                    />
                </FilterDropdown>
            ),
            render: (value: Severity) => (
                <Tag color={severityColors[value]}>{value}</Tag>
            ),
        },
        {
            title: 'Callers',
            dataIndex: 'distinct_callers',
            key: 'distinct_callers',
            sorter: true,
            render: (value: number) => <Text>{value}</Text>,
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
                        options={[
                            { label: 'Pending', value: 'PENDING' },
                            { label: 'Acknowledged', value: 'ACKNOWLEDGED' },
                            { label: 'Investigating', value: 'INVESTIGATING' },
                            { label: 'Resolved', value: 'RESOLVED' },
                            { label: 'Reported NCC', value: 'REPORTED_NCC' },
                        ]}
                    />
                </FilterDropdown>
            ),
            render: (value: AlertStatus) => (
                <Tag color={statusColors[value]}>{value.replace('_', ' ')}</Tag>
            ),
        },
        {
            title: 'NCC',
            dataIndex: 'ncc_reported',
            key: 'ncc_reported',
            render: (value: boolean) =>
                value ? <Tag color="purple">Reported</Tag> : <Tag>Not Reported</Tag>,
        },
        {
            title: 'Detected',
            dataIndex: 'detected_at',
            key: 'detected_at',
            sorter: true,
            defaultSortOrder: getDefaultSortOrder('detected_at', sorters),
            render: (value: string) => (
                <Tooltip title={dayjs(value).format('YYYY-MM-DD HH:mm:ss')}>
                    <Text>{dayjs(value).fromNow()}</Text>
                </Tooltip>
            ),
        },
        {
            title: 'Actions',
            key: 'actions',
            render: (_: unknown, record: FraudAlert) => (
                <Space>
                    <Button
                        type="primary"
                        icon={<EyeOutlined />}
                        size="small"
                        onClick={() => show('fraud-alerts', record.id)}
                    >
                        View
                    </Button>
                </Space>
            ),
        },
    ];

    return (
        <List
            title="Fraud Alerts"
            headerButtons={
                <Button
                    icon={<ReloadOutlined />}
                    onClick={() => tableQueryResult.refetch()}
                >
                    Refresh
                </Button>
            }
        >
            <Table
                {...tableProps}
                rowKey="id"
                columns={columns}
                pagination={{
                    ...tableProps.pagination,
                    showSizeChanger: true,
                    showTotal: (total) => `Total ${total} alerts`,
                }}
                rowClassName={(record: any) =>
                    record.severity === 'CRITICAL' && record.status === 'PENDING'
                        ? 'ant-table-row-critical'
                        : ''
                }
            />
        </List>
    );
};

export default FraudAlertList;
