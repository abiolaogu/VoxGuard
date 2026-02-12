import React, { useState } from 'react';
import { Card, Typography, Segmented, Row, Col } from 'antd';
import {
  ArrowUpOutlined,
  ArrowDownOutlined,
  SafetyCertificateOutlined,
  WarningOutlined,
  ClockCircleOutlined,
  DollarOutlined,
  FolderOpenOutlined,
  RobotOutlined,
  AlertOutlined,
} from '@ant-design/icons';
import { useTranslation } from 'react-i18next';
import { useLocale } from '../../hooks/useLocale';
import '../../styles/pages.css';

const { Title, Text } = Typography;

interface KPIData {
  key: string;
  labelKey: string;
  value: number;
  suffix?: string;
  prefix?: string;
  isCurrency?: boolean;
  trend: number;
  trendDirection: 'up' | 'down';
  trendIsGood: boolean;
  icon: React.ReactNode;
  format?: 'percent' | 'number' | 'currency' | 'duration';
}

const kpiData: Record<string, KPIData[]> = {
  '24h': [
    { key: 'detectionRate', labelKey: 'kpi.detectionRate', value: 97.2, suffix: '%', trend: 1.3, trendDirection: 'up', trendIsGood: true, icon: <SafetyCertificateOutlined />, format: 'percent' },
    { key: 'falsePositiveRate', labelKey: 'kpi.falsePositiveRate', value: 3.8, suffix: '%', trend: 0.5, trendDirection: 'down', trendIsGood: true, icon: <WarningOutlined />, format: 'percent' },
    { key: 'mtti', labelKey: 'kpi.mtti', value: 12, suffix: ' min', trend: 3, trendDirection: 'down', trendIsGood: true, icon: <ClockCircleOutlined />, format: 'duration' },
    { key: 'mttr', labelKey: 'kpi.mttr', value: 4.2, suffix: ' hrs', trend: 0.8, trendDirection: 'down', trendIsGood: true, icon: <ClockCircleOutlined />, format: 'duration' },
    { key: 'revenueProtected', labelKey: 'kpi.revenueProtected', value: 8500000, isCurrency: true, trend: 12, trendDirection: 'up', trendIsGood: true, icon: <DollarOutlined />, format: 'currency' },
    { key: 'activeCases', labelKey: 'kpi.activeCases', value: 7, trend: 2, trendDirection: 'up', trendIsGood: false, icon: <FolderOpenOutlined />, format: 'number' },
    { key: 'modelAccuracy', labelKey: 'kpi.modelAccuracy', value: 94.6, suffix: '%', trend: 0.3, trendDirection: 'up', trendIsGood: true, icon: <RobotOutlined />, format: 'percent' },
    { key: 'alertVolume', labelKey: 'kpi.alertVolume', value: 156, trend: 23, trendDirection: 'up', trendIsGood: false, icon: <AlertOutlined />, format: 'number' },
  ],
  '7d': [
    { key: 'detectionRate', labelKey: 'kpi.detectionRate', value: 96.8, suffix: '%', trend: 0.8, trendDirection: 'up', trendIsGood: true, icon: <SafetyCertificateOutlined />, format: 'percent' },
    { key: 'falsePositiveRate', labelKey: 'kpi.falsePositiveRate', value: 4.1, suffix: '%', trend: 0.3, trendDirection: 'down', trendIsGood: true, icon: <WarningOutlined />, format: 'percent' },
    { key: 'mtti', labelKey: 'kpi.mtti', value: 15, suffix: ' min', trend: 2, trendDirection: 'down', trendIsGood: true, icon: <ClockCircleOutlined />, format: 'duration' },
    { key: 'mttr', labelKey: 'kpi.mttr', value: 5.1, suffix: ' hrs', trend: 1.2, trendDirection: 'down', trendIsGood: true, icon: <ClockCircleOutlined />, format: 'duration' },
    { key: 'revenueProtected', labelKey: 'kpi.revenueProtected', value: 42000000, isCurrency: true, trend: 8, trendDirection: 'up', trendIsGood: true, icon: <DollarOutlined />, format: 'currency' },
    { key: 'activeCases', labelKey: 'kpi.activeCases', value: 12, trend: 3, trendDirection: 'down', trendIsGood: true, icon: <FolderOpenOutlined />, format: 'number' },
    { key: 'modelAccuracy', labelKey: 'kpi.modelAccuracy', value: 94.3, suffix: '%', trend: 0.5, trendDirection: 'up', trendIsGood: true, icon: <RobotOutlined />, format: 'percent' },
    { key: 'alertVolume', labelKey: 'kpi.alertVolume', value: 892, trend: 15, trendDirection: 'down', trendIsGood: true, icon: <AlertOutlined />, format: 'number' },
  ],
  '30d': [
    { key: 'detectionRate', labelKey: 'kpi.detectionRate', value: 95.5, suffix: '%', trend: 2.1, trendDirection: 'up', trendIsGood: true, icon: <SafetyCertificateOutlined />, format: 'percent' },
    { key: 'falsePositiveRate', labelKey: 'kpi.falsePositiveRate', value: 4.5, suffix: '%', trend: 1.2, trendDirection: 'down', trendIsGood: true, icon: <WarningOutlined />, format: 'percent' },
    { key: 'mtti', labelKey: 'kpi.mtti', value: 18, suffix: ' min', trend: 5, trendDirection: 'down', trendIsGood: true, icon: <ClockCircleOutlined />, format: 'duration' },
    { key: 'mttr', labelKey: 'kpi.mttr', value: 6.3, suffix: ' hrs', trend: 2.1, trendDirection: 'down', trendIsGood: true, icon: <ClockCircleOutlined />, format: 'duration' },
    { key: 'revenueProtected', labelKey: 'kpi.revenueProtected', value: 185000000, isCurrency: true, trend: 22, trendDirection: 'up', trendIsGood: true, icon: <DollarOutlined />, format: 'currency' },
    { key: 'activeCases', labelKey: 'kpi.activeCases', value: 23, trend: 5, trendDirection: 'down', trendIsGood: true, icon: <FolderOpenOutlined />, format: 'number' },
    { key: 'modelAccuracy', labelKey: 'kpi.modelAccuracy', value: 93.8, suffix: '%', trend: 1.2, trendDirection: 'up', trendIsGood: true, icon: <RobotOutlined />, format: 'percent' },
    { key: 'alertVolume', labelKey: 'kpi.alertVolume', value: 3420, trend: 8, trendDirection: 'down', trendIsGood: true, icon: <AlertOutlined />, format: 'number' },
  ],
};

