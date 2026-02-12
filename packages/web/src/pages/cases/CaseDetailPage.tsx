import React, { useState } from 'react';
import { Card, Typography, Tag, Space, Button, Descriptions, Timeline, Input, List, Select, message, Divider } from 'antd';
import { ArrowLeftOutlined, ExclamationCircleOutlined, CheckCircleOutlined, PlusOutlined } from '@ant-design/icons';
import { useNavigate, useParams } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { useLocale } from '../../hooks/useLocale';
import { AIDDTierBadge } from '../../components/common';
import type { FraudCase, CaseNote } from '../../api/voxguard';
import '../../styles/pages.css';

const { Title, Text, Paragraph } = Typography;
const { TextArea } = Input;

const mockCase: FraudCase = {
  id: 'CASE-2025-001',
  title: 'CLI Spoofing Ring — MTN Routes',
  description: 'Organized CLI masking operation targeting MTN interconnect routes. Multiple A-numbers detected spoofing legitimate Nigerian CLI prefixes to bypass call masking detection.',
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
    { id: 'n1', author: 'Adebayo Okonkwo', content: 'Initial investigation started. 3 linked alerts confirmed. Pattern matches known CLI spoofing ring.', created_at: '2025-04-18T10:00:00Z' },
    { id: 'n2', author: 'Fatima Hassan', content: 'CDR analysis shows pattern from Sierra Leone prefix range. 47 unique A-numbers identified.', created_at: '2025-04-19T11:00:00Z' },
    { id: 'n3', author: 'System', content: 'ML model flagged 12 additional related calls with composite score > 85.', created_at: '2025-04-19T15:30:00Z' },
    { id: 'n4', author: 'Adebayo Okonkwo', content: 'Coordinating with MTN NOC for route-level blocking. Awaiting confirmation.', created_at: '2025-04-20T14:30:00Z' },
  ],
};

const severityColor: Record<string, string> = {
  critical: 'red', high: 'orange', medium: 'gold', low: 'blue',
};

const statusColor: Record<string, string> = {
  open: 'blue', investigating: 'processing', escalated: 'orange', resolved: 'green', closed: 'default',
};

