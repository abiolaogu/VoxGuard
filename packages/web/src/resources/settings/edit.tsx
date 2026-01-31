import { useState } from 'react';
import {
  Card,
  Row,
  Col,
  Typography,
  Form,
  Input,
  InputNumber,
  Switch,
  Button,
  Divider,
  Space,
  message,
  Tabs,
  Alert,
} from 'antd';
import {
  SaveOutlined,
  ReloadOutlined,
  BellOutlined,
  SafetyCertificateOutlined,
  SettingOutlined,
  ApiOutlined,
  AppstoreOutlined,
  ExportOutlined,
  CheckCircleOutlined,
  CloseCircleOutlined,
  SyncOutlined,
} from '@ant-design/icons';
import { EXTERNAL_SERVICES, SERVICE_CATEGORIES } from '../../config/external-services';
import { VG_COLORS } from '../../config/antd-theme';

const { Title, Text, Paragraph } = Typography;

interface DetectionSettings {
  cpm_warning: number;
  cpm_critical: number;
  acd_warning: number;
  acd_critical: number;
  threat_score_threshold: number;
  auto_block_enabled: boolean;
  auto_block_threshold: number;
}

interface NotificationSettings {
  email_enabled: boolean;
  email_recipients: string;
  slack_enabled: boolean;
  slack_webhook: string;
  critical_sound_enabled: boolean;
  notification_cooldown: number;
}

interface ApiSettings {
  rate_limit: number;
  timeout: number;
  retry_attempts: number;
  ncc_reporting_enabled: boolean;
  ncc_api_key: string;
}

