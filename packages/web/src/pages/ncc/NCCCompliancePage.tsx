import React, { useState } from 'react';
import { Card, Table, Tag, Button, Typography, Space, message } from 'antd';
import { SendOutlined, ExclamationCircleOutlined } from '@ant-design/icons';
import { useTranslation } from 'react-i18next';
import { AIDDTierBadge } from '../../components/common';
import { useLocale } from '../../hooks/useLocale';

const { Title, Text } = Typography;

interface ComplianceReport {
  id: string;
  report_type: string;
  period: string;
  status: string;
  submitted_at: string | null;
  due_date: string;
  incidents_count: number;
}

interface Dispute {
  id: string;
  reference: string;
  operator: string;
  type: string;
  status: string;
  amount: number;
  created_at: string;
}

const mockReports: ComplianceReport[] = [
  { id: '1', report_type: 'Monthly Fraud Summary', period: '2025-04', status: 'draft', submitted_at: null, due_date: '2025-05-15', incidents_count: 23 },
  { id: '2', report_type: 'Quarterly CLI Audit', period: '2025-Q1', status: 'submitted', submitted_at: '2025-04-10', due_date: '2025-04-15', incidents_count: 67 },
  { id: '3', report_type: 'Monthly Fraud Summary', period: '2025-03', status: 'accepted', submitted_at: '2025-04-05', due_date: '2025-04-15', incidents_count: 19 },
];

const mockDisputes: Dispute[] = [
  { id: '1', reference: 'NCC-D-2025-0042', operator: 'MTN Nigeria', type: 'CLI Spoofing', status: 'open', amount: 12500, created_at: '2025-04-20' },
  { id: '2', reference: 'NCC-D-2025-0039', operator: 'Airtel Nigeria', type: 'Revenue Sharing Fraud', status: 'investigating', amount: 8300, created_at: '2025-04-15' },
  { id: '3', reference: 'NCC-D-2025-0031', operator: 'Glo Mobile', type: 'Interconnect Bypass', status: 'resolved', amount: 5600, created_at: '2025-03-28' },
];

export const NCCCompliancePage: React.FC = () => {
  const { t } = useTranslation();
  const { formatCurrency } = useLocale();
  const [reports] = useState<ComplianceReport[]>(mockReports);
  const [disputes] = useState<Dispute[]>(mockDisputes);

  const handleSubmit = (_id: string) => {
    message.success(t('ncc.submitted'));
  };

  const handleEscalate = (_id: string) => {
    message.success(t('ncc.escalated'));
  };

  const statusColor: Record<string, string> = {
    draft: 'default',
    submitted: 'blue',
    accepted: 'green',
    rejected: 'red',
    open: 'orange',
    investigating: 'blue',
    resolved: 'green',
  };

  const reportColumns = [
    { title: t('ncc.reportType'), dataIndex: 'report_type', key: 'report_type' },
    { title: t('ncc.period'), dataIndex: 'period', key: 'period' },
    {
      title: t('common.status'),
      dataIndex: 'status',
      key: 'status',
      render: (status: string) => <Tag color={statusColor[status]}>{status.toUpperCase()}</Tag>,
    },
    { title: t('ncc.incidentsCount'), dataIndex: 'incidents_count', key: 'incidents_count' },
    { title: t('ncc.dueDate'), dataIndex: 'due_date', key: 'due_date' },
    {
      title: t('common.actions'),
      key: 'actions',
      render: (_: unknown, record: ComplianceReport) =>
        record.status === 'draft' ? (
          <Space>
            <Button
              type="primary"
              size="small"
              icon={<SendOutlined />}
              onClick={() => handleSubmit(record.id)}
            >
              {t('ncc.submitToNcc')}
            </Button>
            <AIDDTierBadge tier={2} compact />
          </Space>
        ) : null,
    },
  ];

  const disputeColumns = [
    { title: t('ncc.reference'), dataIndex: 'reference', key: 'reference' },
    { title: t('ncc.operator'), dataIndex: 'operator', key: 'operator' },
    { title: t('common.type'), dataIndex: 'type', key: 'type' },
    {
      title: t('common.status'),
      dataIndex: 'status',
      key: 'status',
      render: (status: string) => <Tag color={statusColor[status]}>{status.toUpperCase()}</Tag>,
    },
    {
      title: t('ncc.amount'),
      dataIndex: 'amount',
      key: 'amount',
      render: (amount: number) => formatCurrency(amount),
    },
    {
      title: t('common.actions'),
      key: 'actions',
      render: (_: unknown, record: Dispute) =>
        record.status !== 'resolved' ? (
          <Space>
            <Button
              type="primary"
              danger
              size="small"
              icon={<ExclamationCircleOutlined />}
              onClick={() => handleEscalate(record.id)}
            >
              {t('ncc.escalate')}
            </Button>
            <AIDDTierBadge tier={2} compact />
          </Space>
        ) : null,
    },
  ];

  return (
    <div className="vg-page-wrapper">
      <Title level={3}>{t('ncc.title')}</Title>
      <Text type="secondary">{t('ncc.subtitle')}</Text>
      <Space direction="vertical" style={{ width: '100%' }} size="large" className="vg-section">
        <Card title={`${t('ncc.complianceReports')} (${reports.length})`}>
          <Table columns={reportColumns} dataSource={reports} rowKey="id" size="small" />
        </Card>
        <Card title={`${t('ncc.disputes')} (${disputes.length})`}>
          <Table columns={disputeColumns} dataSource={disputes} rowKey="id" size="small" />
        </Card>
      </Space>
    </div>
  );
};

export default NCCCompliancePage;
