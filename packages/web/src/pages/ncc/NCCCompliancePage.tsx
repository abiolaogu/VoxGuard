import React, { useState } from 'react';
import { Card, Table, Tag, Button, Typography, Space, message } from 'antd';
import { SendOutlined, ExclamationCircleOutlined } from '@ant-design/icons';
import { AIDDTierBadge } from '../../components/common';

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
  const [reports] = useState<ComplianceReport[]>(mockReports);
  const [disputes] = useState<Dispute[]>(mockDisputes);

  const handleSubmit = (id: string) => {
    message.success(`Report ${id} submitted to NCC`);
  };

  const handleEscalate = (id: string) => {
    message.success(`Dispute ${id} escalated`);
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
    { title: 'Report Type', dataIndex: 'report_type', key: 'report_type' },
    { title: 'Period', dataIndex: 'period', key: 'period' },
    {
      title: 'Status',
      dataIndex: 'status',
      key: 'status',
      render: (status: string) => <Tag color={statusColor[status]}>{status.toUpperCase()}</Tag>,
    },
    { title: 'Incidents', dataIndex: 'incidents_count', key: 'incidents_count' },
    { title: 'Due Date', dataIndex: 'due_date', key: 'due_date' },
    {
      title: 'Actions',
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
              Submit to NCC
            </Button>
            <AIDDTierBadge tier={2} compact />
          </Space>
        ) : null,
    },
  ];

  const disputeColumns = [
    { title: 'Reference', dataIndex: 'reference', key: 'reference' },
    { title: 'Operator', dataIndex: 'operator', key: 'operator' },
    { title: 'Type', dataIndex: 'type', key: 'type' },
    {
      title: 'Status',
      dataIndex: 'status',
      key: 'status',
      render: (status: string) => <Tag color={statusColor[status]}>{status.toUpperCase()}</Tag>,
    },
    {
      title: 'Amount',
      dataIndex: 'amount',
      key: 'amount',
      render: (amount: number) => `$${amount.toLocaleString()}`,
    },
    {
      title: 'Actions',
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
              Escalate
            </Button>
            <AIDDTierBadge tier={2} compact />
          </Space>
        ) : null,
    },
  ];

  return (
    <div style={{ padding: 24 }}>
      <Title level={3}>NCC Compliance</Title>
      <Text type="secondary">Nigerian Communications Commission reporting and dispute management</Text>
      <Space direction="vertical" style={{ width: '100%', marginTop: 24 }} size="large">
        <Card title={`Compliance Reports (${reports.length})`}>
          <Table columns={reportColumns} dataSource={reports} rowKey="id" size="small" />
        </Card>
        <Card title={`Disputes (${disputes.length})`}>
          <Table columns={disputeColumns} dataSource={disputes} rowKey="id" size="small" />
        </Card>
      </Space>
    </div>
  );
};

export default NCCCompliancePage;