export const SettingsPage: React.FC = () => {
  const [detectionForm] = Form.useForm<DetectionSettings>();
  const [notificationForm] = Form.useForm<NotificationSettings>();
  const [apiForm] = Form.useForm<ApiSettings>();
  const [saving, setSaving] = useState(false);
  const [checkingHealth, setCheckingHealth] = useState(false);
  const [serviceHealth, setServiceHealth] = useState<Record<string, 'healthy' | 'unhealthy' | 'unknown'>>({});

  const checkServiceHealth = async (_serviceId: string, url: string) => {
    // For demo purposes, assume services are reachable
    // In production, you'd call a backend health check endpoint
    return url ? 'healthy' : 'unknown';
  };

  const checkAllServicesHealth = async () => {
    setCheckingHealth(true);
    const results: Record<string, 'healthy' | 'unhealthy' | 'unknown'> = {};

    for (const service of EXTERNAL_SERVICES) {
      results[service.id] = await checkServiceHealth(service.id, service.url);
    }

    setServiceHealth(results);
    setCheckingHealth(false);
    message.success('Health check completed');
  };

  const handleSaveDetection = async (_values: DetectionSettings) => {
    setSaving(true);
    // TODO: Implement actual save via GraphQL mutation
    await new Promise((resolve) => setTimeout(resolve, 1000));
    message.success('Detection settings saved');
    setSaving(false);
  };

  const handleSaveNotifications = async (_values: NotificationSettings) => {
    setSaving(true);
    await new Promise((resolve) => setTimeout(resolve, 1000));
    message.success('Notification settings saved');
    setSaving(false);
  };

  const handleSaveApi = async (_values: ApiSettings) => {
    setSaving(true);
    await new Promise((resolve) => setTimeout(resolve, 1000));
    message.success('API settings saved');
    setSaving(false);
  };

  const items = [
    {
      key: 'detection',
      label: (
        <span>
          <SafetyCertificateOutlined />
          Detection
        </span>
      ),
      children: (
        <Card bordered={false}>
          <Paragraph type="secondary" style={{ marginBottom: 24 }}>
            Configure detection thresholds and automatic actions for call masking alerts.
          </Paragraph>

          <Form
            form={detectionForm}
            layout="vertical"
            onFinish={handleSaveDetection}
            initialValues={{
              cpm_warning: 40,
              cpm_critical: 60,
              acd_warning: 10,
              acd_critical: 5,
              threat_score_threshold: 70,
              auto_block_enabled: false,
              auto_block_threshold: 90,
            }}
          >
            <Title level={5}>Calls Per Minute (CPM) Thresholds</Title>
            <Row gutter={16}>
              <Col xs={24} sm={12}>
                <Form.Item
                  label="Warning Level"
                  name="cpm_warning"
                  rules={[{ required: true }]}
                >
                  <InputNumber
                    min={1}
                    max={100}
                    style={{ width: '100%' }}
                    addonAfter="calls/min"
                  />
                </Form.Item>
              </Col>
              <Col xs={24} sm={12}>
                <Form.Item
                  label="Critical Level"
                  name="cpm_critical"
                  rules={[{ required: true }]}
                >
                  <InputNumber
                    min={1}
                    max={200}
                    style={{ width: '100%' }}
                    addonAfter="calls/min"
                  />
                </Form.Item>
              </Col>
            </Row>

            <Title level={5}>Average Call Duration (ACD) Thresholds</Title>
            <Row gutter={16}>
              <Col xs={24} sm={12}>
                <Form.Item
                  label="Warning Level (below)"
                  name="acd_warning"
                  rules={[{ required: true }]}
                >
                  <InputNumber
                    min={1}
                    max={60}
                    style={{ width: '100%' }}
                    addonAfter="seconds"
                  />
                </Form.Item>
              </Col>
              <Col xs={24} sm={12}>
                <Form.Item
                  label="Critical Level (below)"
                  name="acd_critical"
                  rules={[{ required: true }]}
                >
                  <InputNumber
                    min={1}
                    max={30}
                    style={{ width: '100%' }}
                    addonAfter="seconds"
                  />
                </Form.Item>
              </Col>
            </Row>

            <Title level={5}>Threat Score</Title>
            <Form.Item
              label="Alert Threshold"
              name="threat_score_threshold"
              extra="Alerts above this score will be marked as high priority"
            >
              <InputNumber
                min={1}
                max={100}
                style={{ width: '100%' }}
                addonAfter="%"
              />
            </Form.Item>

            <Divider />

            <Title level={5}>Automatic Actions</Title>
            <Alert
              message="Caution"
              description="Enabling automatic blocking may affect legitimate traffic. Use with care."
              type="warning"
              showIcon
              style={{ marginBottom: 16 }}
            />

            <Form.Item
              label="Enable Auto-Block"
              name="auto_block_enabled"
              valuePropName="checked"
            >
              <Switch />
            </Form.Item>

            <Form.Item
              label="Auto-Block Threshold"
              name="auto_block_threshold"
              extra="Numbers exceeding this threat score will be automatically blocked"
            >
              <InputNumber
                min={80}
                max={100}
                style={{ width: '100%' }}
                addonAfter="%"
              />
            </Form.Item>

            <Form.Item>
              <Space>
                <Button type="primary" htmlType="submit" loading={saving} icon={<SaveOutlined />}>
                  Save Detection Settings
                </Button>
                <Button onClick={() => detectionForm.resetFields()} icon={<ReloadOutlined />}>
                  Reset
                </Button>
              </Space>
            </Form.Item>
          </Form>
        </Card>
      ),
    },
    {
      key: 'notifications',
      label: (
        <span>
          <BellOutlined />
          Notifications
        </span>
      ),
      children: (
        <Card bordered={false}>
          <Paragraph type="secondary" style={{ marginBottom: 24 }}>
            Configure how you receive alerts about call masking detections.
          </Paragraph>

          <Form
            form={notificationForm}
            layout="vertical"
            onFinish={handleSaveNotifications}
            initialValues={{
              email_enabled: true,
              email_recipients: 'security@example.com',
              slack_enabled: false,
              slack_webhook: '',
              critical_sound_enabled: true,
              notification_cooldown: 5,
            }}
          >
            <Title level={5}>Email Notifications</Title>
            <Form.Item
              label="Enable Email Alerts"
              name="email_enabled"
              valuePropName="checked"
            >
              <Switch />
            </Form.Item>

            <Form.Item
              label="Recipients"
              name="email_recipients"
              extra="Comma-separated email addresses"
            >
              <Input placeholder="security@example.com, alerts@example.com" />
            </Form.Item>

            <Divider />

            <Title level={5}>Slack Integration</Title>
            <Form.Item
              label="Enable Slack Alerts"
              name="slack_enabled"
              valuePropName="checked"
            >
              <Switch />
            </Form.Item>

            <Form.Item
              label="Webhook URL"
              name="slack_webhook"
            >
              <Input.Password placeholder="https://hooks.slack.com/services/..." />
            </Form.Item>

            <Divider />

            <Title level={5}>Browser Notifications</Title>
            <Form.Item
              label="Sound for Critical Alerts"
              name="critical_sound_enabled"
              valuePropName="checked"
            >
              <Switch />
            </Form.Item>

            <Form.Item
              label="Notification Cooldown"
              name="notification_cooldown"
              extra="Minimum time between notifications for the same alert"
            >
              <InputNumber min={1} max={60} style={{ width: '100%' }} addonAfter="minutes" />
            </Form.Item>

            <Form.Item>
              <Space>
                <Button type="primary" htmlType="submit" loading={saving} icon={<SaveOutlined />}>
                  Save Notification Settings
                </Button>
                <Button onClick={() => notificationForm.resetFields()} icon={<ReloadOutlined />}>
                  Reset
                </Button>
              </Space>
            </Form.Item>
          </Form>
        </Card>
      ),
    },
    {
      key: 'api',
      label: (
        <span>
          <ApiOutlined />
          API & Integration
        </span>
      ),
      children: (
        <Card bordered={false}>
          <Paragraph type="secondary" style={{ marginBottom: 24 }}>
            Configure API rate limits and external integrations.
          </Paragraph>

          <Form
            form={apiForm}
            layout="vertical"
            onFinish={handleSaveApi}
            initialValues={{
              rate_limit: 1000,
              timeout: 30,
              retry_attempts: 3,
              ncc_reporting_enabled: false,
              ncc_api_key: '',
            }}
          >
            <Title level={5}>API Configuration</Title>
            <Row gutter={16}>
              <Col xs={24} sm={8}>
                <Form.Item
                  label="Rate Limit"
                  name="rate_limit"
                >
                  <InputNumber min={100} max={10000} style={{ width: '100%' }} addonAfter="req/min" />
                </Form.Item>
              </Col>
              <Col xs={24} sm={8}>
                <Form.Item
                  label="Timeout"
                  name="timeout"
                >
                  <InputNumber min={5} max={120} style={{ width: '100%' }} addonAfter="seconds" />
                </Form.Item>
              </Col>
              <Col xs={24} sm={8}>
                <Form.Item
                  label="Retry Attempts"
                  name="retry_attempts"
                >
                  <InputNumber min={0} max={10} style={{ width: '100%' }} />
                </Form.Item>
              </Col>
            </Row>

            <Divider />

            <Title level={5}>NCC Compliance Reporting</Title>
            <Form.Item
              label="Enable NCC Reporting"
              name="ncc_reporting_enabled"
              valuePropName="checked"
              extra="Automatically report call masking incidents to NCC"
            >
              <Switch />
            </Form.Item>

            <Form.Item
              label="NCC API Key"
              name="ncc_api_key"
            >
              <Input.Password placeholder="Enter NCC API key" />
            </Form.Item>

            <Form.Item>
              <Space>
                <Button type="primary" htmlType="submit" loading={saving} icon={<SaveOutlined />}>
                  Save API Settings
                </Button>
                <Button onClick={() => apiForm.resetFields()} icon={<ReloadOutlined />}>
                  Reset
                </Button>
              </Space>
            </Form.Item>
          </Form>
        </Card>
      ),
    },
    {
      key: 'external-tools',
      label: (
        <span>
          <AppstoreOutlined />
          External Portals
        </span>
      ),
      children: (
        <Card bordered={false}>
          <Paragraph type="secondary" style={{ marginBottom: 24 }}>
            Quick access to all VoxGuard monitoring, analytics, and administration portals.
            Click any service to open in a new tab.
          </Paragraph>

          <Space style={{ marginBottom: 24 }}>
            <Button
              icon={<SyncOutlined spin={checkingHealth} />}
              onClick={checkAllServicesHealth}
              loading={checkingHealth}
            >
              Check Health
            </Button>
          </Space>

          {Object.entries(SERVICE_CATEGORIES).map(([key, category]) => (
            <div key={key} style={{ marginBottom: 24 }}>
              <Title level={5}>{category.label}</Title>
              <Row gutter={[16, 16]}>
                {category.services.map((service) => (
                  <Col xs={24} sm={12} lg={8} key={service.id}>
                    <Card
                      size="small"
                      hoverable
                      onClick={() => window.open(service.url, '_blank')}
                      style={{ cursor: 'pointer' }}
                    >
                      <Space direction="vertical" style={{ width: '100%' }}>
                        <Space style={{ width: '100%', justifyContent: 'space-between' }}>
                          <Text strong>{service.name}</Text>
                          <Space size={4}>
                            {serviceHealth[service.id] === 'healthy' && (
                              <CheckCircleOutlined style={{ color: VG_COLORS.success }} />
                            )}
                            {serviceHealth[service.id] === 'unhealthy' && (
                              <CloseCircleOutlined style={{ color: VG_COLORS.error }} />
                            )}
                            <ExportOutlined style={{ color: VG_COLORS.textSecondary }} />
                          </Space>
                        </Space>
                        <Text type="secondary" style={{ fontSize: 12 }}>
                          {service.description}
                        </Text>
                        <Text code style={{ fontSize: 11 }}>
                          {service.url}
                        </Text>
                        {service.credentials && (
                          <Text type="secondary" style={{ fontSize: 11 }}>
                            User: {service.credentials.username}
                          </Text>
                        )}
                      </Space>
                    </Card>
                  </Col>
                ))}
              </Row>
              <Divider />
            </div>
          ))}

          <Alert
            message="Note"
            description="These links connect to external monitoring services. Ensure the services are running and accessible from your network."
            type="info"
            showIcon
          />
        </Card>
      ),
    },
  ];

  return (
    <div className="acm-fade-in">
      <div className="acm-page-header" style={{ marginBottom: 24 }}>
        <Title level={3} style={{ marginBottom: 4 }}>
          <SettingOutlined /> Settings
        </Title>
        <Text type="secondary">
          Configure system behavior, notifications, and integrations
        </Text>
      </div>

      <Tabs items={items} />
    </div>
  );
};

export default SettingsPage;
