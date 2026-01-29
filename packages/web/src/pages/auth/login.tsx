import { useState } from 'react';
import { useLogin } from '@refinedev/core';
import { Card, Form, Input, Button, Typography, Space, Divider, Alert, theme } from 'antd';
import { MailOutlined, LockOutlined, SafetyOutlined } from '@ant-design/icons';

const { Title, Text, Link } = Typography;

interface LoginFormValues {
    email: string;
    password: string;
}

export const Login: React.FC = () => {
    const { token } = theme.useToken();
    const { mutate: login, isLoading } = useLogin<LoginFormValues>();
    const [error, setError] = useState<string | null>(null);

    const onFinish = async (values: LoginFormValues) => {
        setError(null);
        login(values, {
            onError: (err) => {
                setError(err.message || 'Login failed. Please check your credentials.');
            },
        });
    };

    return (
        <div
            style={{
                minHeight: '100vh',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                background: `linear-gradient(135deg, ${token.colorPrimary} 0%, ${token.colorPrimaryActive} 100%)`,
                padding: 24,
            }}
        >
            <Card
                style={{
                    width: '100%',
                    maxWidth: 400,
                    boxShadow: '0 8px 32px rgba(0,0,0,0.1)',
                    borderRadius: 12,
                }}
            >
                <Space direction="vertical" size="large" style={{ width: '100%' }}>
                    {/* Header */}
                    <div style={{ textAlign: 'center' }}>
                        <Space>
                            <SafetyOutlined style={{ fontSize: 36, color: token.colorPrimary }} />
                            <Title level={3} style={{ margin: 0 }}>
                                ACM Platform
                            </Title>
                        </Space>
                        <Text type="secondary" style={{ display: 'block', marginTop: 8 }}>
                            Anti-Call Masking Detection System
                        </Text>
                    </div>

                    {error && (
                        <Alert
                            message={error}
                            type="error"
                            showIcon
                            closable
                            onClose={() => setError(null)}
                        />
                    )}

                    {/* Login Form */}
                    <Form
                        name="login"
                        layout="vertical"
                        onFinish={onFinish}
                        autoComplete="off"
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
                                prefix={<MailOutlined style={{ color: token.colorTextSecondary }} />}
                                placeholder="Email"
                                size="large"
                            />
                        </Form.Item>

                        <Form.Item
                            name="password"
                            rules={[{ required: true, message: 'Please enter your password' }]}
                        >
                            <Input.Password
                                prefix={<LockOutlined style={{ color: token.colorTextSecondary }} />}
                                placeholder="Password"
                                size="large"
                            />
                        </Form.Item>

                        <Form.Item style={{ marginBottom: 8 }}>
                            <Button
                                type="primary"
                                htmlType="submit"
                                size="large"
                                block
                                loading={isLoading}
                            >
                                Sign In
                            </Button>
                        </Form.Item>

                        <div style={{ textAlign: 'right' }}>
                            <Link>Forgot password?</Link>
                        </div>
                    </Form>

                    <Divider style={{ margin: 0 }}>
                        <Text type="secondary">or</Text>
                    </Divider>

                    {/* SSO Options */}
                    <Button size="large" block disabled>
                        Sign in with SSO
                    </Button>

                    <div style={{ textAlign: 'center' }}>
                        <Text type="secondary" style={{ fontSize: 12 }}>
                            Protected by enterprise-grade security
                        </Text>
                    </div>
                </Space>
            </Card>
        </div>
    );
};

export default Login;
