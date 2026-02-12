import React, { useState } from 'react';
import { Card, Table, Typography, Input, Select, DatePicker, Button, Space, Tag } from 'antd';
import { SearchOutlined, DownloadOutlined } from '@ant-design/icons';
import { useTranslation } from 'react-i18next';
import { useLocale } from '../../hooks/useLocale';
import '../../styles/pages.css';

const { Title, Text } = Typography;
const { RangePicker } = DatePicker;

interface CDRRecord {
  id: string;
  a_number: string;
  b_number: string;
  start_time: string;
  end_time: string;
  duration_sec: number;
  call_type: string;
  direction: string;
  gateway: string;
  country: string;
  status: string;
}

const mockCDRs: CDRRecord[] = [
  { id: 'CDR-001', a_number: '+2348012345678', b_number: '+2347098765432', start_time: '2025-04-20T10:15:00Z', end_time: '2025-04-20T10:18:30Z', duration_sec: 210, call_type: 'voice', direction: 'inbound', gateway: 'GW-MTN-01', country: 'Nigeria', status: 'completed' },
  { id: 'CDR-002', a_number: '+23280555123', b_number: '+2348033344556', start_time: '2025-04-20T10:20:00Z', end_time: '2025-04-20T10:20:03Z', duration_sec: 3, call_type: 'voice', direction: 'inbound', gateway: 'GW-INTL-02', country: 'Sierra Leone', status: 'completed' },
  { id: 'CDR-003', a_number: '+447911123456', b_number: '+2349055566778', start_time: '2025-04-20T10:25:00Z', end_time: '2025-04-20T10:35:00Z', duration_sec: 600, call_type: 'voice', direction: 'inbound', gateway: 'GW-INTL-01', country: 'United Kingdom', status: 'completed' },
  { id: 'CDR-004', a_number: '+2348012345678', b_number: '+13125551234', start_time: '2025-04-20T10:30:00Z', end_time: '2025-04-20T10:45:00Z', duration_sec: 900, call_type: 'voice', direction: 'outbound', gateway: 'GW-INTL-01', country: 'United States', status: 'completed' },
  { id: 'CDR-005', a_number: '+86138001234', b_number: '+2347044455667', start_time: '2025-04-20T10:32:00Z', end_time: '2025-04-20T10:32:02Z', duration_sec: 2, call_type: 'voice', direction: 'inbound', gateway: 'GW-INTL-02', country: 'China', status: 'completed' },
  { id: 'CDR-006', a_number: '+2348022233445', b_number: '+2349066677889', start_time: '2025-04-20T10:40:00Z', end_time: '2025-04-20T10:55:00Z', duration_sec: 900, call_type: 'voice', direction: 'local', gateway: 'GW-MTN-01', country: 'Nigeria', status: 'completed' },
  { id: 'CDR-007', a_number: '+254711234567', b_number: '+2348077788990', start_time: '2025-04-20T10:45:00Z', end_time: '2025-04-20T10:45:00Z', duration_sec: 0, call_type: 'voice', direction: 'inbound', gateway: 'GW-INTL-02', country: 'Kenya', status: 'failed' },
  { id: 'CDR-008', a_number: '+2348012345678', b_number: '+234900000111', start_time: '2025-04-20T11:00:00Z', end_time: '2025-04-20T11:02:30Z', duration_sec: 150, call_type: 'voice', direction: 'outbound', gateway: 'GW-GLO-01', country: 'Nigeria', status: 'completed' },
];

