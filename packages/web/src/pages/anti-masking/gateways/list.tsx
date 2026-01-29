import { List, useTable, FilterDropdown, getDefaultSortOrder } from '@refinedev/antd';
import { Table, Tag, Space, Typography, Input, Select, Button, Progress, Tooltip, Modal } from 'antd';
import {
    PlusOutlined,
    EditOutlined,
    StopOutlined,
    CheckCircleOutlined,
    SearchOutlined,
} from '@ant-design/icons';
import { useNavigation, useUpdate } from '@refinedev/core';

import type { Gateway, GatewayType } from '@/types';

const { Text } = Typography;

const gatewayTypeColors: Record<GatewayType, string> = {
    LOCAL: 'green',
    INTERNATIONAL: 'blue',
    TRANSIT: 'purple',
};

export const GatewayList: React.FC = () => {
    const { create, edit } = useNavigation();
    const { mutate: update } = useUpdate();

    const { tableProps, sorters } = useTable<Gateway>({
        resource: 'gateways',
        sorters: {
            initial: [{ field: 'name', order: 'asc' }],
        },
        meta: {
            fields: [
                'id',
                'name',
                'ip_address',
                'carrier_name',
                'gateway_type',
                'is_active',
                'is_blacklisted',
                'blacklist_reason',
                'fraud_threshold',
                'cpm_limit',
                'acd_threshold',
                'total_calls',
                'fraud_calls',
                'created_at',
            ],
        },
    });

    const handleBlacklist = (gateway: Gateway) => {
        Modal.confirm({
            title: 'Blacklist Gateway',
            content: `Are you sure you want to blacklist ${gateway.name}?`,
            onOk: () => {
                update({
                    resource: 'gateways',
                    id: gateway.id,
                    values: {
                        is_blacklisted: true,
                        blacklisted_at: new Date().toISOString(),
                    },
                });
            },
        });
    };

    const handleActivate = (gateway: Gateway, active: boolean) => {
        update({
            resource: 'gateways',
            id: gateway.id,
            values: { is_active: active },
        });
    };

    const handleUnblacklist = (gateway: Gateway) => {
        update({
            resource: 'gateways',
            id: gateway.id,
            values: {
                is_blacklisted: false,
                blacklist_reason: null,
                blacklisted_at: null,
            },
        });
    };

    const columns = [
        {
            title: 'Name',
            dataIndex: 'name',
            key: 'name',
            sorter: true,
            filterDropdown: (props: any) => (
                <FilterDropdown {...props}>
                    <Input placeholder="Search name" prefix={<SearchOutlined />} />
                </FilterDropdown>
            ),
            render: (value: string, record: any) => (
                <Space direction="vertical" size={0}>
                    <Text strong>{value}</Text>
                    <Text type="secondary" style={{ fontSize: 12 }}>
                        {record.ip_address}
                    </Text>
                </Space>
            ),
        },
        {
            title: 'Carrier',
            dataIndex: 'carrier_name',
            key: 'carrier_name',
            render: (value: string) => value || '-',
        },
        {
            title: 'Type',
            dataIndex: 'gateway_type',
            key: 'gateway_type',
            filterDropdown: (props: any) => (
                <FilterDropdown {...props}>
                    <Select
                        mode="multiple"
                        placeholder="Select type"
                        style={{ width: 150 }}
                        options={[
                            { label: 'Local', value: 'LOCAL' },
                            { label: 'International', value: 'INTERNATIONAL' },
                            { label: 'Transit', value: 'TRANSIT' },
                        ]}
                    />
                </FilterDropdown>
            ),
            render: (value: GatewayType) => (
                <Tag color={gatewayTypeColors[value]}>{value}</Tag>
            ),
        },
        {
            title: 'Status',
            key: 'status',
            render: (_: unknown, record: any) => (
                <Space>
                    {record.is_blacklisted ? (
                        <Tooltip title={record.blacklist_reason}>
                            <Tag color="error">Blacklisted</Tag>
                        </Tooltip>
                    ) : record.is_active ? (
                        <Tag color="success">Active</Tag>
                    ) : (
                        <Tag color="default">Inactive</Tag>
                    )}
                </Space>
            ),
        },
        {
            title: 'Fraud Rate',
            key: 'fraud_rate',
            sorter: true,
            render: (_: unknown, record: any) => {
                const fraudRate = record.total_calls > 0
                    ? (record.fraud_calls / record.total_calls) * 100
                    : 0;
                const threshold = record.fraud_threshold * 100;
                return (
                    <Space direction="vertical" size={0} style={{ width: 100 }}>
                        <Progress
                            percent={fraudRate}
                            size="small"
                            strokeColor={fraudRate > threshold ? '#ff4d4f' : '#52c41a'}
                            format={() => `${fraudRate.toFixed(1)}%`}
                        />
                        <Text type="secondary" style={{ fontSize: 10 }}>
                            Threshold: {threshold}%
                        </Text>
                    </Space>
                );
            },
        },
        {
            title: 'Calls',
            dataIndex: 'total_calls',
            key: 'total_calls',
            sorter: true,
            render: (value: number, record: any) => (
                <Space direction="vertical" size={0}>
                    <Text>{value?.toLocaleString() || 0}</Text>
                    <Text type="secondary" style={{ fontSize: 11 }}>
                        {record.fraud_calls || 0} flagged
                    </Text>
                </Space>
            ),
        },
        {
            title: 'Limits',
            key: 'limits',
            render: (_: unknown, record: any) => (
                <Space direction="vertical" size={0}>
                    <Text style={{ fontSize: 12 }}>CPM: {record.cpm_limit}</Text>
                    <Text style={{ fontSize: 12 }}>ACD: {record.acd_threshold}s</Text>
                </Space>
            ),
        },
        {
            title: 'Actions',
            key: 'actions',
            render: (_: unknown, record: any) => (
                <Space>
                    <Button
                        type="text"
                        icon={<EditOutlined />}
                        onClick={() => edit('gateways', record.id)}
                    />
                    {record.is_blacklisted ? (
                        <Button
                            type="text"
                            icon={<CheckCircleOutlined />}
                            onClick={() => handleUnblacklist(record)}
                        >
                            Unblock
                        </Button>
                    ) : (
                        <Button
                            type="text"
                            danger
                            icon={<StopOutlined />}
                            onClick={() => handleBlacklist(record)}
                        >
                            Blacklist
                        </Button>
                    )}
                </Space>
            ),
        },
    ];

    return (
        <List
            title="Gateways"
            createButtonProps={{
                onClick: () => create('gateways'),
                icon: <PlusOutlined />,
            }}
        >
            <Table
                {...tableProps}
                rowKey="id"
                columns={columns}
                pagination={{
                    ...tableProps.pagination,
                    showSizeChanger: true,
                }}
                rowClassName={(record: any) =>
                    record.is_blacklisted ? 'ant-table-row-error' : ''
                }
            />
        </List>
    );
};

export default GatewayList;
