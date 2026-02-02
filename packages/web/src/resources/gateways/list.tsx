import React from 'react';
import {
  List,
  useTable,
  DateField,
  TagField,
  EditButton,
  ShowButton,
  DeleteButton,
} from '@refinedev/antd';
import { Table, Space, Tag, Badge, Tooltip, Typography } from 'antd';
import {
  CheckCircleOutlined,
  CloseCircleOutlined,
  WarningOutlined,
  StopOutlined,
  ApiOutlined,
} from '@ant-design/icons';
import type { IResourceComponentsProps } from '@refinedev/core';

const { Text } = Typography;

export interface IGateway {
  id: string;
  name: string;
  code: string;
  ip_address: string;
  port: number;
  protocol: string;
  carrier_name: string;
  carrier_type: string;
  region: string;
  gateway_type: string;
  direction: string;
  status: 'active' | 'inactive' | 'suspended' | 'blacklisted';
  is_blacklisted: boolean;
  health_status: 'healthy' | 'degraded' | 'critical' | 'unknown';
  total_calls_today: number;
  failed_calls_today: number;
  fraud_alerts_today: number;
  current_concurrent_calls: number;
  current_cps: number;
  is_ncc_compliant: boolean;
  created_at: string;
  updated_at: string;
}

export const GatewayList: React.FC<IResourceComponentsProps> = () => {
  const { tableProps } = useTable<IGateway>({
    syncWithLocation: true,
    sorters: {
      initial: [
        {
          field: 'created_at',
          order: 'desc',
        },
      ],
    },
  });

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'active':
        return <CheckCircleOutlined style={{ color: '#52c41a' }} />;
      case 'inactive':
        return <CloseCircleOutlined style={{ color: '#d9d9d9' }} />;
      case 'suspended':
        return <WarningOutlined style={{ color: '#faad14' }} />;
      case 'blacklisted':
        return <StopOutlined style={{ color: '#ff4d4f' }} />;
      default:
        return null;
    }
  };

  const getStatusColor = (status: string) => {
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

  const getHealthColor = (health: string) => {
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
    <List>
      <Table {...tableProps} rowKey="id" size="middle">
        <Table.Column
          dataIndex="name"
          title="Gateway Name"
          sorter
          render={(value: string, record: IGateway) => (
            <Space direction="vertical" size={0}>
              <Text strong>{value}</Text>
              <Text type="secondary" style={{ fontSize: '12px' }}>
                {record.code}
              </Text>
            </Space>
          )}
        />

        <Table.Column
          dataIndex="ip_address"
          title="Network"
          render={(value: string, record: IGateway) => (
            <Space direction="vertical" size={0}>
              <Text>
                <ApiOutlined /> {value}:{record.port}
              </Text>
              <Tag style={{ fontSize: '11px' }}>{record.protocol}</Tag>
            </Space>
          )}
        />

        <Table.Column
          dataIndex="carrier_name"
          title="Carrier"
          sorter
          render={(value: string, record: IGateway) => (
            <Space direction="vertical" size={0}>
              <Text>{value}</Text>
              <Text type="secondary" style={{ fontSize: '12px' }}>
                {record.carrier_type} • {record.region}
              </Text>
            </Space>
          )}
        />

        <Table.Column
          dataIndex="gateway_type"
          title="Type"
          sorter
          render={(value: string, record: IGateway) => (
            <Space direction="vertical" size={0}>
              <Tag color="blue">{value.toUpperCase()}</Tag>
              <Text type="secondary" style={{ fontSize: '11px' }}>
                {record.direction}
              </Text>
            </Space>
          )}
        />

        <Table.Column
          dataIndex="status"
          title="Status"
          sorter
          filters={[
            { text: 'Active', value: 'active' },
            { text: 'Inactive', value: 'inactive' },
            { text: 'Suspended', value: 'suspended' },
            { text: 'Blacklisted', value: 'blacklisted' },
          ]}
          onFilter={(value, record: IGateway) => record.status === value}
          render={(value: string, record: IGateway) => (
            <Space direction="vertical" size={4}>
              <Tag color={getStatusColor(value)} icon={getStatusIcon(value)}>
                {value.toUpperCase()}
              </Tag>
              {record.is_blacklisted && (
                <Tag color="red" style={{ fontSize: '10px' }}>
                  BLACKLISTED
                </Tag>
              )}
            </Space>
          )}
        />

        <Table.Column
          dataIndex="health_status"
          title="Health"
          sorter
          render={(value: string) => (
            <Badge status={getHealthColor(value)} text={value.toUpperCase()} />
          )}
        />

        <Table.Column
          dataIndex="total_calls_today"
          title="Calls Today"
          sorter
          render={(value: number, record: IGateway) => (
            <Space direction="vertical" size={0}>
              <Text strong>{value?.toLocaleString() || 0}</Text>
              <Text type="secondary" style={{ fontSize: '11px' }}>
                {record.fraud_alerts_today > 0 && (
                  <Text type="danger">{record.fraud_alerts_today} alerts</Text>
                )}
                {record.fraud_alerts_today === 0 && (
                  <Text type="success">No alerts</Text>
                )}
              </Text>
            </Space>
          )}
        />

        <Table.Column
          dataIndex="current_cps"
          title="CPS"
          sorter
          render={(value: number, record: IGateway) => (
            <Space direction="vertical" size={0}>
              <Text>{value?.toFixed(1) || '0.0'}</Text>
              <Text type="secondary" style={{ fontSize: '11px' }}>
                {record.current_concurrent_calls || 0} concurrent
              </Text>
            </Space>
          )}
        />

        <Table.Column
          dataIndex="is_ncc_compliant"
          title="NCC"
          render={(value: boolean) =>
            value ? (
              <Tooltip title="NCC Compliant">
                <Tag color="success">
                  <CheckCircleOutlined /> Compliant
                </Tag>
              </Tooltip>
            ) : (
              <Tooltip title="Non-compliant">
                <Tag color="warning">
                  <WarningOutlined /> Non-compliant
                </Tag>
              </Tooltip>
            )
          }
        />

        <Table.Column
          dataIndex="created_at"
          title="Created"
          sorter
          render={(value: string) => <DateField value={value} format="LLL" />}
        />

        <Table.Column
          title="Actions"
          dataIndex="actions"
          render={(_: any, record: IGateway) => (
            <Space>
              <ShowButton hideText size="small" recordItemId={record.id} />
              <EditButton hideText size="small" recordItemId={record.id} />
              <DeleteButton hideText size="small" recordItemId={record.id} />
            </Space>
          )}
        />
      </Table>
    </List>
  );
};
