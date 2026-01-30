import { Edit, useForm, useSelect } from '@refinedev/antd';
import {
  Form,
  Select,
  Input,
  Card,
  Row,
  Col,
  Typography,
  Tag,
  Space,
  Divider,
} from 'antd';
import dayjs from 'dayjs';

import { ACM_COLORS, severityColors } from '../../config/antd-theme';

const { Text } = Typography;
const { TextArea } = Input;

interface Alert {
  id: string;
  b_number: string;
  a_number: string;
  severity: string;
  status: string;
  threat_score: number;
  detection_type: string;
  carrier_name: string;
  created_at: string;
  notes: string;
  assigned_to: string;
}

const statusOptions = [
  { label: 'New', value: 'NEW' },
  { label: 'Investigating', value: 'INVESTIGATING' },
  { label: 'Confirmed', value: 'CONFIRMED' },
  { label: 'Resolved', value: 'RESOLVED' },
  { label: 'False Positive', value: 'FALSE_POSITIVE' },
];

export const AlertEdit: React.FC = () => {
  const { formProps, saveButtonProps, queryResult } = useForm<Alert>({
    resource: 'acm_alerts',
    redirect: 'show',
    meta: {
      fields: [
        'id',
        'b_number',
        'a_number',
        'severity',
        'status',
        'threat_score',
        'detection_type',
        'carrier_name',
        'created_at',
        'notes',
        'assigned_to',
      ],
    },
  });

  const alert = queryResult?.data?.data;

  // Get users for assignment
  const { selectProps: userSelectProps } = useSelect({
    resource: 'acm_users',
    optionLabel: 'name',
    optionValue: 'id',
    filters: [
      { field: 'is_active', operator: 'eq', value: true },
      { field: 'role', operator: 'in', value: ['admin', 'analyst'] },
    ],
  });

  const sevColors = alert ? (severityColors[alert.severity] || severityColors.LOW) : severityColors.LOW;

  return (
    <Edit saveButtonProps={saveButtonProps}>
      <Row gutter={[24, 24]}>
        {/* Alert Info (Read Only) */}
        <Col xs={24} lg={8}>
          <Card title="Alert Information" bordered={false}>
            {alert && (
              <Space direction="vertical" style={{ width: '100%' }}>
                <div>
                  <Text type="secondary">Severity</Text>
                  <div>
                    <Tag
                      style={{
                        backgroundColor: sevColors.background,
                        color: sevColors.color,
                        border: 'none',
                        marginTop: 4,
                      }}
                    >
                      {alert.severity}
                    </Tag>
                  </div>
                </div>

                <Divider style={{ margin: '12px 0' }} />

                <div>
                  <Text type="secondary">B-Number</Text>
                  <div>
                    <Text strong>{alert.b_number}</Text>
                  </div>
                </div>

                <div>
                  <Text type="secondary">A-Number</Text>
                  <div>
                    <Text>{alert.a_number}</Text>
                  </div>
                </div>

                <Divider style={{ margin: '12px 0' }} />

                <div>
                  <Text type="secondary">Threat Score</Text>
                  <div>
                    <Text
                      strong
                      style={{
                        color:
                          alert.threat_score >= 80
                            ? ACM_COLORS.critical
                            : alert.threat_score >= 60
                            ? ACM_COLORS.high
                            : ACM_COLORS.medium,
                        fontSize: 18,
                      }}
                    >
                      {alert.threat_score}%
                    </Text>
                  </div>
                </div>

                <div>
                  <Text type="secondary">Detection Type</Text>
                  <div>
                    <Text>{alert.detection_type?.replace(/_/g, ' ')}</Text>
                  </div>
                </div>

                <div>
                  <Text type="secondary">Carrier</Text>
                  <div>
                    <Text>{alert.carrier_name || 'Unknown'}</Text>
                  </div>
                </div>

                <Divider style={{ margin: '12px 0' }} />

                <div>
                  <Text type="secondary">Created</Text>
                  <div>
                    <Text style={{ fontSize: 12 }}>
                      {dayjs(alert.created_at).format('YYYY-MM-DD HH:mm:ss')}
                    </Text>
                  </div>
                </div>
              </Space>
            )}
          </Card>
        </Col>

        {/* Edit Form */}
        <Col xs={24} lg={16}>
          <Card title="Update Alert" bordered={false}>
            <Form {...formProps} layout="vertical">
              <Form.Item
                label="Status"
                name="status"
                rules={[{ required: true, message: 'Please select a status' }]}
              >
                <Select
                  options={statusOptions}
                  size="large"
                  placeholder="Select status"
                />
              </Form.Item>

              <Form.Item
                label="Assigned To"
                name="assigned_to"
              >
                <Select
                  {...userSelectProps}
                  allowClear
                  placeholder="Select analyst to assign"
                  size="large"
                />
              </Form.Item>

              <Form.Item
                label="Notes"
                name="notes"
                extra="Add any relevant notes or findings about this alert"
              >
                <TextArea
                  rows={6}
                  placeholder="Enter investigation notes, findings, or actions taken..."
                  showCount
                  maxLength={2000}
                />
              </Form.Item>
            </Form>

            {/* Status Guide */}
            <Divider orientation="left">Status Guide</Divider>
            <Space direction="vertical" size={8}>
              <Text>
                <Tag color="blue">NEW</Tag> - Alert just detected, awaiting review
              </Text>
              <Text>
                <Tag color="orange">INVESTIGATING</Tag> - Under active investigation
              </Text>
              <Text>
                <Tag color="red">CONFIRMED</Tag> - Verified as call masking attempt
              </Text>
              <Text>
                <Tag color="green">RESOLVED</Tag> - Action taken, issue resolved
              </Text>
              <Text>
                <Tag color="default">FALSE POSITIVE</Tag> - Not a real threat
              </Text>
            </Space>
          </Card>
        </Col>
      </Row>
    </Edit>
  );
};

export default AlertEdit;
