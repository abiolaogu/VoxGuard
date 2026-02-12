import React, { useState } from 'react';
import { Card, Typography, Row, Col, Tag, Button, Progress, Space, Statistic, Badge, message } from 'antd';
import { ReloadOutlined, ExperimentOutlined, RobotOutlined } from '@ant-design/icons';
import { useTranslation } from 'react-i18next';
import { useLocale } from '../../hooks/useLocale';
import { AIDDTierBadge } from '../../components/common';
import '../../styles/pages.css';

const { Title, Text } = Typography;

interface MLModel {
  id: string;
  model_name: string;
  version: string;
  status: 'active' | 'shadow' | 'retired';
  accuracy: number;
  auc: number;
  f1_score: number;
  last_trained: string;
  features_count: number;
  ab_test_status?: string;
  predictions_today: number;
  avg_latency_ms: number;
}

const mockModels: MLModel[] = [
  {
    id: 'mdl-001',
    model_name: 'Fraud Detector',
    version: 'v3.2.1',
    status: 'active',
    accuracy: 0.946,
    auc: 0.982,
    f1_score: 0.931,
    last_trained: '2025-04-18T03:00:00Z',
    features_count: 47,
    predictions_today: 12450,
    avg_latency_ms: 23,
  },
  {
    id: 'mdl-002',
    model_name: 'CLI Spoofing Classifier',
    version: 'v2.1.0',
    status: 'active',
    accuracy: 0.923,
    auc: 0.965,
    f1_score: 0.908,
    last_trained: '2025-04-15T03:00:00Z',
    features_count: 32,
    predictions_today: 8920,
    avg_latency_ms: 15,
  },
  {
    id: 'mdl-003',
    model_name: 'Wangiri Pattern Detector',
    version: 'v1.8.3',
    status: 'active',
    accuracy: 0.958,
    auc: 0.991,
    f1_score: 0.944,
    last_trained: '2025-04-10T03:00:00Z',
    features_count: 28,
    predictions_today: 5600,
    avg_latency_ms: 12,
  },
  {
    id: 'mdl-004',
    model_name: 'Fraud Detector',
    version: 'v3.3.0-beta',
    status: 'shadow',
    accuracy: 0.951,
    auc: 0.985,
    f1_score: 0.938,
    last_trained: '2025-04-19T03:00:00Z',
    features_count: 52,
    ab_test_status: 'Running — 20% traffic split',
    predictions_today: 2490,
    avg_latency_ms: 28,
  },
  {
    id: 'mdl-005',
    model_name: 'IRSF Risk Scorer',
    version: 'v1.5.0',
    status: 'active',
    accuracy: 0.912,
    auc: 0.954,
    f1_score: 0.897,
    last_trained: '2025-04-12T03:00:00Z',
    features_count: 35,
    predictions_today: 3200,
    avg_latency_ms: 18,
  },
  {
    id: 'mdl-006',
    model_name: 'Traffic Anomaly Detector',
    version: 'v2.0.1',
    status: 'retired',
    accuracy: 0.876,
    auc: 0.921,
    f1_score: 0.853,
    last_trained: '2025-03-01T03:00:00Z',
    features_count: 25,
    predictions_today: 0,
    avg_latency_ms: 0,
  },
];

const statusColor: Record<string, string> = {
  active: 'green',
  shadow: 'blue',
  retired: 'default',
};

