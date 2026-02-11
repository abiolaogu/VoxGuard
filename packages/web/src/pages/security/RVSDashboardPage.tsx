import React, { useState, useEffect } from 'react';
import { Card, Row, Col, Statistic, Table, Tag, Badge, Tabs, Switch, Typography, Space, Button } from 'antd';
import { CheckCircleOutlined, ClockCircleOutlined, ThunderboltOutlined, SafetyCertificateOutlined } from '@ant-design/icons';
import { voxguardApi, type RVSHealth, type VerificationRequest, type FeatureFlag, type MLModelStatus, type DetectionEngineHealth } from '../../api/voxguard';

const { Title, Text } = Typography;

export const RVSDashboardPage: React.FC = () => {
  const [health, setHealth] = useState<RVSHealth | null>(null);
  const [verifications, setVerifications] = useState<VerificationRequest[]>([]);
  const [featureFlags, setFeatureFlags] = useState<FeatureFlag[]>([]);
  const [mlModels, setMlModels] = useState<MLModelStatus[]>([]);
  const [detectionHealth, setDetectionHealth] = useState<DetectionEngineHealth | null>(null);

  useEffect(() => {
    voxguardApi.getRVSHealth().then(setHealth).catch(() => {});
    voxguardApi.getVerifications().then(setVerifications).catch(() => {});
    voxguardApi.getFeatureFlags().then(setFeatureFlags).catch(() => {});
    voxguardApi.getMLModelStatus().then(setMlModels).catch(() => {});
    voxguardApi.getDetectionHealth().then(setDetectionHealth).catch(() => {});
  }, []);

  const columns = [
    { title: 'ID', dataIndex: 'id', key: 'id', width: 100, ellipsis: true },
    { title: 'Calling #', dataIndex: 'calling_number', key: 'calling_number' },
    { title: 'Called #', dataIndex: 'called_number', key: 'called_number' },
    {
      title: 'RVS Score', dataIndex: 'rvs_score', key: 'rvs_score',
      render: (score: number) => <Tag color={score >= 0.7 ? 'green' : score >= 0.4 ? 'orange' : 'red'}>{(score * 100).toFixed(0)}%</Tag>,
    },
    {
      title: 'HLR Status', dataIndex: 'hlr_status', key: 'hlr_status',
      render: (s: string) => <Tag color={s === 'valid' ? 'green' : s === 'invalid' ? 'red' : 'default'}>{s}</Tag>,
    },
    { title: 'Network', dataIndex: 'hlr_network', key: 'hlr_network' },
    { title: 'Country', dataIndex: 'hlr_country', key: 'hlr_country' },
    { title: 'Response', dataIndex: 'response_time_ms', key: 'response_time_ms', render: (ms: number) => `${ms}ms` },
    { title: 'Cached', dataIndex: 'cached', key: 'cached', render: (c: boolean) => c ? <Tag color="green">Yes</Tag> : <Tag>No</Tag> },
  ];

  const tabItems = [
    {
      key: 'overview',
      label: 'Overview',
      children: (
        <>
          <Row gutter={16} style={{ marginBottom: 24 }}>
            <Col span={6}><Card><Statistic title="RVS Status" value={health?.status || '—'} prefix={<CheckCircleOutlined style={{ color: health?.status === 'connected' ? '#52c41a' : '#ff4d4f' }} />} /></Card></Col>
            <Col span={6}><Card><Statistic title="Latency" value={health?.latency_ms || 0} suffix="ms" prefix={<ThunderboltOutlined />} /></Card></Col>
            <Col span={6}><Card><Statistic title="Uptime" value={health?.uptime_pct || 0} suffix="%" prefix={<ClockCircleOutlined />} /></Card></Col>
            <Col span={6}><Card><Statistic title="Circuit Breaker" value={health?.circuit_breaker || '—'} prefix={<SafetyCertificateOutlined />} /></Card></Col>
          </Row>
          <Card title="Recent Verifications">
            <Table columns={columns} dataSource={verifications.slice(0, 10)} rowKey="id" size="small" pagination={false} />
          </Card>
        </>
      ),
    },
    {
      key: 'verifications',
      label: 'Verifications',
      children: (
        <Card title={`All Verifications (${verifications.length})`}>
          <Table columns={columns} dataSource={verifications} rowKey="id" size="small" />
        </Card>
      ),
    },
    {
      key: 'config',
      label: 'Configuration',
      children: (
        <Space direction="vertical" style={{ width: '100%' }} size="large">
          <Card title="Feature Flags">
            {featureFlags.map((flag) => (
              <div key={flag.id} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '12px 0', borderBottom: '1px solid #f0f0f0' }}>
                <div>
                  <Text strong>{flag.name}</Text>
                  <br />
                  <Text type="secondary" style={{ fontSize: 12 }}>{flag.description}</Text>
                </div>
                <Space>
                  <Tag>{flag.phase}</Tag>
                  <Switch checked={flag.enabled} onChange={(checked) => voxguardApi.updateFeatureFlag(flag.id, checked)} />
                </Space>
              </div>
            ))}
          </Card>
          {mlModels.length > 0 && (
            <Card title="ML Model Status">
              <Row gutter={16}>
                {mlModels.map((m) => (
                  <Col span={8} key={m.model_name}>
                    <Card size="small">
                      <Space direction="vertical" style={{ width: '100%' }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                          <Text strong>{m.model_name}</Text>
                          <Tag color={m.status === 'active' ? 'green' : m.status === 'shadow' ? 'orange' : 'default'}>{m.status}</Tag>
                        </div>
                        <Text type="secondary">v{m.version} | Accuracy: {(m.accuracy * 100).toFixed(1)}% | {m.features_count} features</Text>
                      </Space>
                    </Card>
                  </Col>
                ))}
              </Row>
            </Card>
          )}
          {detectionHealth && (
            <Card title="Detection Engine Health">
              <Row gutter={16}>
                <Col span={6}><Statistic title="P99 Latency" value={detectionHealth.latency_p99_ms} suffix="ms" /></Col>
                <Col span={6}><Statistic title="Calls/sec" value={detectionHealth.calls_per_second} /></Col>
                <Col span={6}><Statistic title="Cache Hit Rate" value={(detectionHealth.cache_hit_rate * 100).toFixed(0)} suffix="%" /></Col>
                <Col span={6}><Statistic title="Uptime" value={detectionHealth.uptime_pct} suffix="%" /></Col>
              </Row>
            </Card>
          )}
        </Space>
      ),
    },
  ];

  return (
    <div style={{ padding: 24 }}>
      <Title level={3}>RVS Dashboard</Title>
      <Text type="secondary">Real-time Verification Service monitoring</Text>
      <div style={{ marginTop: 24 }}>
        <Tabs items={tabItems} />
      </div>
    </div>
  );
};

export default RVSDashboardPage;
