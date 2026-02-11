import React, { useState, useEffect } from 'react';
import { Card, Table, Tag, Button, Typography, Space, message } from 'antd';
import { FilterOutlined } from '@ant-design/icons';
import { voxguardApi, type CompositeDecision } from '../../api/voxguard';
import { AIDDTierBadge } from '../../components/common';

const { Title, Text } = Typography;

const decisionColor: Record<string, string> = {
  allow: 'green',
  block: 'red',
  review: 'orange',
};

export const CompositeScoringPage: React.FC = () => {
  const [decisions, setDecisions] = useState<CompositeDecision[]>([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    setLoading(true);
    voxguardApi
      .getCompositeDecisions()
      .then(setDecisions)
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  const columns = [
    { title: 'ID', dataIndex: 'id', key: 'id', width: 100, ellipsis: true },
    { title: 'Call ID', dataIndex: 'call_id', key: 'call_id', width: 120, ellipsis: true },
    {
      title: 'VoxGuard Score',
      dataIndex: 'voxguard_score',
      key: 'voxguard_score',
      render: (score: number) => (
        <Tag color={score >= 0.7 ? 'red' : score >= 0.4 ? 'orange' : 'green'}>
          {(score * 100).toFixed(0)}%
        </Tag>
      ),
    },
    {
      title: 'RVS Score',
      dataIndex: 'rvs_score',
      key: 'rvs_score',
      render: (score: number) => (
        <Tag color={score >= 0.7 ? 'green' : score >= 0.4 ? 'orange' : 'red'}>
          {(score * 100).toFixed(0)}%
        </Tag>
      ),
    },
    {
      title: 'Composite Score',
      dataIndex: 'composite_score',
      key: 'composite_score',
      render: (score: number) => (
        <Tag color={score >= 0.7 ? 'red' : score >= 0.4 ? 'orange' : 'green'}>
          {(score * 100).toFixed(0)}%
        </Tag>
      ),
    },
    {
      title: 'Decision',
      dataIndex: 'decision',
      key: 'decision',
      render: (decision: string) => (
        <Tag color={decisionColor[decision] || 'default'}>{decision.toUpperCase()}</Tag>
      ),
    },
    {
      title: 'Latency',
      dataIndex: 'latency_ms',
      key: 'latency_ms',
      render: (ms: number) => `${ms}ms`,
    },
    {
      title: 'Factors',
      dataIndex: 'factors',
      key: 'factors',
      render: (factors: CompositeDecision['factors']) => (
        <Space wrap>
          {factors.map((f) => (
            <Tag key={f.name} color="blue">
              {f.name}: {(f.contribution * 100).toFixed(0)}%
            </Tag>
          ))}
        </Space>
      ),
    },
  ];

  return (
    <div style={{ padding: 24 }}>
      <Title level={3}>Composite Scoring</Title>
      <Text type="secondary">Combined VoxGuard and RVS scoring decisions</Text>
      <div style={{ marginTop: 24 }}>
        <Card
          title={`Composite Decisions (${decisions.length})`}
          extra={
            <Space>
              <Button
                type="primary"
                icon={<FilterOutlined />}
                onClick={() => message.info('Threshold configuration would open here')}
              >
                Apply Threshold
              </Button>
              <AIDDTierBadge tier={1} compact />
            </Space>
          }
        >
          <Table
            columns={columns}
            dataSource={decisions}
            rowKey="id"
            size="small"
            loading={loading}
          />
        </Card>
      </div>
    </div>
  );
};

export default CompositeScoringPage;
