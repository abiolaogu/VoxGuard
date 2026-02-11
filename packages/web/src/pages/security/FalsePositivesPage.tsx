import React, { useState, useEffect } from 'react';
import { Card, Table, Tag, Typography, Space } from 'antd';
import { voxguardApi, type FalsePositiveCase } from '../../api/voxguard';

const { Title, Text } = Typography;

export const FalsePositivesPage: React.FC = () => {
  const [cases, setCases] = useState<FalsePositiveCase[]>([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    setLoading(true);
    voxguardApi
      .getFalsePositives()
      .then(setCases)
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  const statusColor: Record<string, string> = {
    confirmed: 'green',
    pending: 'orange',
    rejected: 'red',
    investigating: 'blue',
  };

  const columns = [
    { title: 'Alert Type', dataIndex: 'alert_type', key: 'alert_type', render: (type: string) => <Tag>{type}</Tag> },
    { title: 'Calling Number', dataIndex: 'calling_number', key: 'calling_number' },
    { title: 'Called Number', dataIndex: 'called_number', key: 'called_number' },
    {
      title: 'Original Score',
      dataIndex: 'original_score',
      key: 'original_score',
      render: (score: number) => (
        <Tag color={score >= 0.7 ? 'red' : score >= 0.4 ? 'orange' : 'green'}>
          {(score * 100).toFixed(0)}%
        </Tag>
      ),
    },
    {
      title: 'Confidence',
      dataIndex: 'confidence',
      key: 'confidence',
      render: (confidence: number) => (
        <Tag color={confidence >= 0.8 ? 'green' : confidence >= 0.5 ? 'orange' : 'red'}>
          {(confidence * 100).toFixed(0)}%
        </Tag>
      ),
    },
    {
      title: 'Detection Method',
      dataIndex: 'detection_method',
      key: 'detection_method',
      render: (method: string | undefined) => method ? <Tag color="blue">{method}</Tag> : '—',
    },
    {
      title: 'Status',
      dataIndex: 'status',
      key: 'status',
      render: (status: string) => (
        <Tag color={statusColor[status] || 'default'}>{status.toUpperCase()}</Tag>
      ),
    },
    {
      title: 'Matched Patterns',
      dataIndex: 'matched_patterns',
      key: 'matched_patterns',
      render: (patterns: string[] | undefined) =>
        patterns && patterns.length > 0 ? (
          <Space wrap>
            {patterns.map((p) => (
              <Tag key={p} color="purple">
                {p}
              </Tag>
            ))}
          </Space>
        ) : (
          '—'
        ),
    },
  ];

  return (
    <div style={{ padding: 24 }}>
      <Title level={3}>False Positives</Title>
      <Text type="secondary">Review and manage false positive detections</Text>
      <div style={{ marginTop: 24 }}>
        <Card title={`False Positive Cases (${cases.length})`}>
          <Table
            columns={columns}
            dataSource={cases}
            rowKey="id"
            size="small"
            loading={loading}
          />
        </Card>
      </div>
    </div>
  );
};

export default FalsePositivesPage;
