import React from 'react';
import {
  Show,
  DateField,
  NumberField,
  TextField,
  BooleanField,
  TagField,
  EditButton,
  DeleteButton,
  RefreshButton,
} from '@refinedev/antd';
import {
  Typography,
  Card,
  Row,
  Col,
  Descriptions,
  Tag,
  Space,
  Badge,
  Statistic,
  Alert,
  Divider,
} from 'antd';
import {
  ApiOutlined,
  CheckCircleOutlined,
  WarningOutlined,
  StopOutlined,
  PhoneOutlined,
  MailOutlined,
  UserOutlined,
} from '@ant-design/icons';
import type { IResourceComponentsProps } from '@refinedev/core';
import { useShow } from '@refinedev/core';
import type { IGateway } from './list';

const { Title, Text } = Typography;

export const GatewayShow: React.FC<IResourceComponentsProps> = () => {
  const { queryResult } = useShow<IGateway>();
  const { data, isLoading } = queryResult;
  const record = data?.data;

  const getStatusColor = (status?: string) => {
    switch (status) {
      case 'active':
        return 'success';
      case 'inactive':
        return 'default';
      case 'suspended':
        return 'warning';
      case 'blacklisted':
        return 'error';
      default:
        return 'default';
    }
  };

  const getHealthColor = (health?: string) => {
    switch (health) {
      case 'healthy':
        return 'success';
      case 'degraded':
        return 'warning';
      case 'critical':
        return 'error';
      case 'unknown':
        return 'default';
      default:
        return 'default';
    }
  };

  return (
    <Show
      isLoading={isLoading}
      headerButtons={({ defaultButtons }) => (
        <>
          {defaultButtons}
          <RefreshButton />
        </>
      )}
    >
      {record?.is_blacklisted && (
        <Alert
          message="Gateway Blacklisted"
          description={`This gateway has been blacklisted. Reason: ${
            record.blacklist_reason || 'No reason provided'
          }`}
          type="error"
          showIcon
          icon={<StopOutlined />}
          style={{ marginBottom: 24 }}
        />
      )}

      <Row gutter={[16, 16]}>
        {/* Overview Card */}
        <Col xs={24} lg={16}>
          <Card title="Gateway Information" bordered={false}>
            <Descriptions column={{ xxl: 2, xl: 2, lg: 2, md: 1, sm: 1, xs: 1 }}>
              <Descriptions.Item label="Name">
                <Text strong>{record?.name}</Text>
              </Descriptions.Item>

              <Descriptions.Item label="Code">
                <Tag color="blue">{record?.code}</Tag>
              </Descriptions.Item>

              <Descriptions.Item label="IP Address">
                <Text>
                  <ApiOutlined /> {record?.ip_address}:{record?.port}
                </Text>
              </Descriptions.Item>

              <Descriptions.Item label="Protocol">
                <Tag>{record?.protocol}</Tag>
              </Descriptions.Item>

              <Descriptions.Item label="Carrier">
                <Space direction="vertical" size={0}>
                  <Text strong>{record?.carrier_name}</Text>
                  <Text type="secondary">
                    {record?.carrier_type} • {record?.region}
                  </Text>
                </Space>
              </Descriptions.Item>

              <Descriptions.Item label="Gateway Type">
                <Space>
                  <Tag color="blue">{record?.gateway_type?.toUpperCase()}</Tag>
                  <Text type="secondary">{record?.direction}</Text>
                </Space>
              </Descriptions.Item>

              <Descriptions.Item label="Status">
                <Tag color={getStatusColor(record?.status)}>
                  {record?.status?.toUpperCase()}
                </Tag>
              </Descriptions.Item>

              <Descriptions.Item label="Health">
                <Badge
                  status={getHealthColor(record?.health_status)}
                  text={record?.health_status?.toUpperCase()}
                />
              </Descriptions.Item>

              <Descriptions.Item label="NCC Compliant">
                <BooleanField
                  value={record?.is_ncc_compliant}
                  valueLabelTrue="Yes"
                  valueLabelFalse="No"
                />
              </Descriptions.Item>

              <Descriptions.Item label="Monitored">
                <BooleanField
                  value={record?.is_monitored}
                  valueLabelTrue="Yes"
                  valueLabelFalse="No"
                />
              </Descriptions.Item>
            </Descriptions>

            {record?.description && (
              <>
                <Divider />
                <Descriptions column={1}>
                  <Descriptions.Item label="Description">
                    <Text>{record.description}</Text>
                  </Descriptions.Item>
                </Descriptions>
              </>
            )}
          </Card>
        </Col>

        {/* Statistics Card */}
        <Col xs={24} lg={8}>
          <Card title="Today's Statistics" bordered={false}>
            <Space direction="vertical" size="large" style={{ width: '100%' }}>
              <Statistic
                title="Total Calls"
                value={record?.total_calls_today || 0}
                valueStyle={{ color: '#3f8600' }}
              />
              <Statistic
                title="Failed Calls"
                value={record?.failed_calls_today || 0}
                valueStyle={{ color: '#cf1322' }}
              />
              <Statistic
                title="Fraud Alerts"
                value={record?.fraud_alerts_today || 0}
                valueStyle={{
                  color:
                    (record?.fraud_alerts_today || 0) > 0 ? '#cf1322' : '#3f8600',
                }}
                prefix={
                  (record?.fraud_alerts_today || 0) > 0 ? (
                    <WarningOutlined />
                  ) : (
                    <CheckCircleOutlined />
                  )
                }
              />
              <Divider />
              <Statistic
                title="Current CPS"
                value={record?.current_cps || 0}
                precision={1}
                suffix="calls/s"
              />
              <Statistic
                title="Concurrent Calls"
                value={record?.current_concurrent_calls || 0}
              />
            </Space>
          </Card>
        </Col>

        {/* Configuration Card */}
        <Col xs={24} lg={12}>
          <Card title="Detection Configuration" bordered={false}>
            <Descriptions column={1}>
              <Descriptions.Item label="Fraud Threshold">
                <NumberField value={record?.fraud_threshold || 5} />
              </Descriptions.Item>

              <Descriptions.Item label="Max Concurrent Calls">
                <NumberField value={record?.max_concurrent_calls || 0} />
              </Descriptions.Item>

              <Descriptions.Item label="Max Calls Per Second">
                <NumberField value={record?.max_calls_per_second || 0} />
              </Descriptions.Item>

              <Descriptions.Item label="Peak Concurrent Calls">
                <NumberField value={record?.peak_concurrent_calls || 0} />
              </Descriptions.Item>

              <Descriptions.Item label="Peak CPS">
                <NumberField
                  value={record?.peak_cps || 0}
                  options={{ minimumFractionDigits: 1 }}
                />
              </Descriptions.Item>
            </Descriptions>
          </Card>
        </Col>

        {/* Contact Information Card */}
        <Col xs={24} lg={12}>
          <Card title="Technical Contact" bordered={false}>
            <Descriptions column={1}>
              <Descriptions.Item label="Name">
                <Text>
                  <UserOutlined /> {record?.technical_contact_name || 'N/A'}
                </Text>
              </Descriptions.Item>

              <Descriptions.Item label="Email">
                <Text>
                  <MailOutlined /> {record?.technical_contact_email || 'N/A'}
                </Text>
              </Descriptions.Item>

              <Descriptions.Item label="Phone">
                <Text>
                  <PhoneOutlined /> {record?.technical_contact_phone || 'N/A'}
                </Text>
              </Descriptions.Item>
            </Descriptions>

            <Divider />

            <Descriptions column={1}>
              <Descriptions.Item label="NCC License">
                <Text>{record?.ncc_license_number || 'N/A'}</Text>
              </Descriptions.Item>

              <Descriptions.Item label="License Expiry">
                {record?.license_expiry_date ? (
                  <DateField value={record.license_expiry_date} format="LL" />
                ) : (
                  <Text type="secondary">N/A</Text>
                )}
              </Descriptions.Item>
            </Descriptions>
          </Card>
        </Col>

        {/* Audit Information Card */}
        <Col xs={24}>
          <Card title="Audit Information" bordered={false}>
            <Descriptions column={{ xxl: 3, xl: 3, lg: 2, md: 2, sm: 1, xs: 1 }}>
              <Descriptions.Item label="Created At">
                <DateField value={record?.created_at} format="LLL" />
              </Descriptions.Item>

              <Descriptions.Item label="Updated At">
                <DateField value={record?.updated_at} format="LLL" />
              </Descriptions.Item>

              {record?.blacklisted_at && (
                <Descriptions.Item label="Blacklisted At">
                  <DateField value={record.blacklisted_at} format="LLL" />
                </Descriptions.Item>
              )}
            </Descriptions>
          </Card>
        </Col>
      </Row>
    </Show>
  );
};
