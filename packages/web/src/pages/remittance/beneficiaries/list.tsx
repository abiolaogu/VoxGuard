import { List, useTable, FilterDropdown } from '@refinedev/antd';
import { Table, Tag, Space, Typography, Input, Button, Avatar } from 'antd';
import { PlusOutlined, SearchOutlined, StarFilled, StarOutlined } from '@ant-design/icons';
import { useNavigation, useUpdate } from '@refinedev/core';

import type { Beneficiary } from '@/types';

const { Text } = Typography;

export const BeneficiaryList: React.FC = () => {
    const { create } = useNavigation();
    const { mutate: update } = useUpdate();

    const { tableProps } = useTable<Beneficiary>({
        resource: 'beneficiaries',
        sorters: {
            initial: [{ field: 'is_favorite', order: 'desc' }, { field: 'last_used_at', order: 'desc' }],
        },
        meta: {
            fields: [
                'id',
                'first_name',
                'last_name',
                'middle_name',
                'relationship',
                'bank_code',
                'account_number',
                'account_name',
                'is_verified',
                'is_favorite',
                'phone_number',
                'email',
                'created_at',
            ],
        },
    });

    const handleToggleFavorite = (beneficiary: any) => {
        update({
            resource: 'beneficiaries',
            id: beneficiary.id,
            values: { is_favorite: !beneficiary.is_favorite },
        });
    };

    const columns = [
        {
            title: 'Favorite',
            key: 'favorite',
            width: 60,
            render: (_: unknown, record: any) => (
                <Button
                    type="text"
                    icon={record.is_favorite ? <StarFilled style={{ color: '#faad14' }} /> : <StarOutlined />}
                    onClick={() => handleToggleFavorite(record)}
                />
            ),
        },
        {
            title: 'Name',
            key: 'name',
            filterDropdown: (props: any) => (
                <FilterDropdown {...props}>
                    <Input placeholder="Search name" prefix={<SearchOutlined />} />
                </FilterDropdown>
            ),
            render: (_: unknown, record: any) => (
                <Space>
                    <Avatar style={{ backgroundColor: '#1890ff' }}>
                        {record.first_name?.[0]}{record.last_name?.[0]}
                    </Avatar>
                    <Space direction="vertical" size={0}>
                        <Text strong>{record.first_name} {record.last_name}</Text>
                        {record.relationship && (
                            <Text type="secondary" style={{ fontSize: 11 }}>{record.relationship}</Text>
                        )}
                    </Space>
                </Space>
            ),
        },
        {
            title: 'Bank Account',
            key: 'bank',
            render: (_: unknown, record: any) => (
                <Space direction="vertical" size={0}>
                    <Text>{record.account_name}</Text>
                    <Text type="secondary" style={{ fontSize: 12 }}>
                        {record.bank_code} • {record.account_number}
                    </Text>
                </Space>
            ),
        },
        {
            title: 'Contact',
            key: 'contact',
            render: (_: unknown, record: any) => (
                <Space direction="vertical" size={0}>
                    {record.phone_number && <Text>{record.phone_number}</Text>}
                    {record.email && <Text type="secondary" style={{ fontSize: 11 }}>{record.email}</Text>}
                </Space>
            ),
        },
        {
            title: 'Status',
            key: 'status',
            render: (_: unknown, record: any) => (
                <Tag color={record.is_verified ? 'success' : 'default'}>
                    {record.is_verified ? 'Verified' : 'Unverified'}
                </Tag>
            ),
        },
    ];

    return (
        <List
            title="Beneficiaries"
            createButtonProps={{
                onClick: () => create('beneficiaries'),
                icon: <PlusOutlined />,
                children: 'Add Beneficiary',
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
            />
        </List>
    );
};

export default BeneficiaryList;
