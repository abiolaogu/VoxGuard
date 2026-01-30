import type { ThemeConfig } from 'antd';

// ACM Brand Colors
export const ACM_COLORS = {
  // Primary - Deep Blue (Trust & Security)
  primary: '#1B4F72',
  primaryLight: '#2E86AB',
  primaryDark: '#154360',

  // Secondary - Teal (Technology & Innovation)
  secondary: '#17A2B8',
  secondaryLight: '#20C997',
  secondaryDark: '#138496',

  // Accent - Orange (Alert & Attention)
  accent: '#E67E22',
  accentLight: '#F39C12',
  accentDark: '#D35400',

  // Status Colors
  success: '#28A745',
  warning: '#FFC107',
  error: '#DC3545',
  info: '#17A2B8',

  // Severity Colors for Alerts
  critical: '#DC3545',
  high: '#E67E22',
  medium: '#FFC107',
  low: '#17A2B8',

  // Neutral Colors
  background: '#F8F9FA',
  surface: '#FFFFFF',
  textPrimary: '#212529',
  textSecondary: '#6C757D',
  border: '#DEE2E6',
};

// Light Theme Configuration
export const lightTheme: ThemeConfig = {
  token: {
    colorPrimary: ACM_COLORS.primary,
    colorSuccess: ACM_COLORS.success,
    colorWarning: ACM_COLORS.warning,
    colorError: ACM_COLORS.error,
    colorInfo: ACM_COLORS.info,
    colorBgContainer: ACM_COLORS.surface,
    colorBgLayout: ACM_COLORS.background,
    colorText: ACM_COLORS.textPrimary,
    colorTextSecondary: ACM_COLORS.textSecondary,
    colorBorder: ACM_COLORS.border,
    borderRadius: 6,
    fontFamily: "'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif",
  },
  components: {
    Layout: {
      siderBg: ACM_COLORS.primaryDark,
      headerBg: ACM_COLORS.surface,
      bodyBg: ACM_COLORS.background,
    },
    Menu: {
      darkItemBg: ACM_COLORS.primaryDark,
      darkItemSelectedBg: ACM_COLORS.primary,
      darkItemHoverBg: ACM_COLORS.primary,
    },
    Card: {
      borderRadiusLG: 8,
    },
    Table: {
      headerBg: '#FAFAFA',
      rowHoverBg: '#F5F5F5',
    },
    Button: {
      primaryShadow: '0 2px 0 rgba(27, 79, 114, 0.1)',
    },
  },
};

// Dark Theme Configuration
export const darkTheme: ThemeConfig = {
  token: {
    colorPrimary: ACM_COLORS.primaryLight,
    colorSuccess: ACM_COLORS.success,
    colorWarning: ACM_COLORS.warning,
    colorError: ACM_COLORS.error,
    colorInfo: ACM_COLORS.info,
    colorBgContainer: '#1F1F1F',
    colorBgLayout: '#141414',
    colorText: '#FFFFFF',
    colorTextSecondary: '#A0A0A0',
    colorBorder: '#303030',
    borderRadius: 6,
    fontFamily: "'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif",
  },
  components: {
    Layout: {
      siderBg: '#001529',
      headerBg: '#1F1F1F',
      bodyBg: '#141414',
    },
    Menu: {
      darkItemBg: '#001529',
      darkItemSelectedBg: ACM_COLORS.primaryLight,
      darkItemHoverBg: '#1890ff22',
    },
    Card: {
      borderRadiusLG: 8,
    },
    Table: {
      headerBg: '#1D1D1D',
      rowHoverBg: '#2A2A2A',
    },
  },
};

// Severity Badge Colors
export const severityColors: Record<string, { color: string; background: string }> = {
  CRITICAL: { color: '#FFFFFF', background: ACM_COLORS.critical },
  HIGH: { color: '#FFFFFF', background: ACM_COLORS.high },
  MEDIUM: { color: '#000000', background: ACM_COLORS.medium },
  LOW: { color: '#FFFFFF', background: ACM_COLORS.low },
};

// Status Badge Colors
export const statusColors: Record<string, { color: string; background: string }> = {
  NEW: { color: '#FFFFFF', background: ACM_COLORS.info },
  INVESTIGATING: { color: '#FFFFFF', background: ACM_COLORS.warning },
  CONFIRMED: { color: '#FFFFFF', background: ACM_COLORS.error },
  RESOLVED: { color: '#FFFFFF', background: ACM_COLORS.success },
  FALSE_POSITIVE: { color: '#FFFFFF', background: ACM_COLORS.textSecondary },
};
