import React, { useState } from 'react';
import { Card, Table, Tag, Button, Typography, Select, Input, Modal, Form, message } from 'antd';
import { PlusOutlined, SearchOutlined, EyeOutlined } from '@ant-design/icons';
import { useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { useLocale } from '../../hooks/useLocale';
import { AIDDTierBadge } from '../../components/common';
import type { FraudCase } from '../../api/voxguard';
import '../../styles/pages.css';

const { Title, Text } = Typography;

const mockCases: FraudCase[] = [
  {
    id: 'CASE-2025-001',
    title: 'CLI Spoofing Ring — MTN Routes',
    description: 'Organized CLI masking operation targeting MTN interconnect routes',
    status: 'investigating',
    severity: 'critical',
    assignee: 'Adebayo Okonkwo',
    fraud_type: 'CLI Spoofing',
    linked_alert_ids: ['ALT-001', 'ALT-002', 'ALT-003'],
    created_at: '2025-04-18T09:00:00Z',
    updated_at: '2025-04-20T14:30:00Z',
    estimated_loss: 1250000,
    currency: 'NGN',
    notes: [
      { id: 'n1', author: 'Adebayo Okonkwo', content: 'Initial investigation started. 3 linked alerts confirmed.', created_at: '2025-04-18T10:00:00Z' },
      { id: 'n2', author: 'Fatima Hassan', content: 'CDR analysis shows pattern from Sierra Leone prefix range.', created_at: '2025-04-19T11:00:00Z' },
    ],
  },
  {
    id: 'CASE-2025-002',
    title: 'Wangiri Callback Fraud — Premium Numbers',
    description: 'High-volume wangiri attacks targeting premium rate numbers',
    status: 'escalated',
    severity: 'high',
    assignee: 'Fatima Hassan',
    fraud_type: 'Wangiri',
    linked_alert_ids: ['ALT-010', 'ALT-011'],
    created_at: '2025-04-15T08:00:00Z',
    updated_at: '2025-04-19T16:00:00Z',
    estimated_loss: 875000,
    currency: 'NGN',
    notes: [
      { id: 'n3', author: 'Fatima Hassan', content: 'Escalated to NCC for cross-operator investigation.', created_at: '2025-04-19T16:00:00Z' },
    ],
  },
  {
    id: 'CASE-2025-003',
    title: 'IRSF Pump Pattern — Eastern Europe',
    description: 'International Revenue Share Fraud via Eastern European destinations',
    status: 'open',
    severity: 'high',
    assignee: 'Chukwu Emeka',
    fraud_type: 'IRSF',
    linked_alert_ids: ['ALT-015'],
    created_at: '2025-04-20T06:00:00Z',
    updated_at: '2025-04-20T06:00:00Z',
    estimated_loss: 450000,
    currency: 'NGN',
    notes: [],
  },
  {
    id: 'CASE-2025-004',
    title: 'Interconnect Bypass via SIM Box',
    description: 'SIM box detected routing international calls as local',
    status: 'resolved',
    severity: 'medium',
    assignee: 'Adebayo Okonkwo',
    fraud_type: 'SIM Box',
    linked_alert_ids: ['ALT-005', 'ALT-006'],
    created_at: '2025-04-10T10:00:00Z',
    updated_at: '2025-04-17T12:00:00Z',
    resolution: 'SIM box location identified and reported to operator. Route blocked.',
    estimated_loss: 320000,
    currency: 'NGN',
    notes: [],
  },
  {
    id: 'CASE-2025-005',
    title: 'Suspicious Short Duration Calls — Airtel Gateway',
    description: 'Abnormal pattern of very short duration calls on Airtel interconnect',
    status: 'closed',
    severity: 'low',
    assignee: 'Fatima Hassan',
    fraud_type: 'Traffic Anomaly',
    linked_alert_ids: ['ALT-020'],
    created_at: '2025-04-05T14:00:00Z',
    updated_at: '2025-04-12T09:00:00Z',
    resolution: 'Determined to be legitimate autodialer for survey service.',
    estimated_loss: 0,
    currency: 'NGN',
    notes: [],
  },
];

const severityColor: Record<string, string> = {
  critical: 'red',
  high: 'orange',
  medium: 'gold',
  low: 'blue',
};

const statusColor: Record<string, string> = {
  open: 'blue',
  investigating: 'processing',
  escalated: 'orange',
  resolved: 'green',
  closed: 'default',
};

export const CaseListPage: React.FC = () => {
  const { t } = useTranslation();
  const { formatCurrency, formatDate } = useLocale();
  const navigate = useNavigate();
  const [cases] = useState<FraudCase[]>(mockCases);
  const [statusFilter, setStatusFilter] = useState<string | undefined>(undefined);
  const [severityFilter, setSeverityFilter] = useState<string | undefined>(undefined);
  const [searchText, setSearchText] = useState('');
  const [createModalOpen, setCreateModalOpen] = useState(false);
  const [form] = Form.useForm();

  const filteredCases = cases.filter((c) => {
    if (statusFilter && c.status !== statusFilter) return false;
    if (severityFilter && c.severity !== severityFilter) return false;
    if (searchText && !c.title.toLowerCase().includes(searchText.toLowerCase()) && !c.id.toLowerCase().includes(searchText.toLowerCase())) return false;
    return true;
  });

  const handleCreate = (values: Record<string, string>) => {
    message.success(t('cases.caseCreated'));
    setCreateModalOpen(false);
    form.resetFields();
    console.log('New case:', values);
  };

  const columns = [
    {
      title: t('cases.caseId'),
      dataIndex: 'id',
      key: 'id',
      render: (id: string) => <Text strong>{id}</Text>,
    },
    {
      title: t('common.name'),
      dataIndex: 'title',
      key: 'title',
      ellipsis: true,
    },
    {
      title: t('cases.severity'),
      dataIndex: 'severity',
      key: 'severity',
      render: (severity: string) => (
        <Tag color={severityColor[severity]}>{severity.toUpperCase()}</Tag>
      ),
    },
    {
      title: t('common.status'),
      dataIndex: 'status',
      key: 'status',
      render: (status: string) => (
        <Tag color={statusColor[status]}>{status.toUpperCase()}</Tag>
      ),
    },
    {
      title: t('cases.assignee'),
      dataIndex: 'assignee',
      key: 'assignee',
    },
    {
      title: t('cases.fraudType'),
      dataIndex: 'fraud_type',
      key: 'fraud_type',
      render: (type: string) => <Tag color="purple">{type}</Tag>,
    },
    {
      title: t('cases.estimatedLoss'),
      dataIndex: 'estimated_loss',
      key: 'estimated_loss',
      render: (loss: number, record: FraudCase) => formatCurrency(loss, record.currency),
    },
    {
      title: t('common.date'),
      dataIndex: 'created_at',
      key: 'created_at',
      render: (date: string) => formatDate(date, 'short'),
    },
    {
      title: t('common.actions'),
      key: 'actions',
      render: (_: unknown, record: FraudCase) => (
        <div className="vg-table-actions">
          <Button
            type="link"
            size="small"
            icon={<EyeOutlined />}
            onClick={() => navigate(`/cases/${record.id}`)}
          >
            {t('common.view')}
          </Button>
          <AIDDTierBadge tier={1} compact />
        </div>
      ),
    },
  ];

  return (
    <div className="vg-page-wrapper acm-fade-in">
      <Title level={3} className="vg-page-title">{t('cases.title')}</Title>
      <Text type="secondary">{t('cases.subtitle')}</Text>

      <div className="vg-section">
        <div className="vg-filter-bar">
          <Input
            placeholder={t('common.search')}
            prefix={<SearchOutlined />}
            value={searchText}
            onChange={(e) => setSearchText(e.target.value)}
            style={{ width: 250 }}
          />
          <Select
            placeholder={t('common.status')}
            allowClear
            value={statusFilter}
            onChange={setStatusFilter}
            style={{ width: 150 }}
            options={[
              { value: 'open', label: t('cases.open') },
              { value: 'investigating', label: t('cases.investigating') },
              { value: 'escalated', label: t('cases.escalated') },
              { value: 'resolved', label: t('cases.resolved') },
              { value: 'closed', label: t('cases.closed') },
            ]}
          />
          <Select
            placeholder={t('cases.severity')}
            allowClear
            value={severityFilter}
            onChange={setSeverityFilter}
            style={{ width: 150 }}
            options={[
              { value: 'critical', label: t('alerts.critical') },
              { value: 'high', label: t('alerts.high') },
              { value: 'medium', label: t('alerts.medium') },
              { value: 'low', label: t('alerts.low') },
            ]}
          />
          <Button type="primary" icon={<PlusOutlined />} onClick={() => setCreateModalOpen(true)}>
            {t('cases.createCase')}
          </Button>
        </div>

        <Card>
          <Table
            columns={columns}
            dataSource={filteredCases}
            rowKey="id"
            size="small"
            pagination={{ pageSize: 10 }}
          />
        </Card>
      </div>

      <Modal
        title={t('cases.createCase')}
        open={createModalOpen}
        onCancel={() => setCreateModalOpen(false)}
        onOk={() => form.submit()}
      >
        <Form form={form} layout="vertical" onFinish={handleCreate}>
          <Form.Item label={t('common.name')} name="title" rules={[{ required: true }]}>
            <Input />
          </Form.Item>
          <Form.Item label={t('common.description')} name="description" rules={[{ required: true }]}>
            <Input.TextArea rows={3} />
          </Form.Item>
          <Form.Item label={t('cases.severity')} name="severity" rules={[{ required: true }]}>
            <Select options={[
              { value: 'critical', label: t('alerts.critical') },
              { value: 'high', label: t('alerts.high') },
              { value: 'medium', label: t('alerts.medium') },
              { value: 'low', label: t('alerts.low') },
            ]} />
          </Form.Item>
          <Form.Item label={t('cases.fraudType')} name="fraud_type" rules={[{ required: true }]}>
            <Select options={[
              { value: 'CLI Spoofing', label: 'CLI Spoofing' },
              { value: 'Wangiri', label: 'Wangiri' },
              { value: 'IRSF', label: 'IRSF' },
              { value: 'SIM Box', label: 'SIM Box' },
              { value: 'Traffic Anomaly', label: 'Traffic Anomaly' },
            ]} />
          </Form.Item>
          <Form.Item label={t('cases.assignee')} name="assignee">
            <Input />
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
};

export default CaseListPage;