export const MLDashboardPage: React.FC = () => {
  const { t } = useTranslation();
  const { formatDate, formatNumber } = useLocale();
  const [models] = useState<MLModel[]>(mockModels);

  const handleRetrain = (modelId: string) => {
    message.success(t('ml.retrainRequested'));
    console.log('Retraining model:', modelId);
  };

  const activeModels = models.filter((m) => m.status === 'active');
  const totalPredictions = models.reduce((sum, m) => sum + m.predictions_today, 0);

  return (
    <div className="vg-page-wrapper acm-fade-in">
      <Title level={3} className="vg-page-title">{t('ml.title')}</Title>
      <Text type="secondary">{t('ml.subtitle')}</Text>

      <Row gutter={[16, 16]} style={{ marginTop: 24, marginBottom: 24 }}>
        <Col xs={24} sm={8}>
          <Card className="acm-stats-card">
            <Statistic
              title={t('common.active') + ' Models'}
              value={activeModels.length}
              prefix={<RobotOutlined />}
            />
          </Card>
        </Col>
        <Col xs={24} sm={8}>
          <Card className="acm-stats-card">
            <Statistic
              title="Predictions Today"
              value={totalPredictions}
              prefix={<ExperimentOutlined />}
            />
          </Card>
        </Col>
        <Col xs={24} sm={8}>
          <Card className="acm-stats-card">
            <Statistic
              title="Avg Accuracy"
              value={activeModels.reduce((sum, m) => sum + m.accuracy, 0) / (activeModels.length || 1) * 100}
              precision={1}
              suffix="%"
              prefix={<Badge status="success" />}
            />
          </Card>
        </Col>
      </Row>

      <Row gutter={[16, 16]}>
        {models.map((model) => (
          <Col xs={24} lg={12} key={model.id}>
            <Card
              title={
                <Space>
                  <RobotOutlined />
                  <Text strong>{model.model_name}</Text>
                  <Tag>{model.version}</Tag>
                  <Tag color={statusColor[model.status]}>{model.status.toUpperCase()}</Tag>
                </Space>
              }
              extra={
                model.status !== 'retired' && (
                  <Space>
                    <Button
                      size="small"
                      icon={<ReloadOutlined />}
                      onClick={() => handleRetrain(model.id)}
                    >
                      {t('ml.triggerRetrain')}
                    </Button>
                    <AIDDTierBadge tier={2} compact />
                  </Space>
                )
              }
              className="vg-model-card"
            >
              <Row gutter={16}>
                <Col span={8}>
                  <div style={{ textAlign: 'center' }}>
                    <Text type="secondary">{t('ml.accuracy')}</Text>
                    <Progress
                      type="circle"
                      percent={Number((model.accuracy * 100).toFixed(1))}
                      size={80}
                      strokeColor={model.accuracy >= 0.9 ? '#28A745' : model.accuracy >= 0.8 ? '#FFC107' : '#DC3545'}
                    />
                  </div>
                </Col>
                <Col span={8}>
                  <div style={{ textAlign: 'center' }}>
                    <Text type="secondary">{t('ml.auc')}</Text>
                    <Progress
                      type="circle"
                      percent={Number((model.auc * 100).toFixed(1))}
                      size={80}
                      strokeColor="#1B4F72"
                    />
                  </div>
                </Col>
                <Col span={8}>
                  <div style={{ textAlign: 'center' }}>
                    <Text type="secondary">{t('ml.f1Score')}</Text>
                    <Progress
                      type="circle"
                      percent={Number((model.f1_score * 100).toFixed(1))}
                      size={80}
                      strokeColor="#17A2B8"
                    />
                  </div>
                </Col>
              </Row>

              <div style={{ marginTop: 16 }}>
                <div className="vg-model-metric">
                  <Text type="secondary">{t('ml.featureCount')}</Text>
                  <Text strong>{model.features_count}</Text>
                </div>
                <div className="vg-model-metric">
                  <Text type="secondary">{t('ml.lastTrained')}</Text>
                  <Text strong>{formatDate(model.last_trained, 'short')}</Text>
                </div>
                {model.status !== 'retired' && (
                  <>
                    <div className="vg-model-metric">
                      <Text type="secondary">Predictions Today</Text>
                      <Text strong>{formatNumber(model.predictions_today)}</Text>
                    </div>
                    <div className="vg-model-metric">
                      <Text type="secondary">Avg Latency</Text>
                      <Text strong>{model.avg_latency_ms}ms</Text>
                    </div>
                  </>
                )}
                {model.ab_test_status && (
                  <div className="vg-model-metric">
                    <Text type="secondary">{t('ml.abTestStatus')}</Text>
                    <Tag color="blue">{model.ab_test_status}</Tag>
                  </div>
                )}
              </div>
            </Card>
          </Col>
        ))}
      </Row>
    </div>
  );
};

export default MLDashboardPage;
