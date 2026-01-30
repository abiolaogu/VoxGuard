import { Show } from '@refinedev/antd';
import { useShow, useCan } from '@refinedev/core';
import {
  Card,
  Row,
  Col,
  Descriptions,
  Tag,
  Typography,
  Avatar,
  Space,
  Button,
  Statistic,
  Divider,
  Spin,
  Alert,
} from 'antd';
import {
  UserOutlined,
  EditOutlined,
  MailOutlined,
  CalendarOutlined,
  SafetyCertificateOutlined,
} from '@ant-design/icons';
import { useNavigate } from 'react-router-dom';
import dayjs from 'dayjs';

import { VG_COLORS } from '../../config/antd-theme';

const { Title, Text } = Typography;

interface User {
  id: string;
  email: string;
  name: string;
  role: string;
  avatar?: string;
  is_active: boolean;
  last_login: string;
  created_at: string;
  updated_at: string;
  assigned_alerts?: {
    aggregate: {
      count: number;
    };
  };
}

const roleColors: Record<string, string> = {
  admin: 'purple',
  analyst: 'blue',
  developer: 'green',
  viewer: 'default',
};

const roleDescriptions: Record<string, string> = {
  admin: 'Full system access including user management and settings',
  analyst: 'Can view and manage alerts, access analytics',
  developer: 'Read-only access to alerts, analytics, and settings',
  viewer: 'Read-only access to alerts and analytics',
};

export const UserShow: React.FC = () => {
  const navigate = useNavigate();
  const { queryResult } = useShow<User>({
    resource: 'acm_users',
  });

  const { data: canEdit } = useCan({ resource: 'acm_users', action: 'edit' });

  const { data, isLoading, isError } = queryResult;
  const user = data?.data;

  if (isLoading) {
    return (
      <Show>
        <div style={{ textAlign: 'center', padding: 48 }}>
          <Spin size="large" />
        </div>
      </Show>
    );
  }

  if (isError || !user) {
    return (
      <Show>
        <Alert
          type="error"
          message="Error"
          description="Failed to load user details"
          showIcon
        />
      </Show>
    );
  }

  return (
    <Show
      headerButtons={
        canEdit?.can
          ? () => (
              <Button
                type="primary"
                icon={<EditOutlined />}
                onClick={() => navigate(`/users/edit/${user.id}`)}
              >
                Edit User
              </Button>
            )
          : undefined
      }
    >
      <Row gutter={[24, 24]}>
        {/* User Profile Card */}
        <Col xs={24} lg={8}>
          <Card bordered={false}>
            <div style={{ textAlign: 'center', marginBottom: 24 }}>
              <Avatar
                size={96}
                src={user.avatar}
                icon={<UserOutlined />}
                style={{ backgroundColor: VG_COLORS.primary }}
              />
              <Title level={4} style={{ marginTop: 16, marginBottom: 4 }}>
                {user.name}
              </Title>
              <Tag
                color={roleColors[user.role]}
                style={{ textTransform: 'capitalize' }}
              >
                {user.role}
              </Tag>
            </div>

            <Divider />

            <Space direction="vertical" style={{ width: '100%' }} size={12}>
              <div>
                <Space>
                  <MailOutlined style={{ color: VG_COLORS.textSecondary }} />
                  <Text>{user.email}</Text>
                </Space>
              </div>
              <div>
                <Space>
                  <CalendarOutlined style={{ color: VG_COLORS.textSecondary }} />
                  <Text type="secondary">
                    Joined {dayjs(user.created_at).format('MMM DD, YYYY')}
                  </Text>
                </Space>
              </div>
              <div>
                <Space>
                  <SafetyCertificateOutlined style={{ color: VG_COLORS.textSecondary }} />
                  <Text type="secondary">
                    {user.is_active ? (
                      <Tag color="success">Active</Tag>
                    ) : (
                      <Tag color="default">Inactive</Tag>
                    )}
                  </Text>
                </Space>
              </div>
            </Space>
          </Card>

          {/* Stats Card */}
          <Card bordered={false} style={{ marginTop: 16 }}>
            <Statistic
              title="Assigned Alerts"
              value={user.assigned_alerts?.aggregate?.count || 0}
              prefix={<SafetyCertificateOutlined />}
            />
          </Card>
        </Col>

        {/* User Details */}
        <Col xs={24} lg={16}>
          <Card title="User Details" bordered={false}>
            <Descriptions column={{ xs: 1, sm: 2 }} bordered>
              <Descriptions.Item label="Full Name">{user.name}</Descriptions.Item>
              <Descriptions.Item label="Email">{user.email}</Descriptions.Item>
              <Descriptions.Item label="Role">
                <Tag
                  color={roleColors[user.role]}
                  style={{ textTransform: 'capitalize' }}
                >
                  {user.role}
                </Tag>
              </Descriptions.Item>
              <Descriptions.Item label="Status">
                {user.is_active ? (
                  <Tag color="success">Active</Tag>
                ) : (
                  <Tag color="default">Inactive</Tag>
                )}
              </Descriptions.Item>
              <Descriptions.Item label="Last Login">
                {user.last_login
                  ? dayjs(user.last_login).format('YYYY-MM-DD HH:mm:ss')
                  : 'Never'}
              </Descriptions.Item>
              <Descriptions.Item label="Created">
                {dayjs(user.created_at).format('YYYY-MM-DD HH:mm:ss')}
              </Descriptions.Item>
              <Descriptions.Item label="Updated">
                {dayjs(user.updated_at).format('YYYY-MM-DD HH:mm:ss')}
              </Descriptions.Item>
            </Descriptions>
          </Card>

          {/* Role Permissions */}
          <Card title="Role Permissions" bordered={false} style={{ marginTop: 16 }}>
            <Text type="secondary" style={{ display: 'block', marginBottom: 16 }}>
              {roleDescriptions[user.role] || 'No description available'}
            </Text>

            <Divider orientation="left">Permissions</Divider>
            {user.role === 'admin' && (
              <Space wrap>
                <Tag color="blue">Dashboard</Tag>
                <Tag color="blue">Alerts (Full)</Tag>
                <Tag color="blue">Users (Full)</Tag>
                <Tag color="blue">Analytics</Tag>
                <Tag color="blue">Settings</Tag>
              </Space>
            )}
            {user.role === 'analyst' && (
              <Space wrap>
                <Tag color="blue">Dashboard</Tag>
                <Tag color="blue">Alerts (Read/Update)</Tag>
                <Tag color="default">Users (Read)</Tag>
                <Tag color="blue">Analytics</Tag>
                <Tag color="default">Settings (Read)</Tag>
              </Space>
            )}
            {user.role === 'developer' && (
              <Space wrap>
                <Tag color="blue">Dashboard</Tag>
                <Tag color="default">Alerts (Read)</Tag>
                <Tag color="blue">Analytics</Tag>
                <Tag color="default">Settings (Read)</Tag>
              </Space>
            )}
            {user.role === 'viewer' && (
              <Space wrap>
                <Tag color="blue">Dashboard</Tag>
                <Tag color="default">Alerts (Read)</Tag>
                <Tag color="blue">Analytics</Tag>
              </Space>
            )}
          </Card>
        </Col>
      </Row>
    </Show>
  );
};

export default UserShow;
