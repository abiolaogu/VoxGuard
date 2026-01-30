import { useState, useEffect, useCallback } from 'react';

type ThemeMode = 'light' | 'dark';

const THEME_STORAGE_KEY = 'acm-theme-mode';

export function useThemeMode() {
  const [mode, setMode] = useState<ThemeMode>(() => {
    // Check localStorage first
    const stored = localStorage.getItem(THEME_STORAGE_KEY);
    if (stored === 'light' || stored === 'dark') {
      return stored;
    }

    // Check system preference
    if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {
      return 'dark';
    }

    return 'light';
  });

  useEffect(() => {
    // Save to localStorage
    localStorage.setItem(THEME_STORAGE_KEY, mode);

    // Update document attribute for CSS selectors
    document.documentElement.setAttribute('data-theme', mode);

    // Update Ant Design's algorithm (for components that use ConfigProvider)
    document.body.classList.remove('light-mode', 'dark-mode');
    document.body.classList.add(`${mode}-mode`);
  }, [mode]);

  const toggleMode = useCallback(() => {
    setMode((prevMode) => (prevMode === 'light' ? 'dark' : 'light'));
  }, []);

  const setThemeMode = useCallback((newMode: ThemeMode) => {
    setMode(newMode);
  }, []);

  return {
    mode,
    isDark: mode === 'dark',
    isLight: mode === 'light',
    toggleMode,
    setThemeMode,
  };
}

export default useThemeMode;
