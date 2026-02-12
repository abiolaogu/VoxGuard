import React from 'react';
import { Select } from 'antd';
import { GlobalOutlined } from '@ant-design/icons';
import { useLocale } from '../../hooks/useLocale';
import { supportedLanguages } from '../../i18n';

export const LanguageSwitcher: React.FC = () => {
  const { language, setLanguage } = useLocale();

  return (
    <Select
      value={language}
      onChange={setLanguage}
      style={{ width: 130 }}
      size="small"
      suffixIcon={<GlobalOutlined />}
      options={supportedLanguages.map((lang) => ({
        value: lang.code,
        label: lang.label,
      }))}
    />
  );
};
