import {
  List,
  useTable,
  FilterDropdown,
  getDefaultSortOrder,
  ShowButton,
  EditButton,
} from '@refinedev/antd';
import {
  Table,
  Space,
  Tag,
  Input,
  Select,
  Button,
  Typography,
  Row,
  Col,
  Card,
  Statistic,
  Tooltip,
} from 'antd';
import {
  SearchOutlined,
  ReloadOutlined,
  AlertOutlined,
  ExclamationCircleOutlined,
} from '@ant-design/icons';
import { useSubscription } from '@apollo/client';
import dayjs from 'dayjs';

import { UNRESOLVED_ALERTS_COUNT_SUBSCRIPTION } from '../../graphql/subscriptions';
import { ACM_COLORS, severityColors, statusColors } from '../../config/antd-theme';

const { Text } = Typography;

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
  updated_at: string;
}

const severityOptions = [
  { label: 'Critical', value: 'CRITICAL' },
  { label: 'High', value: 'HIGH' },
  { label: 'Medium', value: 'MEDIUM' },
  { label: 'Low', value: 'LOW' },
];

const statusOptions = [
  { label: 'New', value: 'NEW' },
  { label: 'Investigating', value: 'INVESTIGATING' },
  { label: 'Confirmed', value: 'CONFIRMED' },
  { label: 'Resolved', value: 'RESOLVED' },
  { label: 'False Positive', value: 'FALSE_POSITIVE' },
];

export const AlertList: React.FC = () => {
  const { tableProps, sorters } = useTable<Alert>({
    resource: 'acm_alerts',
    sorters: {
      initial: [{ field: 'created_at', order: 'desc' }],
    },
    filters: {
      initial: [
        { field: 'status', operator: 'nin', value: ['RESOLVED', 'FALSE_POSITIVE'] },
      ],
    },
    pagination: {
      pageSize: 20,
    },
    syncWithLocation: true,
    liveMode: 'auto',
  });

  // Real-time counts
  const { data: alertCounts } = useSubscription(UNRESOLVED_ALERTS_COUNT_SUBSCRIPTION);

  const newCount = alertCounts?.new_count?.aggregate?.count || 0;
  const criticalCount = alertCounts?.critical_count?.aggregate?.count || 0;

  const columns = [
    {
      title: 'Time',
      dataIndex: 'created_at',
      key: 'created_at',
      sorter: true,
      defaultSortOrder: getDefaultSortOrder('created_at', sorters),
      width: 160,
      render: (date: string) => (
        <Tooltip title={dayjs(date).format('YYYY-MM-DD HH:mm:ss')}>
          <Text style={{ fontSize: 12 }}>
            {dayjs(date).format('MMM DD, HH:mm')}
          </Text>
        </Tooltip>
      ),
    },
    {
      title: 'B-Number',
      dataIndex: 'b_number',
      key: 'b_number',
      filterDropdown: (props: any) => (
        <FilterDropdown {...props}>
          <Input
            placeholder="Search B-Number"
            prefix={<SearchOutlined />}
            style={{ width: 200 }}
          />
        </FilterDropdown>
      ),
      render: (text: string) => <Text strong copyable>{text}</Text>,
    },
    {
      title: 'A-Number',
      dataIndex: 'a_number',
      key: 'a_number',
      render: (text: string) => <Text copyable={{ text }}>{text}</Text>,
    },
    {
      title: 'Severity',
      dataIndex: 'severity',
      key: 'severity',
      width: 100,
      filterDropdown: (props: any) => (
        <FilterDropdown {...props}>
          <Select
            mode="multiple"
            placeholder="Select severity"
            options={severityOptions}
            style={{ width: 200 }}
          />
        </FilterDropdown>
      ),
      render: (severity: string) => {
        const colors = severityColors[severity] || severityColors.LOW;
        return (
          <Tag
            style={{
              backgroundColor: colors.background,
              color: colors.color,
              border: 'none',
              fontWeight: 600,
            }}
          >
            {severity}
          </Tag>
        );
      },
    },
    {
      title: 'Status',
      dataIndex: 'status',
      key: 'status',
      width: 130,
      filterDropdown: (props: any) => (
        <FilterDropdown {...props}>
          <Select
            mode="multiple"
            placeholder="Select status"
            options={statusOptions}
            style={{ width: 200 }}
          />
        </FilterDropdown>
      ),
      render: (status: string) => {
        const colors = statusColors[status] || statusColors.NEW;
        return (
          <Tag
            style={{
              backgroundColor: colors.background,
              color: colors.color,
              border: 'none',
            }}
          >
            {status.replace('_', ' ')}
          </Tag>
        );
      },
    },
    {
      title: 'Score',
      dataIndex: 'threat_score',
      key: 'threat_score',
      sorter: true,
      width: 80,
      render: (score: number) => (
        <Text
          strong
          style={{
            color:
              score >= 80
                ? ACM_COLORS.critical
                : score >= 60
                ? ACM_COLORS.high
                : ACM_COLORS.medium,
          }}
        >
          {score}%
        </Text>
      ),
    },
    {
      title: 'Detection',
      dataIndex: 'detection_type',
      key: 'detection_type',
      width: 140,
      render: (type: string) => (
        <Text type="secondary" style={{ fontSize: 12 }}>
          {type?.replace(/_/g, ' ')}
        </Text>
      ),
    },
    {
      title: 'Carrier',
      dataIndex: 'carrier_name',
      key: 'carrier_name',
      width: 120,
      ellipsis: true,
    },
    {
      title: 'Actions',
      key: 'actions',
      fixed: 'right' as const,
      width: 100,
      render: (_: unknown, record: Alert) => (
        <Space size="small">
          <ShowButton
            hideText
            size="small"
            recordItemId={record.id}
          />
          <EditButton
            hideText
            size="small"
            recordItemId={record.id}
          />
        </Space>
      ),
    },
  ];

  return (
    <List
      title="Alert Management"
      headerButtons={({ defaultButtons }) => (
        <>
          <Button
            icon={<ReloadOutlined />}
            onClick={() => window.location.reload()}
          >
            Refresh
          </Button>
          {defaultButtons}
        </>
      )}
    >
      {/* Stats Row */}
      <Row gutter={16} style={{ marginBottom: 16 }}>
        <Col xs={12} sm={6}>
          <Card size="small" bordered={false}>
            <Statistic
              title="New Alerts"
              value={newCount}
              prefix={<AlertOutlined style={{ color: ACM_COLORS.info }} />}
              valueStyle={{ fontSize: 20 }}
            />
          </Card>
        </Col>
        <Col xs={12} sm={6}>
          <Card size="small" bordered={false}>
            <Statistic
              title="Critical"
              value={criticalCount}
              prefix={<ExclamationCircleOutlined style={{ color: ACM_COLORS.critical }} />}
              valueStyle={{ fontSize: 20, color: criticalCount > 0 ? ACM_COLORS.critical : undefined }}
            />
          </Card>
        </Col>
      </Row>

      {/* Alerts Table */}
      <Table
        {...tableProps}
        columns={columns}
        rowKey="id"
        scroll={{ x: 1200 }}
        size="middle"
        rowClassName={(record) =>
          record.severity === 'CRITICAL' ? 'ant-table-row-critical' : ''
        }
      />
    </List>
  );
};

export default AlertList;
