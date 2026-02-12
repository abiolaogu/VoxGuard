import React, { useState } from 'react';
import { Card, Typography, Form, Select, DatePicker, Button, Table, Tag, Space, Radio, message, Divider } from 'antd';
import { FileTextOutlined, DownloadOutlined, ScheduleOutlined, PlusOutlined } from '@ant-design/icons';
import { useTranslation } from 'react-i18next';
import { useLocale } from '../../hooks/useLocale';
import '../../styles/pages.css';

const { Title, Text } = Typography;
const { RangePicker } = DatePicker;

interface ReportHistoryItem {
  id: string;
  report_type: string;
  date_range: string;
  format: string;
  status: 'generated' | 'pending' | 'failed';
  generated_at: string;
  size: string;
  schedule?: string;
}

const mockHistory: ReportHistoryItem[] = [
  { id: 'RPT-001', report_type: 'Daily Fraud Summary', date_range: '2025-04-20', format: 'PDF', status: 'generated', generated_at: '2025-04-20T06:00:00Z', size: '2.4 MB' },
  { id: 'RPT-002', report_type: 'Weekly Trend Report', date_range: '2025-04-14 to 2025-04-20', format: 'Excel', status: 'generated', generated_at: '2025-04-20T07:00:00Z', size: '5.1 MB' },
  { id: 'RPT-003', report_type: 'Monthly NCC Submission', date_range: '2025-03', format: 'PDF', status: 'generated', generated_at: '2025-04-05T06:00:00Z', size: '8.7 MB', schedule: 'Monthly' },
  { id: 'RPT-004', report_type: 'Daily Fraud Summary', date_range: '2025-04-19', format: 'PDF', status: 'generated', generated_at: '2025-04-19T06:00:00Z', size: '2.1 MB', schedule: 'Daily' },
  { id: 'RPT-005', report_type: 'Custom Report', date_range: '2025-04-01 to 2025-04-15', format: 'CSV', status: 'pending', generated_at: '2025-04-20T14:00:00Z', size: '—' },
];

const statusColor: Record<string, string> = {
  generated: 'green',
  pending: 'processing',
  failed: 'red',
};

export const ReportBuilderPage: React.FC = () => {
  const { t } = useTranslation();
  const { formatDate } = useLocale();
  const [form] = Form.useForm();
  const [history] = useState<ReportHistoryItem[]>(mockHistory);

  const handleGenerate = (values: Record<string, unknown>) => {
    message.success(t('reports.reportGenerated'));
    console.log('Report request:', values);
  };

  const columns = [
    { title: t('common.id'), dataIndex: 'id', key: 'id', width: 100 },
    { title: t('reports.reportType'), dataIndex: 'report_type', key: 'report_type' },
    { title: t('reports.dateRange'), dataIndex: 'date_range', key: 'date_range' },
    { title: t('reports.format'), dataIndex: 'format', key: 'format', render: (f: string) => <Tag>{f}</Tag> },
    {
      title: t('common.status'),
      dataIndex: 'status',
      key: 'status',
      render: (s: string) => <Tag color={statusColor[s]}>{t(`reports.${s}`)}</Tag>,
    },
    {
      title: t('common.date'),
      dataIndex: 'generated_at',
      key: 'generated_at',
      render: (d: string) => formatDate(d, 'short'),
    },
    {
      title: 'Size',
      dataIndex: 'size',
      key: 'size',
    },
    {
      title: t('reports.schedule'),
      dataIndex: 'schedule',
      key: 'schedule',
      render: (s: string | undefined) => s ? <Tag color="blue">{s}</Tag> : <Text type="secondary">—</Text>,
    },
    {
      title: t('common.actions'),
      key: 'actions',
      render: (_: unknown, record: ReportHistoryItem) =>
        record.status === 'generated' ? (
          <Button type="link" size="small" icon={<DownloadOutlined />}>
            {t('reports.downloadReport')}
          </Button>
        ) : null,
    },
  ];

  return (
    <div className="vg-page-wrapper acm-fade-in">
      <Title level={3} className="vg-page-title">{t('reports.title')}</Title>
      <Text type="secondary">{t('reports.subtitle')}</Text>

      <div className="vg-section">
        <Card title={<><PlusOutlined /> {t('reports.generate')}</>}>
          <Form
            form={form}
            layout="vertical"
            onFinish={handleGenerate}
            initialValues={{ report_type: 'daily_fraud', format: 'pdf', schedule: 'one_time' }}
          >
            <Space direction="vertical" style={{ width: '100%' }} size="middle">
              <div className="vg-filter-bar">
                <Form.Item label={t('reports.reportType')} name="report_type" style={{ marginBottom: 0, minWidth: 220 }}>
                  <Select
                    options={[
                      { value: 'daily_fraud', label: t('reports.dailyFraudSummary') },
                      { value: 'weekly_trend', label: t('reports.weeklyTrend') },
                      { value: 'monthly_ncc', label: t('reports.monthlyNcc') },
                      { value: 'custom', label: t('reports.custom') },
                    ]}
                  />
                </Form.Item>

                <Form.Item label={t('reports.dateRange')} name="date_range" style={{ marginBottom: 0 }}>
                  <RangePicker />
                </Form.Item>

                <Form.Item label={t('reports.format')} name="format" style={{ marginBottom: 0 }}>
                  <Radio.Group>
                    <Radio.Button value="pdf">PDF</Radio.Button>
                    <Radio.Button value="csv">CSV</Radio.Button>
                    <Radio.Button value="excel">Excel</Radio.Button>
                  </Radio.Group>
                </Form.Item>
              </div>

              <Form.Item label={t('reports.schedule')} name="schedule" style={{ marginBottom: 0 }}>
                <Radio.Group>
                  <Radio.Button value="one_time">{t('reports.oneTime')}</Radio.Button>
                  <Radio.Button value="daily">{t('reports.daily')}</Radio.Button>
                  <Radio.Button value="weekly">{t('reports.weekly')}</Radio.Button>
                  <Radio.Button value="monthly">{t('reports.monthly')}</Radio.Button>
                </Radio.Group>
              </Form.Item>

              <Button type="primary" htmlType="submit" icon={<FileTextOutlined />}>
                {t('reports.generate')}
              </Button>
            </Space>
          </Form>
        </Card>

        <Divider />

        <Card title={<><ScheduleOutlined /> {t('reports.reportHistory')}</>}>
          <Table
            columns={columns}
            dataSource={history}
            rowKey="id"
            size="small"
            pagination={{ pageSize: 10 }}
          />
        </Card>
      </div>
    </div>
  );
};

export default ReportBuilderPage;
