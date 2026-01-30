import type { ThemeConfig } from 'antd';

// VoxGuard Brand Colors
export const VG_COLORS = {
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
    colorPrimary: VG_COLORS.primary,
    colorSuccess: VG_COLORS.success,
    colorWarning: VG_COLORS.warning,
    colorError: VG_COLORS.error,
    colorInfo: VG_COLORS.info,
    colorBgContainer: VG_COLORS.surface,
    colorBgLayout: VG_COLORS.background,
    colorText: VG_COLORS.textPrimary,
    colorTextSecondary: VG_COLORS.textSecondary,
    colorBorder: VG_COLORS.border,
    borderRadius: 6,
    fontFamily: "'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif",
  },
  components: {
    Layout: {
      siderBg: VG_COLORS.primaryDark,
      headerBg: VG_COLORS.surface,
      bodyBg: VG_COLORS.background,
    },
    Menu: {
      darkItemBg: VG_COLORS.primaryDark,
      darkItemSelectedBg: VG_COLORS.primary,
      darkItemHoverBg: VG_COLORS.primary,
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
    colorPrimary: VG_COLORS.primaryLight,
    colorSuccess: VG_COLORS.success,
    colorWarning: VG_COLORS.warning,
    colorError: VG_COLORS.error,
    colorInfo: VG_COLORS.info,
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
      darkItemSelectedBg: VG_COLORS.primaryLight,
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
  CRITICAL: { color: '#FFFFFF', background: VG_COLORS.critical },
  HIGH: { color: '#FFFFFF', background: VG_COLORS.high },
  MEDIUM: { color: '#000000', background: VG_COLORS.medium },
  LOW: { color: '#FFFFFF', background: VG_COLORS.low },
};

// Status Badge Colors
export const statusColors: Record<string, { color: string; background: string }> = {
  NEW: { color: '#FFFFFF', background: VG_COLORS.info },
  INVESTIGATING: { color: '#FFFFFF', background: VG_COLORS.warning },
  CONFIRMED: { color: '#FFFFFF', background: VG_COLORS.error },
  RESOLVED: { color: '#FFFFFF', background: VG_COLORS.success },
  FALSE_POSITIVE: { color: '#FFFFFF', background: VG_COLORS.textSecondary },
};
