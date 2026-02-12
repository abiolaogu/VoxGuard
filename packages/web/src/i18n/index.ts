import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import LanguageDetector from 'i18next-browser-languagedetector';

import en from './locales/en.json';
import fr from './locales/fr.json';
import pt from './locales/pt.json';
import ha from './locales/ha.json';
import yo from './locales/yo.json';
import ig from './locales/ig.json';
import ar from './locales/ar.json';
import es from './locales/es.json';
import zh from './locales/zh.json';
import sw from './locales/sw.json';

export const supportedLanguages = [
  { code: 'en', label: 'English', dir: 'ltr' },
  { code: 'fr', label: 'Français', dir: 'ltr' },
  { code: 'pt', label: 'Português', dir: 'ltr' },
  { code: 'ha', label: 'Hausa', dir: 'ltr' },
  { code: 'yo', label: 'Yorùbá', dir: 'ltr' },
  { code: 'ig', label: 'Igbo', dir: 'ltr' },
  { code: 'ar', label: 'العربية', dir: 'rtl' },
  { code: 'es', label: 'Español', dir: 'ltr' },
  { code: 'zh', label: '中文', dir: 'ltr' },
  { code: 'sw', label: 'Kiswahili', dir: 'ltr' },
] as const;

i18n
  .use(LanguageDetector)
  .use(initReactI18next)
  .init({
    resources: {
      en: { translation: en },
      fr: { translation: fr },
      pt: { translation: pt },
      ha: { translation: ha },
      yo: { translation: yo },
      ig: { translation: ig },
      ar: { translation: ar },
      es: { translation: es },
      zh: { translation: zh },
      sw: { translation: sw },
    },
    fallbackLng: 'en',
    interpolation: {
      escapeValue: false,
    },
    detection: {
      order: ['localStorage', 'navigator'],
      lookupLocalStorage: 'voxguard-language',
      caches: ['localStorage'],
    },
  });

export default i18n;
