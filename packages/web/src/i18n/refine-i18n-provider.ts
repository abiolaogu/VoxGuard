import type { I18nProvider } from '@refinedev/core';
import i18n from './index';

export const i18nProvider: I18nProvider = {
  translate: (key: string, params?: Record<string, string>) => {
    return i18n.t(key, params) as string;
  },
  changeLocale: (lang: string) => {
    return i18n.changeLanguage(lang);
  },
  getLocale: () => {
    return i18n.language;
  },
};
