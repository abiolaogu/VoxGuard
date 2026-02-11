import React, { useState, useEffect } from 'react';
import { Card, Table, Tag, Button, Typography, Space, message } from 'antd';
import { StopOutlined, CheckCircleOutlined } from '@ant-design/icons';
import { voxguardApi, type MultiCallPattern } from '../../api/voxguard';

const { Title, Text } = Typography;

export const MultiCallDetectionPage: React.FC = () => {
  const [patterns, setPatterns] = useState<MultiCallPattern[]>([]);
  const [loading, setLoading] = useState(false);

  const loadPatterns = () => {
    setLoading(true);
    voxguardApi
      .getMultiCallPatterns()
      .then(setPatterns)
      .catch(() => {})
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    loadPatterns();
  }, []);

  const handleBlock = async (id: string) => {
    try {
      await voxguardApi.blockMultiCallPattern(id);
      message.success('Pattern blocked successfully');
      loadPatterns();
    } catch {
      message.error('Failed to block pattern');
    }
  };

  const handleResolve = (id: string) => {
    // Mark pattern as resolved locally (API would handle this in production)
    setPatterns((prev) =>
      prev.map((p) => (p.id === id ? { ...p, status: 'resolved' } : p))
    );
    message.success('Pattern marked as resolved');
  };

  const columns = [
    { title: 'B-Number', dataIndex: 'b_number', key: 'b_number' },
    { title: 'Call Count', dataIndex: 'call_count', key: 'call_count' },
    { title: 'Unique A-Numbers', dataIndex: 'unique_a_numbers', key: 'unique_a_numbers' },
    {
      title: 'Time Window',
      dataIndex: 'time_window_minutes',
      key: 'time_window_minutes',
      render: (mins: number) => `${mins} min`,
    },
    {
      title: 'Risk Score',
      dataIndex: 'risk_score',
      key: 'risk_score',
      render: (score: number) => (
        <Tag color={score >= 0.8 ? 'red' : score >= 0.5 ? 'orange' : 'green'}>
          {(score * 100).toFixed(0)}%
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
      title: 'Fraud Type',
      dataIndex: 'fraud_type',
      key: 'fraud_type',
      render: (type: string | undefined) => type ? <Tag color="purple">{type}</Tag> : '—',
    },
    {
      title: 'Actions',
      key: 'actions',
      render: (_: unknown, record: MultiCallPattern) => (
        <Space>
          {record.status === 'active' && (
            <>
              <Button
                type="primary"
                danger
                size="small"
                icon={<StopOutlined />}
                onClick={() => handleBlock(record.id)}
              >
                Block
              </Button>
              <Button
                size="small"
                icon={<CheckCircleOutlined />}
                onClick={() => handleResolve(record.id)}
              >
                Resolve
              </Button>
            </>
          )}
        </Space>
      ),
    },
  ];

  return (
    <div style={{ padding: 24 }}>
      <Title level={3}>Multi-Call Detection</Title>
      <Text type="secondary">Detect and manage suspicious multi-call patterns</Text>
      <div style={{ marginTop: 24 }}>
        <Card title={`Multi-Call Patterns (${patterns.length})`}>
          <Table
            columns={columns}
            dataSource={patterns}
            rowKey="id"
            size="small"
            loading={loading}
          />
        </Card>
      </div>
    </div>
  );
};

export default MultiCallDetectionPage;
