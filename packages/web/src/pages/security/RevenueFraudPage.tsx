import React, { useState, useEffect } from 'react';
import { Card, Table, Tag, Button, Tabs, Typography, Space, message } from 'antd';
import { StopOutlined } from '@ant-design/icons';
import { useTranslation } from 'react-i18next';
import { voxguardApi, type WangiriIncident, type IrsfIncident } from '../../api/voxguard';
import { AIDDTierBadge } from '../../components/common';
import { useLocale } from '../../hooks/useLocale';

const { Title, Text } = Typography;

export const RevenueFraudPage: React.FC = () => {
  const { t } = useTranslation();
  const { formatCurrency } = useLocale();
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
      message.success(t('security.blockedSuccess'));
      loadData();
    } catch {
      message.error(t('security.blockFailed'));
    }
  };

  const wangiriColumns = [
    { title: t('alerts.callingNumber'), dataIndex: 'calling_number', key: 'calling_number' },
    { title: t('cdr.country'), dataIndex: 'country', key: 'country' },
    {
      title: t('security.ringDuration'),
      dataIndex: 'ring_duration_sec',
      key: 'ring_duration_sec',
      render: (sec: number) => `${sec}s`,
    },
    { title: t('security.callbackCount'), dataIndex: 'callback_count', key: 'callback_count' },
    {
      title: t('security.revenueRisk'),
      dataIndex: 'revenue_risk',
      key: 'revenue_risk',
      render: (risk: number) => (
        <Tag color={risk >= 100 ? 'red' : risk >= 50 ? 'orange' : 'green'}>
          {formatCurrency(risk)}
        </Tag>
      ),
    },
    {
      title: t('common.status'),
      dataIndex: 'status',
      key: 'status',
      render: (status: string) => {
        const color =
          status === 'active' ? 'red' : status === 'blocked' ? 'volcano' : status === 'resolved' ? 'green' : 'default';
        return <Tag color={color}>{status.toUpperCase()}</Tag>;
      },
    },
    {
      title: t('common.actions'),
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
              {t('security.blockNumber')}
            </Button>
            <AIDDTierBadge tier={1} compact />
          </Space>
        ) : null,
    },
  ];

  const irsfColumns = [
    { title: t('cdr.bNumber'), dataIndex: 'destination', key: 'destination' },
    { title: t('cdr.country'), dataIndex: 'country', key: 'country' },
    {
      title: t('security.totalMinutes'),
      dataIndex: 'total_minutes',
      key: 'total_minutes',
      render: (mins: number) => `${mins.toFixed(1)} min`,
    },
    {
      title: t('security.totalCost'),
      dataIndex: 'total_cost',
      key: 'total_cost',
      render: (cost: number) => (
        <Tag color={cost >= 500 ? 'red' : cost >= 100 ? 'orange' : 'green'}>
          {formatCurrency(cost)}
        </Tag>
      ),
    },
    {
      title: t('security.pumpPattern'),
      dataIndex: 'pump_pattern',
      key: 'pump_pattern',
      render: (pattern: string) => <Tag color="purple">{pattern}</Tag>,
    },
    {
      title: t('common.status'),
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
      label: `${t('security.wangiri')} (${wangiri.length})`,
      children: (
        <Card title={t('security.wangiri')}>
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
      label: `${t('security.irsf')} (${irsf.length})`,
      children: (
        <Card title={t('security.irsf')}>
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
    <div className="vg-page-wrapper">
      <Title level={3}>{t('security.revenueFraudDetection')}</Title>
      <Text type="secondary">{t('security.wangiriAndIrsf')}</Text>
      <div className="vg-section">
        <Tabs items={tabItems} />
      </div>
    </div>
  );
};

export default RevenueFraudPage;