export const CDRBrowserPage: React.FC = () => {
  const { t } = useTranslation();
  const { formatDate } = useLocale();
  const [aNumber, setANumber] = useState('');
  const [bNumber, setBNumber] = useState('');
  const [countryFilter, setCountryFilter] = useState<string | undefined>();
  const [gatewayFilter, setGatewayFilter] = useState<string | undefined>();
  const [data] = useState<CDRRecord[]>(mockCDRs);

  const filtered = data.filter((r) => {
    if (aNumber && !r.a_number.includes(aNumber)) return false;
    if (bNumber && !r.b_number.includes(bNumber)) return false;
    if (countryFilter && r.country !== countryFilter) return false;
    if (gatewayFilter && r.gateway !== gatewayFilter) return false;
    return true;
  });

  const formatDuration = (sec: number) => {
    if (sec === 0) return '0s';
    const m = Math.floor(sec / 60);
    const s = sec % 60;
    return m > 0 ? `${m}m ${s}s` : `${s}s`;
  };

  const columns = [
    { title: t('common.id'), dataIndex: 'id', key: 'id', width: 100 },
    { title: t('cdr.aNumber'), dataIndex: 'a_number', key: 'a_number' },
    { title: t('cdr.bNumber'), dataIndex: 'b_number', key: 'b_number' },
    {
      title: t('cdr.startTime'),
      dataIndex: 'start_time',
      key: 'start_time',
      render: (d: string) => formatDate(d, 'long'),
    },
    {
      title: t('cdr.duration'),
      dataIndex: 'duration_sec',
      key: 'duration_sec',
      render: (sec: number) => formatDuration(sec),
      sorter: (a: CDRRecord, b: CDRRecord) => a.duration_sec - b.duration_sec,
    },
    {
      title: t('cdr.direction'),
      dataIndex: 'direction',
      key: 'direction',
      render: (dir: string) => (
        <Tag color={dir === 'inbound' ? 'blue' : dir === 'outbound' ? 'green' : 'default'}>
          {dir.toUpperCase()}
        </Tag>
      ),
    },
    { title: t('cdr.gateway'), dataIndex: 'gateway', key: 'gateway' },
    { title: t('cdr.country'), dataIndex: 'country', key: 'country' },
    {
      title: t('common.status'),
      dataIndex: 'status',
      key: 'status',
      render: (s: string) => (
        <Tag color={s === 'completed' ? 'green' : s === 'failed' ? 'red' : 'default'}>
          {s.toUpperCase()}
        </Tag>
      ),
    },
  ];

  const countries = [...new Set(data.map((r) => r.country))];
  const gateways = [...new Set(data.map((r) => r.gateway))];

  const handleExport = () => {
    const csv = [
      ['ID', 'A-Number', 'B-Number', 'Start Time', 'Duration (s)', 'Direction', 'Gateway', 'Country', 'Status'].join(','),
      ...filtered.map((r) =>
        [r.id, r.a_number, r.b_number, r.start_time, r.duration_sec, r.direction, r.gateway, r.country, r.status].join(','),
      ),
    ].join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'cdr_export.csv';
    a.click();
    URL.revokeObjectURL(url);
  };

  return (
    <div className="vg-page-wrapper acm-fade-in">
      <Title level={3} className="vg-page-title">{t('cdr.title')}</Title>
      <Text type="secondary">{t('cdr.subtitle')}</Text>

      <div className="vg-section">
        <Card>
          <div className="vg-filter-bar">
            <Input
              placeholder={t('cdr.aNumber')}
              prefix={<SearchOutlined />}
              value={aNumber}
              onChange={(e) => setANumber(e.target.value)}
              style={{ width: 200 }}
            />
            <Input
              placeholder={t('cdr.bNumber')}
              prefix={<SearchOutlined />}
              value={bNumber}
              onChange={(e) => setBNumber(e.target.value)}
              style={{ width: 200 }}
            />
            <RangePicker size="middle" />
            <Select
              placeholder={t('cdr.country')}
              allowClear
              value={countryFilter}
              onChange={setCountryFilter}
              style={{ width: 150 }}
              options={countries.map((c) => ({ value: c, label: c }))}
            />
            <Select
              placeholder={t('cdr.gateway')}
              allowClear
              value={gatewayFilter}
              onChange={setGatewayFilter}
              style={{ width: 150 }}
              options={gateways.map((g) => ({ value: g, label: g }))}
            />
            <Button icon={<DownloadOutlined />} onClick={handleExport}>
              {t('cdr.exportCsv')}
            </Button>
          </div>

          <Space style={{ marginBottom: 16 }}>
            <Text type="secondary">{t('cdr.totalRecords')}: <Text strong>{filtered.length}</Text></Text>
            <Text type="secondary">
              {t('cdr.avgDuration')}: <Text strong>{formatDuration(Math.round(filtered.reduce((sum, r) => sum + r.duration_sec, 0) / (filtered.length || 1)))}</Text>
            </Text>
          </Space>

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

export default CDRBrowserPage;
