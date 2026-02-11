import React, { useState, useEffect } from 'react';
import { Card, Table, Tag, Button, Tabs, Typography, Space, message } from 'antd';
import { StopOutlined } from '@ant-design/icons';
import { voxguardApi, type WangiriIncident, type IrsfIncident } from '../../api/voxguard';
import { AIDDTierBadge } from '../../components/common';

const { Title, Text } = Typography;

export const RevenueFraudPage: React.FC = () => {
  const [wangiri, setWangiri] = useState<WangiriIncident[]>([]);
  const [irsf, setIrsf] = useState<IrsfIncident[]>([]);
  const [loading, setLoading] = useState(false);

  const loadData = () => {
    setLoading(true);
    Promise.all([
      voxguardApi.getWangiriIncidents().then(setWangiri).catch(() => {}),
      voxguardApi.getIrsfIncidents().then(setIrsf).catch(() => {}),
    ]).finally(() => setLoading(false));
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleBlockWangiri = async (id: string) => {
    try {
      await voxguardApi.blockWangiri(id);
      message.success('Wangiri number blocked successfully');
      loadData();
    } catch {
      message.error('Failed to block number');
    }
  };

  const wangiriColumns = [
    { title: 'Calling Number', dataIndex: 'calling_number', key: 'calling_number' },
    { title: 'Country', dataIndex: 'country', key: 'country' },
    {
      title: 'Ring Duration',
      dataIndex: 'ring_duration_sec',
      key: 'ring_duration_sec',
      render: (sec: number) => `${sec}s`,
    },
    { title: 'Callback Count', dataIndex: 'callback_count', key: 'callback_count' },
    {
      title: 'Revenue Risk',
      dataIndex: 'revenue_risk',
      key: 'revenue_risk',
      render: (risk: number) => (
        <Tag color={risk >= 100 ? 'red' : risk >= 50 ? 'orange' : 'green'}>
          ${risk.toFixed(2)}
        </Tag>
      ),
    },
    {
      title: 'Status',
      dataIndex: 'status',
      key: 'status',
      render: (status: string) => {
        const color =
          status === 'active' ? 'red' : status === 'blocked' ? 'volcano' : status === 'resolved' ? 'green' : 'default';
        return <Tag color={color}>{status.toUpperCase()}</Tag>;
      },
    },
    {
      title: 'Actions',
      key: 'actions',
      render: (_: unknown, record: WangiriIncident) =>
        record.status === 'active' ? (
          <Space>
            <Button
              type="primary"
              danger
              size="small"
              icon={<StopOutlined />}
              onClick={() => handleBlockWangiri(record.id)}
            >
              Block
            </Button>
            <AIDDTierBadge tier={1} compact />
          </Space>
        ) : null,
    },
  ];

  const irsfColumns = [
    { title: 'Destination', dataIndex: 'destination', key: 'destination' },
    { title: 'Country', dataIndex: 'country', key: 'country' },
    {
      title: 'Total Minutes',
      dataIndex: 'total_minutes',
      key: 'total_minutes',
      render: (mins: number) => `${mins.toFixed(1)} min`,
    },
    {
      title: 'Total Cost',
      dataIndex: 'total_cost',
      key: 'total_cost',
      render: (cost: number) => (
        <Tag color={cost >= 500 ? 'red' : cost >= 100 ? 'orange' : 'green'}>
          ${cost.toFixed(2)}
        </Tag>
      ),
    },
    {
      title: 'Pump Pattern',
      dataIndex: 'pump_pattern',
      key: 'pump_pattern',
      render: (pattern: string) => <Tag color="purple">{pattern}</Tag>,
    },
    {
      title: 'Status',
      dataIndex: 'status',
      key: 'status',
      render: (status: string) => {
        const color =
          status === 'active' ? 'red' : status === 'blocked' ? 'volcano' : status === 'resolved' ? 'green' : 'default';
        return <Tag color={color}>{status.toUpperCase()}</Tag>;
      },
    },
  ];

  const tabItems = [
    {
      key: 'wangiri',
      label: `Wangiri (${wangiri.length})`,
      children: (
        <Card title="Wangiri Fraud Incidents">
          <Table
            columns={wangiriColumns}
            dataSource={wangiri}
            rowKey="id"
            size="small"
            loading={loading}
          />
        </Card>
      ),
    },
    {
      key: 'irsf',
      label: `IRSF (${irsf.length})`,
      children: (
        <Card title="IRSF Fraud Incidents">
          <Table
            columns={irsfColumns}
            dataSource={irsf}
            rowKey="id"
            size="small"
            loading={loading}
          />
        </Card>
      ),
    },
  ];

  return (
    <div style={{ padding: 24 }}>
      <Title level={3}>Revenue Fraud Detection</Title>
      <Text type="secondary">Wangiri and IRSF fraud monitoring</Text>
      <div style={{ marginTop: 24 }}>
        <Tabs items={tabItems} />
      </div>
    </div>
  );
};

export default RevenueFraudPage;
