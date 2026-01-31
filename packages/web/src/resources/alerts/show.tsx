import { Show } from '@refinedev/antd';
import { useShow } from '@refinedev/core';
import {
  Card,
  Row,
  Col,
  Descriptions,
  Tag,
  Typography,
  Timeline,
  Space,
  Button,
  Divider,
  Spin,
  Alert as AntAlert,
} from 'antd';
import {
  CheckCircleOutlined,
  CloseCircleOutlined,
  EditOutlined,
  UserOutlined,
  ClockCircleOutlined,
} from '@ant-design/icons';
import { useNavigate } from 'react-router-dom';
import dayjs from 'dayjs';

import { VG_COLORS, severityColors, statusColors } from '../../config/antd-theme';
import { ExternalToolsLinks } from '../../components/common/ExternalToolsLinks';

const { Text, Paragraph } = Typography;

interface Alert {
  id: string;
  b_number: string;
  a_number: string;
  severity: string;
  status: string;
  threat_score: number;
  detection_type: string;
  carrier_id: string;
  carrier_name: string;
  route_type: string;
  cli_status: string;
  created_at: string;
  updated_at: string;
  notes: string;
  assigned_to: string;
  audit_logs?: AuditLog[];
}

interface AuditLog {
  id: string;
  action: string;
  user_name: string;
  old_value: string;
  new_value: string;
  created_at: string;
}

