
import {
  List,
  useTable,
  FilterDropdown,
  ShowButton,
  DateField,
} from '@refinedev/antd';
import { Table, Space, Tag, Select, Typography } from 'antd';
import {
  PhoneOutlined,
  SafetyCertificateOutlined,
  WarningOutlined,
  StopOutlined,
} from '@ant-design/icons';


const { Text } = Typography;

interface Call {
  id: string;
  call_id: string;
  a_number: string;
  b_number: string;
  carrier: string;
  status: 'verified' | 'masked' | 'failed' | 'suspicious';
  latency_ms: number;
  created_at: string;
}

const statusConfig: Record<string, { color: string; icon: React.ReactNode; label: string }> = {
  verified: { color: 'success', icon: <SafetyCertificateOutlined />, label: 'Verified' },
  masked: { color: 'error', icon: <StopOutlined />, label: 'Masked' },
  suspicious: { color: 'warning', icon: <WarningOutlined />, label: 'Suspicious' },
  failed: { color: 'default', icon: <WarningOutlined />, label: 'Failed' },
};

export const CallList: React.FC = () => {
  const { tableProps } = useTable<Call>({
    resource: 'call_logs',
    sorters: {
      initial: [{ field: 'created_at', order: 'desc' }],
    },
    pagination: {
      pageSize: 20,
    },
    syncWithLocation: true,
  });

  const columns = [
    {
      title: 'Time',
      dataIndex: 'created_at',
      key: 'created_at',
      sorter: true,
      width: 180,
      render: (value: string) => <DateField value={value} format="YYYY-MM-DD HH:mm:ss" />,
    },
    {
      title: 'Caller (A-Num)',
      dataIndex: 'a_number',
      key: 'a_number',
      render: (value: string) => (
        <Space>
          <PhoneOutlined style={{ color: '#8c8c8c' }} />
          <Text>{value}</Text>
        </Space>
      ),
    },
    {
      title: 'Receiver (B-Num)',
      dataIndex: 'b_number',
      key: 'b_number',
      render: (value: string) => <Text>{value}</Text>,
    },
    {
      title: 'Carrier',
      dataIndex: 'carrier',
      key: 'carrier',
      width: 120,
      filterDropdown: (props: any) => (
        <FilterDropdown {...props}>
          <Select
            placeholder="Select Carrier"
            options={[
              { label: 'MTN', value: 'MTN' },
              { label: 'Glo', value: 'Glo' },
              { label: 'Airtel', value: 'Airtel' },
              { label: '9mobile', value: '9mobile' },
            ]}
          />
        </FilterDropdown>
      ),
      render: (value: string) => <Tag>{value}</Tag>,
    },
    {
      title: 'Status',
      dataIndex: 'status',
      key: 'status',
      width: 140,
      filterDropdown: (props: any) => (
        <FilterDropdown {...props}>
          <Select
            placeholder="Status"
            options={[
              { label: 'Verified', value: 'verified' },
              { label: 'Masked', value: 'masked' },
              { label: 'Suspicious', value: 'suspicious' },
            ]}
          />
        </FilterDropdown>
      ),
      render: (value: string) => {
        const config = statusConfig[value?.toLowerCase()] || statusConfig.failed;
        return (
          <Tag color={config.color} icon={config.icon}>
            {config.label}
          </Tag>
        );
      },
    },
    {
      title: 'Latency',
      dataIndex: 'latency_ms',
      key: 'latency_ms',
      width: 100,
      sorter: true,
      render: (value: number) => (
        <Text type={value > 200 ? 'danger' : 'secondary'}>{value} ms</Text>
      ),
    },
    {
      title: 'Actions',
      key: 'actions',
      fixed: 'right' as const,
      width: 80,
      render: (_: unknown, record: Call) => (
        <Space size="small">
          <ShowButton hideText size="small" recordItemId={record.id} />
        </Space>
      ),
    },
  ];

  return (
    <List title="Call Verifications" resource="call_logs">
      <Table
        {...tableProps}
        columns={columns}
        rowKey="id"
        size="small"
        scroll={{ x: 1000 }}
      />
    </List>
  );
};
