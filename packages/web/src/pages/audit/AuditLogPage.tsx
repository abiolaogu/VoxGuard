import React, { useState } from 'react';
import { Card, Table, Typography, Input, Select, DatePicker, Button, Tag } from 'antd';
import { SearchOutlined, DownloadOutlined } from '@ant-design/icons';
import { useTranslation } from 'react-i18next';
import { useLocale } from '../../hooks/useLocale';
import '../../styles/pages.css';

const { Title, Text } = Typography;
const { RangePicker } = DatePicker;

interface AuditEntry {
  id: string;
  timestamp: string;
  user: string;
  action: string;
  resource: string;
  details: string;
  ip_address: string;
}

const mockAuditEntries: AuditEntry[] = [
  { id: 'AUD-001', timestamp: '2025-04-20T14:30:00Z', user: 'adebayo.okonkwo', action: 'UPDATE', resource: 'case/CASE-2025-001', details: 'Changed status from open to investigating', ip_address: '10.0.1.45' },
  { id: 'AUD-002', timestamp: '2025-04-20T14:15:00Z', user: 'fatima.hassan', action: 'CREATE', resource: 'alert/ALT-025', details: 'New critical alert created: CLI spoofing detected', ip_address: '10.0.1.32' },
  { id: 'AUD-003', timestamp: '2025-04-20T13:45:00Z', user: 'system', action: 'EXECUTE', resource: 'ml/retrain', details: 'Scheduled model retraining started for fraud_detector_v3', ip_address: '10.0.0.1' },
  { id: 'AUD-004', timestamp: '2025-04-20T13:00:00Z', user: 'chukwu.emeka', action: 'DELETE', resource: 'list/BL-042', details: 'Removed expired blacklist entry for +23280555*', ip_address: '10.0.1.55' },
  { id: 'AUD-005', timestamp: '2025-04-20T12:30:00Z', user: 'adebayo.okonkwo', action: 'UPDATE', resource: 'settings/detection', details: 'Updated CPM warning threshold from 35 to 40', ip_address: '10.0.1.45' },
  { id: 'AUD-006', timestamp: '2025-04-20T11:00:00Z', user: 'fatima.hassan', action: 'EXPORT', resource: 'report/ncc-monthly', details: 'Exported NCC monthly compliance report for April 2025', ip_address: '10.0.1.32' },
  { id: 'AUD-007', timestamp: '2025-04-20T10:30:00Z', user: 'system', action: 'BLOCK', resource: 'traffic/rule-15', details: 'Auto-blocked pattern +23280* based on threat score 95', ip_address: '10.0.0.1' },
  { id: 'AUD-008', timestamp: '2025-04-20T09:15:00Z', user: 'admin', action: 'LOGIN', resource: 'auth/session', details: 'User logged in from new IP address', ip_address: '192.168.1.100' },
  { id: 'AUD-009', timestamp: '2025-04-20T08:00:00Z', user: 'system', action: 'BACKUP', resource: 'database/main', details: 'Daily database backup completed successfully', ip_address: '10.0.0.1' },
  { id: 'AUD-010', timestamp: '2025-04-19T23:00:00Z', user: 'system', action: 'ROTATE', resource: 'auth/tokens', details: 'Nightly token rotation completed. 3 expired tokens removed.', ip_address: '10.0.0.1' },
];

const actionColors: Record<string, string> = {
  CREATE: 'green',
  UPDATE: 'blue',
  DELETE: 'red',
  EXECUTE: 'purple',
  EXPORT: 'cyan',
  BLOCK: 'orange',
  LOGIN: 'default',
  BACKUP: 'geekblue',
  ROTATE: 'default',
};

export const AuditLogPage: React.FC = () => {
  const { t } = useTranslation();
  const { formatDate } = useLocale();
  const [searchText, setSearchText] = useState('');
  const [userFilter, setUserFilter] = useState<string | undefined>();
  const [actionFilter, setActionFilter] = useState<string | undefined>();
  const [entries] = useState<AuditEntry[]>(mockAuditEntries);

  const filtered = entries.filter((e) => {
    if (searchText && !e.details.toLowerCase().includes(searchText.toLowerCase()) && !e.resource.toLowerCase().includes(searchText.toLowerCase())) return false;
    if (userFilter && e.user !== userFilter) return false;
    if (actionFilter && e.action !== actionFilter) return false;
    return true;
  });

  const users = [...new Set(entries.map((e) => e.user))];
  const actions = [...new Set(entries.map((e) => e.action))];

  const columns = [
    {
      title: t('audit.timestamp'),
      dataIndex: 'timestamp',
      key: 'timestamp',
      render: (ts: string) => formatDate(ts, 'long'),
      width: 200,
    },
    { title: t('audit.user'), dataIndex: 'user', key: 'user', width: 150 },
    {
      title: t('audit.actionType'),
      dataIndex: 'action',
      key: 'action',
      width: 100,
      render: (action: string) => <Tag color={actionColors[action] || 'default'}>{action}</Tag>,
    },
    { title: t('audit.resource'), dataIndex: 'resource', key: 'resource', width: 200 },
    { title: t('audit.details'), dataIndex: 'details', key: 'details', ellipsis: true },
    { title: t('audit.ipAddress'), dataIndex: 'ip_address', key: 'ip_address', width: 130 },
  ];

  const handleExport = () => {
    const csv = [
      ['Timestamp', 'User', 'Action', 'Resource', 'Details', 'IP Address'].join(','),
      ...filtered.map((e) =>
        [e.timestamp, e.user, e.action, e.resource, `"${e.details}"`, e.ip_address].join(','),
      ),
    ].join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'audit_log_export.csv';
    a.click();
    URL.revokeObjectURL(url);
  };

  return (
    <div className="vg-page-wrapper acm-fade-in">
      <Title level={3} className="vg-page-title">{t('audit.title')}</Title>
      <Text type="secondary">{t('audit.subtitle')}</Text>

      <div className="vg-section">
        <Card>
          <div className="vg-filter-bar">
            <Input
              placeholder={t('common.search')}
              prefix={<SearchOutlined />}
              value={searchText}
              onChange={(e) => setSearchText(e.target.value)}
              style={{ width: 250 }}
            />
            <Select
              placeholder={t('audit.filterByUser')}
              allowClear
              value={userFilter}
              onChange={setUserFilter}
              style={{ width: 180 }}
              options={users.map((u) => ({ value: u, label: u }))}
            />
            <Select
              placeholder={t('audit.filterByAction')}
              allowClear
              value={actionFilter}
              onChange={setActionFilter}
              style={{ width: 150 }}
              options={actions.map((a) => ({ value: a, label: a }))}
            />
            <RangePicker />
            <Button icon={<DownloadOutlined />} onClick={handleExport}>
              {t('audit.exportLog')}
            </Button>
          </div>

          <Table
            columns={columns}
            dataSource={filtered}
            rowKey="id"
            size="small"
            pagination={{ pageSize: 20, showSizeChanger: true }}
          />
        </Card>
      </div>
    </div>
  );
};

export default AuditLogPage;
