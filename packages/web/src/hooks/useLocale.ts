import { useCallback, useMemo } from 'react';
import { useTranslation } from 'react-i18next';

const STORAGE_KEY = 'voxguard-locale-prefs';

interface LocalePreferences {
  language: string;
  currency: string;
  secondaryCurrency?: string;
  timezone: string;
  dateFormat: 'short' | 'medium' | 'long';
}

const defaultPrefs: LocalePreferences = {
  language: 'en',
  currency: 'NGN',
  timezone: 'Africa/Lagos',
  dateFormat: 'medium',
};

function getStoredPrefs(): LocalePreferences {
  try {
    const stored = localStorage.getItem(STORAGE_KEY);
    if (stored) return { ...defaultPrefs, ...JSON.parse(stored) };
  } catch {
    // ignore
  }
  return defaultPrefs;
}

function storePrefs(prefs: LocalePreferences) {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(prefs));
}

export function useLocale() {
  const { i18n } = useTranslation();

  const prefs = useMemo(() => getStoredPrefs(), []);

  const setLanguage = useCallback(
    (lang: string) => {
      i18n.changeLanguage(lang);
      const updated = { ...getStoredPrefs(), language: lang };
      storePrefs(updated);
      localStorage.setItem('voxguard-language', lang);
    },
    [i18n],
  );

  const setCurrency = useCallback((currency: string) => {
    const updated = { ...getStoredPrefs(), currency };
    storePrefs(updated);
    window.dispatchEvent(new Event('voxguard-locale-change'));
  }, []);

  const setSecondaryCurrency = useCallback((secondaryCurrency: string | undefined) => {
    const updated = { ...getStoredPrefs(), secondaryCurrency };
    storePrefs(updated);
    window.dispatchEvent(new Event('voxguard-locale-change'));
  }, []);

  const setTimezone = useCallback((timezone: string) => {
    const updated = { ...getStoredPrefs(), timezone };
    storePrefs(updated);
  }, []);

  const setDateFormat = useCallback((dateFormat: 'short' | 'medium' | 'long') => {
    const updated = { ...getStoredPrefs(), dateFormat };
    storePrefs(updated);
  }, []);

  const formatCurrency = useCallback(
    (amount: number, currencyCode?: string) => {
      const currency = currencyCode || getStoredPrefs().currency;
      const locale = i18n.language;
      try {
        return new Intl.NumberFormat(locale, {
          style: 'currency',
          currency,
        }).format(amount);
      } catch {
        return `${currency} ${amount.toFixed(2)}`;
      }
    },
    [i18n.language],
  );

  const formatNumber = useCallback(
    (value: number, options?: Intl.NumberFormatOptions) => {
      const locale = i18n.language;
      try {
        return new Intl.NumberFormat(locale, options).format(value);
      } catch {
        return String(value);
      }
    },
    [i18n.language],
  );

  const formatDate = useCallback(
    (date: string | Date, style?: 'short' | 'medium' | 'long') => {
      const locale = i18n.language;
      const tz = getStoredPrefs().timezone;
      const fmt = style || getStoredPrefs().dateFormat;
      const dateObj = typeof date === 'string' ? new Date(date) : date;

      const options: Intl.DateTimeFormatOptions = { timeZone: tz };
      switch (fmt) {
        case 'short':
          options.dateStyle = 'short';
          break;
        case 'long':
          options.dateStyle = 'long';
          options.timeStyle = 'medium';
          break;
        default:
          options.dateStyle = 'medium';
          options.timeStyle = 'short';
      }

      try {
        return new Intl.DateTimeFormat(locale, options).format(dateObj);
      } catch {
        return dateObj.toLocaleDateString();
      }
    },
    [i18n.language],
  );

  return {
    language: i18n.language,
    currency: prefs.currency,
    secondaryCurrency: prefs.secondaryCurrency,
    timezone: prefs.timezone,
    dateFormat: prefs.dateFormat,
    setLanguage,
    setCurrency,
    setSecondaryCurrency,
    setTimezone,
    setDateFormat,
    formatCurrency,
    formatNumber,
    formatDate,
  };
}
