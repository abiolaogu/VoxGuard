import {
  List,
  useTable,
  FilterDropdown,
  ShowButton,
  EditButton,
  DeleteButton,
  CreateButton,
} from '@refinedev/antd';
import { useCan } from '@refinedev/core';
import {
  Table,
  Space,
  Tag,
  Select,
  Avatar,
  Typography,
  Tooltip,
} from 'antd';
import {
  UserOutlined,
  CheckCircleOutlined,
  CloseCircleOutlined,
} from '@ant-design/icons';
import dayjs from 'dayjs';

import { ACM_COLORS } from '../../config/antd-theme';

const { Text } = Typography;

interface User {
  id: string;
  email: string;
  name: string;
  role: string;
  avatar?: string;
  is_active: boolean;
  last_login: string;
  created_at: string;
}

const roleColors: Record<string, string> = {
  admin: 'purple',
  analyst: 'blue',
  developer: 'green',
  viewer: 'default',
};

const roleOptions = [
  { label: 'Admin', value: 'admin' },
  { label: 'Analyst', value: 'analyst' },
  { label: 'Developer', value: 'developer' },
  { label: 'Viewer', value: 'viewer' },
];

export const UserList: React.FC = () => {
  const { tableProps } = useTable<User>({
    resource: 'acm_users',
    sorters: {
      initial: [{ field: 'created_at', order: 'desc' }],
    },
    pagination: {
      pageSize: 20,
    },
    syncWithLocation: true,
  });

  const { data: canCreate } = useCan({ resource: 'acm_users', action: 'create' });
  const { data: canEdit } = useCan({ resource: 'acm_users', action: 'edit' });
  const { data: canDelete } = useCan({ resource: 'acm_users', action: 'delete' });

  const columns = [
    {
      title: 'User',
      key: 'user',
      render: (_: unknown, record: User) => (
        <Space>
          <Avatar
            src={record.avatar}
            icon={<UserOutlined />}
            style={{ backgroundColor: ACM_COLORS.primary }}
          />
          <div>
            <Text strong>{record.name}</Text>
            <br />
            <Text type="secondary" style={{ fontSize: 12 }}>
              {record.email}
            </Text>
          </div>
        </Space>
      ),
    },
    {
      title: 'Role',
      dataIndex: 'role',
      key: 'role',
      width: 120,
      filterDropdown: (props: any) => (
        <FilterDropdown {...props}>
          <Select
            mode="multiple"
            placeholder="Select role"
            options={roleOptions}
            style={{ width: 200 }}
          />
        </FilterDropdown>
      ),
      render: (role: string) => (
        <Tag color={roleColors[role] || 'default'} style={{ textTransform: 'capitalize' }}>
          {role}
        </Tag>
      ),
    },
    {
      title: 'Status',
      dataIndex: 'is_active',
      key: 'is_active',
      width: 100,
      render: (isActive: boolean) =>
        isActive ? (
          <Tag color="success" icon={<CheckCircleOutlined />}>
            Active
          </Tag>
        ) : (
          <Tag color="default" icon={<CloseCircleOutlined />}>
            Inactive
          </Tag>
        ),
    },
    {
      title: 'Last Login',
      dataIndex: 'last_login',
      key: 'last_login',
      sorter: true,
      width: 160,
      render: (date: string) =>
        date ? (
          <Tooltip title={dayjs(date).format('YYYY-MM-DD HH:mm:ss')}>
            <Text type="secondary" style={{ fontSize: 12 }}>
              {dayjs(date).fromNow()}
            </Text>
          </Tooltip>
        ) : (
          <Text type="secondary" style={{ fontSize: 12 }}>
            Never
          </Text>
        ),
    },
    {
      title: 'Created',
      dataIndex: 'created_at',
      key: 'created_at',
      sorter: true,
      width: 140,
      render: (date: string) => (
        <Text type="secondary" style={{ fontSize: 12 }}>
          {dayjs(date).format('MMM DD, YYYY')}
        </Text>
      ),
    },
    {
      title: 'Actions',
      key: 'actions',
      fixed: 'right' as const,
      width: 120,
      render: (_: unknown, record: User) => (
        <Space size="small">
          <ShowButton hideText size="small" recordItemId={record.id} />
          {canEdit?.can && (
            <EditButton hideText size="small" recordItemId={record.id} />
          )}
          {canDelete?.can && (
            <DeleteButton hideText size="small" recordItemId={record.id} />
          )}
        </Space>
      ),
    },
  ];

  return (
    <List
      title="User Management"
      canCreate={canCreate?.can}
      headerButtons={({ createButtonProps }) =>
        canCreate?.can ? <CreateButton {...createButtonProps} /> : null
      }
    >
      <Table
        {...tableProps}
        columns={columns}
        rowKey="id"
        scroll={{ x: 900 }}
        size="middle"
      />
    </List>
  );
};

export default UserList;
