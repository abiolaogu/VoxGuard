import React from 'react';
import { Select } from 'antd';
import { DollarOutlined } from '@ant-design/icons';
import { useLocale } from '../../hooks/useLocale';

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

export const CurrencySwitcher: React.FC = () => {
  const { currency, setCurrency } = useLocale();

  return (
    <Select
      value={currency}
      onChange={setCurrency}
      style={{ width: 100 }}
      size="small"
      suffixIcon={<DollarOutlined />}
      showSearch
      filterOption={(input, option) =>
        (option?.label as string)?.toLowerCase().includes(input.toLowerCase()) ?? false
      }
      options={commonCurrencies.map((c) => ({
        value: c.code,
        label: c.code,
        title: c.label,
      }))}
    />
  );
};