export const CaseDetailPage: React.FC = () => {
  const { t } = useTranslation();
  const { formatCurrency, formatDate } = useLocale();
  const navigate = useNavigate();
  const { id } = useParams<{ id: string }>();
  const [caseData] = useState<FraudCase>(mockCase);
  const [newNote, setNewNote] = useState('');
  const [notes, setNotes] = useState<CaseNote[]>(mockCase.notes);
  const [status, setStatus] = useState(mockCase.status);

  const handleAddNote = () => {
    if (!newNote.trim()) return;
    const note: CaseNote = {
      id: `n${notes.length + 1}`,
      author: 'Current User',
      content: newNote,
      created_at: new Date().toISOString(),
    };
    setNotes([...notes, note]);
    setNewNote('');
    message.success(t('cases.noteAdded'));
  };

  const handleStatusChange = (newStatus: string) => {
    setStatus(newStatus as FraudCase['status']);
    message.success(t('cases.caseUpdated'));
  };

  return (
    <div className="vg-page-wrapper acm-fade-in">
      <Space style={{ marginBottom: 16 }}>
        <Button icon={<ArrowLeftOutlined />} onClick={() => navigate('/cases')}>
          {t('common.back')}
        </Button>
      </Space>

      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 24 }}>
        <div>
          <Title level={3} style={{ marginBottom: 4 }}>{id || caseData.id}: {caseData.title}</Title>
          <Space>
            <Tag color={severityColor[caseData.severity]}>{caseData.severity.toUpperCase()}</Tag>
            <Tag color={statusColor[status]}>{status.toUpperCase()}</Tag>
            <Tag color="purple">{caseData.fraud_type}</Tag>
            <AIDDTierBadge tier={1} compact />
          </Space>
        </div>
        <Space>
          <Select
            value={status}
            onChange={handleStatusChange}
            style={{ width: 160 }}
            options={[
              { value: 'open', label: t('cases.open') },
              { value: 'investigating', label: t('cases.investigating') },
              { value: 'escalated', label: t('cases.escalated') },
              { value: 'resolved', label: t('cases.resolved') },
              { value: 'closed', label: t('cases.closed') },
            ]}
          />
          {status !== 'escalated' && status !== 'resolved' && status !== 'closed' && (
            <Button danger icon={<ExclamationCircleOutlined />} onClick={() => handleStatusChange('escalated')}>
              {t('cases.escalate')}
            </Button>
          )}
          {status !== 'resolved' && status !== 'closed' && (
            <Button type="primary" icon={<CheckCircleOutlined />} onClick={() => handleStatusChange('resolved')}>
              {t('cases.resolve')}
            </Button>
          )}
        </Space>
      </div>

      <Space direction="vertical" style={{ width: '100%' }} size="large">
        <Card title={t('common.description')}>
          <Descriptions column={{ xs: 1, sm: 2, lg: 3 }} bordered size="small">
            <Descriptions.Item label={t('cases.caseId')}>{caseData.id}</Descriptions.Item>
            <Descriptions.Item label={t('cases.assignee')}>{caseData.assignee}</Descriptions.Item>
            <Descriptions.Item label={t('cases.fraudType')}>{caseData.fraud_type}</Descriptions.Item>
            <Descriptions.Item label={t('cases.estimatedLoss')}>
              <Text type="danger" strong>{formatCurrency(caseData.estimated_loss, caseData.currency)}</Text>
            </Descriptions.Item>
            <Descriptions.Item label={t('common.date')}>{formatDate(caseData.created_at)}</Descriptions.Item>
            <Descriptions.Item label={t('cases.linkedAlerts')}>
              {caseData.linked_alert_ids.map((aid) => (
                <Tag key={aid} color="blue">{aid}</Tag>
              ))}
            </Descriptions.Item>
          </Descriptions>
          <Paragraph style={{ marginTop: 16 }}>{caseData.description}</Paragraph>
          {caseData.resolution && (
            <>
              <Divider />
              <Text strong>{t('cases.resolution')}: </Text>
              <Paragraph>{caseData.resolution}</Paragraph>
            </>
          )}
        </Card>

        <Card title={t('cases.timeline')}>
          <Timeline
            items={notes.map((note) => ({
              color: note.author === 'System' ? 'blue' : 'green',
              children: (
                <div>
                  <Text strong>{note.author}</Text>
                  <Text type="secondary" style={{ marginLeft: 8, fontSize: 12 }}>
                    {formatDate(note.created_at)}
                  </Text>
                  <Paragraph style={{ marginTop: 4, marginBottom: 0 }}>{note.content}</Paragraph>
                </div>
              ),
            }))}
          />
        </Card>

        <Card title={t('cases.addNote')}>
          <TextArea
            rows={3}
            value={newNote}
            onChange={(e) => setNewNote(e.target.value)}
            placeholder={t('cases.addNote')}
          />
          <Button
            type="primary"
            icon={<PlusOutlined />}
            onClick={handleAddNote}
            style={{ marginTop: 12 }}
            disabled={!newNote.trim()}
          >
            {t('cases.addNote')}
          </Button>
        </Card>

        <Card title={t('cases.linkedAlerts')}>
          <List
            size="small"
            dataSource={caseData.linked_alert_ids}
            renderItem={(alertId) => (
              <List.Item>
                <Tag color="blue">{alertId}</Tag>
                <Button type="link" size="small" onClick={() => navigate(`/alerts/show/${alertId}`)}>
                  {t('common.view')}
                </Button>
              </List.Item>
            )}
          />
        </Card>
      </Space>
    </div>
  );
};

export default CaseDetailPage;
