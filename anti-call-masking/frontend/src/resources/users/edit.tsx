import { Edit, useForm } from '@refinedev/antd';
import { Form, Input, Select, Switch, Card, Row, Col, Typography, Avatar } from 'antd';
import { UserOutlined, MailOutlined } from '@ant-design/icons';

import { ACM_COLORS } from '../../config/antd-theme';

const { Text } = Typography;

interface User {
  id: string;
  name: string;
  email: string;
  role: string;
  avatar?: string;
  is_active: boolean;
}

const roleOptions = [
  { label: 'Admin', value: 'admin' },
  { label: 'Analyst', value: 'analyst' },
  { label: 'Developer', value: 'developer' },
  { label: 'Viewer', value: 'viewer' },
];

export const UserEdit: React.FC = () => {
  const { formProps, saveButtonProps, queryResult } = useForm<User>({
    resource: 'acm_users',
    redirect: 'show',
  });

  const user = queryResult?.data?.data;

  return (
    <Edit saveButtonProps={saveButtonProps}>
      <Row gutter={[24, 24]}>
        {/* Current User Info */}
        <Col xs={24} lg={8}>
          <Card title="Current User" bordered={false}>
            {user && (
              <div style={{ textAlign: 'center' }}>
                <Avatar
                  size={80}
                  src={user.avatar}
                  icon={<UserOutlined />}
                  style={{ backgroundColor: ACM_COLORS.primary }}
                />
                <div style={{ marginTop: 16 }}>
                  <Text strong style={{ fontSize: 16 }}>
                    {user.name}
                  </Text>
                  <br />
                  <Text type="secondary">{user.email}</Text>
                </div>
              </div>
            )}
          </Card>
        </Col>

        {/* Edit Form */}
        <Col xs={24} lg={16}>
          <Card title="Edit User" bordered={false}>
            <Form {...formProps} layout="vertical">
              <Form.Item
                label="Full Name"
                name="name"
                rules={[
                  { required: true, message: 'Please enter the user name' },
                  { min: 2, message: 'Name must be at least 2 characters' },
                ]}
              >
                <Input
                  prefix={<UserOutlined />}
                  placeholder="Enter full name"
                  size="large"
                />
              </Form.Item>

              <Form.Item
                label="Email Address"
                name="email"
                rules={[
                  { required: true, message: 'Please enter an email address' },
                  { type: 'email', message: 'Please enter a valid email' },
                ]}
              >
                <Input
                  prefix={<MailOutlined />}
                  placeholder="Enter email address"
                  size="large"
                />
              </Form.Item>

              <Form.Item
                label="Role"
                name="role"
                rules={[{ required: true, message: 'Please select a role' }]}
              >
                <Select size="large" options={roleOptions} placeholder="Select role" />
              </Form.Item>

              <Form.Item
                label="Account Status"
                name="is_active"
                valuePropName="checked"
              >
                <Switch checkedChildren="Active" unCheckedChildren="Inactive" />
              </Form.Item>
            </Form>
          </Card>
        </Col>
      </Row>
    </Edit>
  );
};

export default UserEdit;
