import { useLogin } from '@refinedev/core';
import { Form, Input, Button, Card, Typography, Space, Divider, Alert } from 'antd';
import { UserOutlined, LockOutlined, SafetyCertificateOutlined } from '@ant-design/icons';
import { useState } from 'react';
import { VG_COLORS } from '../../config/antd-theme';

const { Title, Text, Link } = Typography;

interface LoginFormValues {
  email: string;
  password: string;
}

export const LoginPage: React.FC = () => {
  const { mutate: login, isLoading } = useLogin();
  const [error, setError] = useState<string | null>(null);

  const onFinish = async (values: LoginFormValues) => {
    setError(null);

    login(values, {
      onError: (err) => {
        setError(err?.message || 'Invalid email or password');
      },
    });
  };

  const loginAsDemo = (email: string) => {
    login({ email, password: 'demo123' });
  };

  return (
    <div
      style={{
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        background: `linear-gradient(135deg, ${VG_COLORS.primaryDark} 0%, ${VG_COLORS.primary} 50%, ${VG_COLORS.primaryLight} 100%)`,
        padding: 24,
      }}
    >
      <Card
        style={{
          width: '100%',
          maxWidth: 400,
          boxShadow: '0 8px 32px rgba(0, 0, 0, 0.2)',
          borderRadius: 12,
        }}
        bordered={false}
      >
        {/* Logo and Title */}
        <div style={{ textAlign: 'center', marginBottom: 32 }}>
          <SafetyCertificateOutlined
            style={{
              fontSize: 48,
              color: VG_COLORS.primary,
              marginBottom: 16,
            }}
          />
          <Title level={3} style={{ margin: 0, color: VG_COLORS.primary }}>
            VoxGuard
          </Title>
          <Text type="secondary">Voice Network Fraud Detection</Text>
        </div>

        {/* Error Alert */}
        {error && (
          <Alert
            message={error}
            type="error"
            showIcon
            style={{ marginBottom: 24 }}
            closable
            onClose={() => setError(null)}
          />
        )}

        {/* Login Form */}
        <Form
          name="login"
          onFinish={onFinish}
          layout="vertical"
          size="large"
          requiredMark={false}
        >
          <Form.Item
            name="email"
            rules={[
              { required: true, message: 'Please enter your email' },
              { type: 'email', message: 'Please enter a valid email' },
            ]}
          >
            <Input
              prefix={<UserOutlined style={{ color: VG_COLORS.textSecondary }} />}
              placeholder="Email address"
              autoComplete="email"
            />
          </Form.Item>

          <Form.Item
            name="password"
            rules={[{ required: true, message: 'Please enter your password' }]}
          >
            <Input.Password
              prefix={<LockOutlined style={{ color: VG_COLORS.textSecondary }} />}
              placeholder="Password"
              autoComplete="current-password"
            />
          </Form.Item>

          <Form.Item style={{ marginBottom: 16 }}>
            <Button
              type="primary"
              htmlType="submit"
              loading={isLoading}
              block
              style={{
                height: 44,
                backgroundColor: VG_COLORS.primary,
              }}
            >
              Sign In
            </Button>
          </Form.Item>

          <div style={{ textAlign: 'center' }}>
            <Link style={{ color: VG_COLORS.primaryLight }}>Forgot password?</Link>
          </div>
        </Form>

        {/* Demo Accounts */}
        <Divider plain>
          <Text type="secondary" style={{ fontSize: 12 }}>
            Demo Accounts
          </Text>
        </Divider>

        <Space direction="vertical" style={{ width: '100%' }} size={8}>
          <Button
            block
            onClick={() => loginAsDemo('admin@acm.com')}
            disabled={isLoading}
          >
            Login as Admin
          </Button>
          <Button
            block
            onClick={() => loginAsDemo('analyst@acm.com')}
            disabled={isLoading}
          >
            Login as Analyst
          </Button>
          <Button
            block
            onClick={() => loginAsDemo('viewer@acm.com')}
            disabled={isLoading}
          >
            Login as Viewer
          </Button>
        </Space>

        {/* Footer */}
        <div style={{ textAlign: 'center', marginTop: 24 }}>
          <Text type="secondary" style={{ fontSize: 11 }}>
            VoxGuard &copy; 2026 | Nigerian ICL Compliance
          </Text>
        </div>
      </Card>
    </div>
  );
};

export default LoginPage;