export const AlertShow: React.FC = () => {
  const navigate = useNavigate();
  const { queryResult } = useShow<Alert>({
    resource: 'acm_alerts',
    liveMode: 'auto',
  });

  const { data, isLoading, isError } = queryResult;
  const alert = data?.data;

  if (isLoading) {
    return (
      <Show>
        <div style={{ textAlign: 'center', padding: 48 }}>
          <Spin size="large" />
        </div>
      </Show>
    );
  }

  if (isError || !alert) {
    return (
      <Show>
        <AntAlert
          type="error"
          message="Error"
          description="Failed to load alert details"
          showIcon
        />
      </Show>
    );
  }

  const sevColors = severityColors[alert.severity] || severityColors.LOW;
  const statColors = statusColors[alert.status] || statusColors.NEW;

  const getActionIcon = (action: string) => {
    switch (action) {
      case 'STATUS_CHANGED':
        return <ClockCircleOutlined style={{ color: VG_COLORS.warning }} />;
      case 'ASSIGNED':
        return <UserOutlined style={{ color: VG_COLORS.info }} />;
      case 'RESOLVED':
        return <CheckCircleOutlined style={{ color: VG_COLORS.success }} />;
      case 'NOTE_ADDED':
        return <EditOutlined style={{ color: VG_COLORS.primary }} />;
      default:
        return <ClockCircleOutlined />;
    }
  };

  return (
    <Show
      headerButtons={() => (
        <Space>
          <Button
            type="primary"
            icon={<EditOutlined />}
            onClick={() => navigate(`/alerts/edit/${alert.id}`)}
          >
            Update Status
          </Button>
        </Space>
      )}
    >
      <Row gutter={[24, 24]}>
        {/* Main Alert Details */}
        <Col xs={24} lg={16}>
          <Card bordered={false}>
            {/* Header with severity and status */}
            <Space align="center" style={{ marginBottom: 24 }}>
              <Tag
                style={{
                  backgroundColor: sevColors.background,
                  color: sevColors.color,
                  border: 'none',
                  fontSize: 14,
                  padding: '4px 12px',
                }}
              >
                {alert.severity}
              </Tag>
              <Tag
                style={{
                  backgroundColor: statColors.background,
                  color: statColors.color,
                  border: 'none',
                  fontSize: 14,
                  padding: '4px 12px',
                }}
              >
                {alert.status.replace('_', ' ')}
              </Tag>
              <Text type="secondary">
                Threat Score:{' '}
                <Text
                  strong
                  style={{
                    color:
                      alert.threat_score >= 80
                        ? VG_COLORS.critical
                        : alert.threat_score >= 60
                        ? VG_COLORS.high
                        : VG_COLORS.medium,
                    fontSize: 18,
                  }}
                >
                  {alert.threat_score}%
                </Text>
              </Text>
            </Space>

            <Descriptions column={{ xs: 1, sm: 2 }} bordered>
              <Descriptions.Item label="B-Number (Destination)">
                <Text strong copyable style={{ fontSize: 16 }}>
                  {alert.b_number}
                </Text>
              </Descriptions.Item>
              <Descriptions.Item label="A-Number (Source)">
                <Text copyable>{alert.a_number}</Text>
              </Descriptions.Item>
              <Descriptions.Item label="Detection Type">
                {alert.detection_type?.replace(/_/g, ' ')}
              </Descriptions.Item>
              <Descriptions.Item label="Route Type">
                {alert.route_type || 'Unknown'}
              </Descriptions.Item>
              <Descriptions.Item label="CLI Status">
                {alert.cli_status || 'Unknown'}
              </Descriptions.Item>
              <Descriptions.Item label="Carrier">
                {alert.carrier_name || 'Unknown'}
              </Descriptions.Item>
              <Descriptions.Item label="Created">
                {dayjs(alert.created_at).format('YYYY-MM-DD HH:mm:ss')}
              </Descriptions.Item>
              <Descriptions.Item label="Last Updated">
                {dayjs(alert.updated_at).format('YYYY-MM-DD HH:mm:ss')}
              </Descriptions.Item>
            </Descriptions>

            {/* Notes */}
            {alert.notes && (
              <>
                <Divider orientation="left">Notes</Divider>
                <Paragraph style={{ whiteSpace: 'pre-wrap' }}>
                  {alert.notes}
                </Paragraph>
              </>
            )}
          </Card>
        </Col>

        {/* Audit Trail */}
        <Col xs={24} lg={8}>
          <Card title="Activity Timeline" bordered={false}>
            {alert.audit_logs && alert.audit_logs.length > 0 ? (
              <Timeline>
                {alert.audit_logs.map((log) => (
                  <Timeline.Item
                    key={log.id}
                    dot={getActionIcon(log.action)}
                  >
                    <div>
                      <Text strong style={{ fontSize: 12 }}>
                        {log.action.replace(/_/g, ' ')}
                      </Text>
                      <br />
                      <Text type="secondary" style={{ fontSize: 11 }}>
                        by {log.user_name}
                      </Text>
                      {log.old_value && log.new_value && (
                        <div style={{ fontSize: 11, marginTop: 4 }}>
                          <Text type="secondary">{log.old_value}</Text>
                          {' → '}
                          <Text>{log.new_value}</Text>
                        </div>
                      )}
                      <div>
                        <Text type="secondary" style={{ fontSize: 10 }}>
                          {dayjs(log.created_at).format('MMM DD, HH:mm')}
                        </Text>
                      </div>
                    </div>
                  </Timeline.Item>
                ))}
              </Timeline>
            ) : (
              <Text type="secondary">No activity recorded</Text>
            )}
          </Card>

          {/* Quick Actions */}
          <Card title="Quick Actions" bordered={false} style={{ marginTop: 16 }}>
            <Space direction="vertical" style={{ width: '100%' }}>
              {alert.status !== 'RESOLVED' && (
                <Button
                  type="primary"
                  icon={<CheckCircleOutlined />}
                  block
                  style={{ backgroundColor: VG_COLORS.success }}
                  onClick={() => navigate(`/alerts/edit/${alert.id}`)}
                >
                  Mark as Resolved
                </Button>
              )}
              {alert.status !== 'FALSE_POSITIVE' && (
                <Button
                  icon={<CloseCircleOutlined />}
                  block
                  onClick={() => navigate(`/alerts/edit/${alert.id}`)}
                >
                  Mark as False Positive
                </Button>
              )}
            </Space>
          </Card>

          {/* External Analysis Tools */}
          <div style={{ marginTop: 16 }}>
            <ExternalToolsLinks alert={alert} />
          </div>
        </Col>
      </Row>
    </Show>
  );
};

export default AlertShow;