export const KPIScorecardPage: React.FC = () => {
  const { t } = useTranslation();
  const { formatCurrency, formatNumber } = useLocale();
  const [period, setPeriod] = useState<string>('24h');

  const currentKPIs = kpiData[period] || kpiData['24h'];

  const displayValue = (kpi: KPIData) => {
    if (kpi.isCurrency) return formatCurrency(kpi.value);
    if (kpi.suffix) return `${formatNumber(kpi.value)}${kpi.suffix}`;
    return formatNumber(kpi.value);
  };

  return (
    <div className="vg-page-wrapper acm-fade-in">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <div>
          <Title level={3} className="vg-page-title">{t('kpi.title')}</Title>
          <Text type="secondary">{t('kpi.subtitle')}</Text>
        </div>
        <Segmented
          options={[
            { label: t('kpi.period24h'), value: '24h' },
            { label: t('kpi.period7d'), value: '7d' },
            { label: t('kpi.period30d'), value: '30d' },
          ]}
          value={period}
          onChange={(v) => setPeriod(v as string)}
        />
      </div>

      <Row gutter={[16, 16]}>
        {currentKPIs.map((kpi) => {
          const trendColor = kpi.trendIsGood ? '#28A745' : '#DC3545';
          const TrendIcon = kpi.trendDirection === 'up' ? ArrowUpOutlined : ArrowDownOutlined;

          return (
            <Col xs={24} sm={12} lg={6} key={kpi.key}>
              <Card hoverable className="acm-stats-card">
                <div style={{ textAlign: 'center' }}>
                  <div style={{ fontSize: 24, color: '#1B4F72', marginBottom: 8 }}>{kpi.icon}</div>
                  <Text type="secondary">{t(kpi.labelKey)}</Text>
                  <div style={{ fontSize: 32, fontWeight: 700, lineHeight: 1.2, marginTop: 8 }}>
                    {displayValue(kpi)}
                  </div>
                  <div style={{ marginTop: 8, color: trendColor, fontSize: 14 }}>
                    <TrendIcon /> {kpi.trend}{kpi.format === 'percent' || kpi.format === 'currency' ? '%' : ''} vs prev period
                  </div>
                </div>
              </Card>
            </Col>
          );
        })}
      </Row>
    </div>
  );
};

export default KPIScorecardPage;
