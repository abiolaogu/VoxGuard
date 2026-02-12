import React, { useState } from 'react';
import { Card, Form, Select, Button, Space, Typography, message } from 'antd';
import { SaveOutlined, ReloadOutlined } from '@ant-design/icons';
import { useTranslation } from 'react-i18next';
import { useLocale } from '../../hooks/useLocale';
import { supportedLanguages } from '../../i18n';

const { Paragraph, Title } = Typography;

const commonCurrencies = [
  { code: 'NGN', label: '₦ NGN - Nigerian Naira' },
  { code: 'USD', label: '$ USD - US Dollar' },
  { code: 'EUR', label: '€ EUR - Euro' },
  { code: 'GBP', label: '£ GBP - British Pound' },
  { code: 'GHS', label: '₵ GHS - Ghanaian Cedi' },
  { code: 'KES', label: 'KSh KES - Kenyan Shilling' },
  { code: 'ZAR', label: 'R ZAR - South African Rand' },
  { code: 'XOF', label: 'CFA XOF - West African CFA' },
  { code: 'XAF', label: 'FCFA XAF - Central African CFA' },
  { code: 'EGP', label: 'E£ EGP - Egyptian Pound' },
  { code: 'TZS', label: 'TSh TZS - Tanzanian Shilling' },
  { code: 'UGX', label: 'USh UGX - Ugandan Shilling' },
  { code: 'CNY', label: '¥ CNY - Chinese Yuan' },
  { code: 'SAR', label: '﷼ SAR - Saudi Riyal' },
  { code: 'AED', label: 'د.إ AED - UAE Dirham' },
  { code: 'INR', label: '₹ INR - Indian Rupee' },
  { code: 'BRL', label: 'R$ BRL - Brazilian Real' },
  { code: 'CAD', label: 'C$ CAD - Canadian Dollar' },
  { code: 'AUD', label: 'A$ AUD - Australian Dollar' },
  { code: 'JPY', label: '¥ JPY - Japanese Yen' },
];

const timezones = [
  'Africa/Lagos',
  'Africa/Accra',
  'Africa/Cairo',
  'Africa/Johannesburg',
  'Africa/Nairobi',
  'Africa/Dar_es_Salaam',
  'Africa/Casablanca',
  'Europe/London',
  'Europe/Paris',
  'Europe/Berlin',
  'America/New_York',
  'America/Chicago',
  'America/Los_Angeles',
  'America/Sao_Paulo',
  'Asia/Dubai',
  'Asia/Riyadh',
  'Asia/Shanghai',
  'Asia/Tokyo',
  'Asia/Kolkata',
  'Australia/Sydney',
  'UTC',
];

export const LanguageSettings: React.FC = () => {
  const { t } = useTranslation();
  const { language, currency, secondaryCurrency, timezone, dateFormat, setLanguage, setCurrency, setSecondaryCurrency, setTimezone, setDateFormat } = useLocale();
  const [form] = Form.useForm();
  const [saving, setSaving] = useState(false);

  const handleSave = async (values: Record<string, string>) => {
    setSaving(true);
    setLanguage(values.language);
    setCurrency(values.currency);
    setSecondaryCurrency(values.secondary_currency || undefined);
    setTimezone(values.timezone);
    setDateFormat(values.date_format as 'short' | 'medium' | 'long');
    await new Promise((resolve) => setTimeout(resolve, 500));
    message.success(t('settings.languageSaved'));
    setSaving(false);
  };

  return (
    <Card bordered={false}>
      <Paragraph type="secondary" style={{ marginBottom: 24 }}>
        {t('settings.languageRegion')}
      </Paragraph>

      <Form
        form={form}
        layout="vertical"
        onFinish={handleSave}
        initialValues={{
          language,
          currency,
          secondary_currency: secondaryCurrency || '',
          timezone,
          date_format: dateFormat,
        }}
      >
        <Title level={5}>{t('settings.primaryLanguage')}</Title>
        <Form.Item label={t('settings.primaryLanguage')} name="language">
          <Select
            showSearch
            options={supportedLanguages.map((l) => ({ value: l.code, label: l.label }))}
            style={{ width: '100%', maxWidth: 400 }}
          />
        </Form.Item>

        <Title level={5}>{t('settings.primaryCurrency')}</Title>
        <Form.Item label={t('settings.primaryCurrency')} name="currency">
          <Select
            showSearch
            filterOption={(input, option) =>
              (option?.label as string)?.toLowerCase().includes(input.toLowerCase()) ?? false
            }
            options={commonCurrencies.map((c) => ({ value: c.code, label: c.label }))}
            style={{ width: '100%', maxWidth: 400 }}
          />
        </Form.Item>

        <Form.Item
          label={t('settings.secondaryCurrency')}
          name="secondary_currency"
          extra={t('settings.secondaryCurrencyHint')}
        >
          <Select
            showSearch
            allowClear
            filterOption={(input, option) =>
              (option?.label as string)?.toLowerCase().includes(input.toLowerCase()) ?? false
            }
            options={commonCurrencies.map((c) => ({ value: c.code, label: c.label }))}
            style={{ width: '100%', maxWidth: 400 }}
          />
        </Form.Item>

        <Title level={5}>{t('settings.timezone')}</Title>
        <Form.Item label={t('settings.timezone')} name="timezone">
          <Select
            showSearch
            options={timezones.map((tz) => ({ value: tz, label: tz }))}
            style={{ width: '100%', maxWidth: 400 }}
          />
        </Form.Item>

        <Form.Item label={t('settings.dateFormat')} name="date_format">
          <Select
            options={[
              { value: 'short', label: 'Short (12/02/26)' },
              { value: 'medium', label: 'Medium (Feb 12, 2026 2:30 PM)' },
              { value: 'long', label: 'Long (February 12, 2026 at 2:30:00 PM)' },
            ]}
            style={{ width: '100%', maxWidth: 400 }}
          />
        </Form.Item>

        <Form.Item>
          <Space>
            <Button type="primary" htmlType="submit" loading={saving} icon={<SaveOutlined />}>
              {t('settings.saveLanguageSettings')}
            </Button>
            <Button onClick={() => form.resetFields()} icon={<ReloadOutlined />}>
              {t('common.reset')}
            </Button>
          </Space>
        </Form.Item>
      </Form>
    </Card>
  );
};
