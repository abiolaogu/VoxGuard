import { Create, useForm } from '@refinedev/antd';
import { Form, Input, Select, Switch, Card, Row, Col, Typography, Divider } from 'antd';
import { UserOutlined, MailOutlined, LockOutlined } from '@ant-design/icons';

const { Text } = Typography;

interface UserFormValues {
  name: string;
  email: string;
  password: string;
  role: string;
  is_active: boolean;
}

const roleOptions = [
  { label: 'Admin', value: 'admin', description: 'Full system access' },
  { label: 'Analyst', value: 'analyst', description: 'Manage alerts and view analytics' },
  { label: 'Developer', value: 'developer', description: 'Read-only technical access' },
  { label: 'Viewer', value: 'viewer', description: 'Read-only basic access' },
];

export const UserCreate: React.FC = () => {
  const { formProps, saveButtonProps } = useForm<UserFormValues>({
    resource: 'acm_users',
    redirect: 'list',
  });

  return (
    <Create saveButtonProps={saveButtonProps}>
      <Row gutter={[24, 24]}>
        <Col xs={24} lg={16}>
          <Card title="User Information" bordered={false}>
            <Form
              {...formProps}
              layout="vertical"
              initialValues={{ is_active: true, role: 'viewer' }}
            >
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
                label="Password"
                name="password"
                rules={[
                  { required: true, message: 'Please enter a password' },
                  { min: 8, message: 'Password must be at least 8 characters' },
                ]}
                extra="Password must be at least 8 characters"
              >
                <Input.Password
                  prefix={<LockOutlined />}
                  placeholder="Enter password"
                  size="large"
                />
              </Form.Item>

              <Form.Item
                label="Role"
                name="role"
                rules={[{ required: true, message: 'Please select a role' }]}
              >
                <Select size="large" placeholder="Select user role">
                  {roleOptions.map((option) => (
                    <Select.Option key={option.value} value={option.value}>
                      <div>
                        <Text strong>{option.label}</Text>
                        <br />
                        <Text type="secondary" style={{ fontSize: 12 }}>
                          {option.description}
                        </Text>
                      </div>
                    </Select.Option>
                  ))}
                </Select>
              </Form.Item>

              <Form.Item
                label="Active"
                name="is_active"
                valuePropName="checked"
              >
                <Switch checkedChildren="Active" unCheckedChildren="Inactive" />
              </Form.Item>
            </Form>
          </Card>
        </Col>

        <Col xs={24} lg={8}>
          <Card title="Role Guide" bordered={false}>
            <div style={{ marginBottom: 16 }}>
              <Text strong>Admin</Text>
              <br />
              <Text type="secondary" style={{ fontSize: 12 }}>
                Full system access including user management, settings configuration,
                and all alert operations.
              </Text>
            </div>

            <Divider style={{ margin: '12px 0' }} />

            <div style={{ marginBottom: 16 }}>
              <Text strong>Analyst</Text>
              <br />
              <Text type="secondary" style={{ fontSize: 12 }}>
                Can view dashboard, manage alerts (update status, assign), and access analytics.
                Cannot manage users or modify settings.
              </Text>
            </div>

            <Divider style={{ margin: '12px 0' }} />

            <div style={{ marginBottom: 16 }}>
              <Text strong>Developer</Text>
              <br />
              <Text type="secondary" style={{ fontSize: 12 }}>
                Read-only access to alerts, analytics, and settings.
                Useful for technical staff who need to monitor the system.
              </Text>
            </div>

            <Divider style={{ margin: '12px 0' }} />

            <div>
              <Text strong>Viewer</Text>
              <br />
              <Text type="secondary" style={{ fontSize: 12 }}>
                Basic read-only access to dashboard and alerts.
                Cannot access settings or user management.
              </Text>
            </div>
          </Card>
        </Col>
      </Row>
    </Create>
  );
};

export default UserCreate;
