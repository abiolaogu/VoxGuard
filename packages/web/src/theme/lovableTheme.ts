import type { ThemeConfig } from 'antd';

/**
 * Lovable UI Theme Configuration
 * Trust & Security focused design system for Anti-Call Masking Platform
 */
export const lovableTheme: ThemeConfig = {
    token: {
        // Primary palette - Trust & Security focused
        colorPrimary: '#1890ff',
        colorSuccess: '#52c41a',
        colorWarning: '#faad14',
        colorError: '#ff4d4f',
        colorInfo: '#1890ff',

        // Extended palette
        colorPrimaryBg: '#e6f4ff',
        colorPrimaryBgHover: '#bae0ff',
        colorPrimaryBorder: '#91caff',
        colorPrimaryBorderHover: '#69b1ff',
        colorPrimaryHover: '#4096ff',
        colorPrimaryActive: '#0958d9',
        colorPrimaryTextHover: '#4096ff',
        colorPrimaryText: '#1890ff',
        colorPrimaryTextActive: '#0958d9',

        // Background colors
        colorBgContainer: '#ffffff',
        colorBgElevated: '#ffffff',
        colorBgLayout: '#f5f7fa',
        colorBgSpotlight: 'rgba(0, 0, 0, 0.85)',
        colorBgMask: 'rgba(0, 0, 0, 0.45)',

        // Text colors
        colorText: 'rgba(0, 0, 0, 0.88)',
        colorTextSecondary: 'rgba(0, 0, 0, 0.65)',
        colorTextTertiary: 'rgba(0, 0, 0, 0.45)',
        colorTextQuaternary: 'rgba(0, 0, 0, 0.25)',

        // Border colors
        colorBorder: '#d9d9d9',
        colorBorderSecondary: '#f0f0f0',

        // Typography - Inter for modern, clean look
        fontFamily: "'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif",
        fontSize: 14,
        fontSizeSM: 12,
        fontSizeLG: 16,
        fontSizeXL: 20,
        fontSizeHeading1: 38,
        fontSizeHeading2: 30,
        fontSizeHeading3: 24,
        fontSizeHeading4: 20,
        fontSizeHeading5: 16,

        // Line heights
        lineHeight: 1.5714285714285714,
        lineHeightLG: 1.5,
        lineHeightSM: 1.6666666666666667,
        lineHeightHeading1: 1.2105263157894737,
        lineHeightHeading2: 1.2666666666666666,
        lineHeightHeading3: 1.3333333333333333,
        lineHeightHeading4: 1.4,
        lineHeightHeading5: 1.5,

        // Spacing & Radius - Lovable soft corners
        borderRadius: 8,
        borderRadiusSM: 6,
        borderRadiusLG: 12,
        borderRadiusXS: 4,

        // Control heights
        controlHeight: 40,
        controlHeightLG: 48,
        controlHeightSM: 32,
        controlHeightXS: 24,

        // Shadows for depth - Lovable elevation
        boxShadow: '0 2px 8px rgba(0, 0, 0, 0.08)',
        boxShadowSecondary: '0 4px 16px rgba(0, 0, 0, 0.12)',
        boxShadowTertiary: '0 1px 2px rgba(0, 0, 0, 0.03), 0 1px 6px -1px rgba(0, 0, 0, 0.02), 0 2px 4px rgba(0, 0, 0, 0.02)',

        // Motion
        motionDurationFast: '0.1s',
        motionDurationMid: '0.2s',
        motionDurationSlow: '0.3s',
        motionEaseInOut: 'cubic-bezier(0.645, 0.045, 0.355, 1)',
        motionEaseOut: 'cubic-bezier(0.215, 0.61, 0.355, 1)',
        motionEaseIn: 'cubic-bezier(0.55, 0.055, 0.675, 0.19)',
        motionEaseOutBack: 'cubic-bezier(0.12, 0.4, 0.29, 1.46)',
        motionEaseInBack: 'cubic-bezier(0.71, -0.46, 0.88, 0.6)',
        motionEaseOutCirc: 'cubic-bezier(0.08, 0.82, 0.17, 1)',
        motionEaseInCirc: 'cubic-bezier(0.6, 0.04, 0.98, 0.34)',
        motionEaseOutQuint: 'cubic-bezier(0.23, 1, 0.32, 1)',
        motionEaseInQuint: 'cubic-bezier(0.755, 0.05, 0.855, 0.06)',

        // Link
        colorLink: '#1890ff',
        colorLinkHover: '#40a9ff',
        colorLinkActive: '#096dd9',

        // Wire frame
        wireframe: false,
    },
    components: {
        // Button - Lovable rounded with better padding
        Button: {
            controlHeight: 40,
            controlHeightLG: 48,
            controlHeightSM: 32,
            paddingContentHorizontal: 24,
            borderRadius: 8,
            primaryShadow: '0 2px 0 rgba(24, 144, 255, 0.1)',
            defaultShadow: '0 2px 0 rgba(0, 0, 0, 0.02)',
            dangerShadow: '0 2px 0 rgba(255, 77, 79, 0.1)',
        },
        // Card - Glassmorphism style
        Card: {
            paddingLG: 24,
            borderRadiusLG: 12,
            boxShadowTertiary: '0 1px 2px rgba(0, 0, 0, 0.03), 0 2px 4px rgba(0, 0, 0, 0.04), 0 4px 8px rgba(0, 0, 0, 0.04)',
        },
        // Table - Clean header with subtle background
        Table: {
            headerBg: '#fafafa',
            headerColor: 'rgba(0, 0, 0, 0.88)',
            headerSortActiveBg: '#f0f0f0',
            headerSortHoverBg: '#f5f5f5',
            rowHoverBg: '#fafafa',
            borderColor: '#f0f0f0',
        },
        // Input - Larger touch targets
        Input: {
            controlHeight: 40,
            controlHeightLG: 48,
            controlHeightSM: 32,
            paddingInline: 12,
            borderRadius: 8,
        },
        // Select
        Select: {
            controlHeight: 40,
            borderRadius: 8,
        },
        // Modal - Rounded corners
        Modal: {
            borderRadiusLG: 16,
            paddingContentHorizontal: 24,
            paddingContentVertical: 20,
        },
        // Notification
        Notification: {
            borderRadiusLG: 12,
        },
        // Message
        Message: {
            borderRadiusLG: 8,
        },
        // Tag - Pill style
        Tag: {
            borderRadiusSM: 4,
        },
        // Dropdown
        Dropdown: {
            borderRadiusLG: 8,
        },
        // Menu
        Menu: {
            itemBorderRadius: 6,
            subMenuItemBorderRadius: 6,
        },
        // Tooltip
        Tooltip: {
            borderRadius: 6,
        },
        // Drawer
        Drawer: {
            borderRadiusLG: 0,
        },
        // Progress
        Progress: {
            circleTextFontSize: '1em',
        },
        // Statistic
        Statistic: {
            titleFontSize: 14,
            contentFontSize: 24,
        },
        // Alert
        Alert: {
            borderRadiusLG: 8,
        },
        // Badge
        Badge: {
            textFontSize: 12,
            textFontSizeSM: 12,
        },
    },
};

/**
 * Dark mode theme configuration
 */
export const lovableDarkTheme: ThemeConfig = {
    ...lovableTheme,
    token: {
        ...lovableTheme.token,
        // Background colors - Dark mode
        colorBgContainer: '#141414',
        colorBgElevated: '#1f1f1f',
        colorBgLayout: '#000000',
        colorBgSpotlight: 'rgba(255, 255, 255, 0.85)',
        colorBgMask: 'rgba(0, 0, 0, 0.75)',

        // Text colors - Dark mode
        colorText: 'rgba(255, 255, 255, 0.85)',
        colorTextSecondary: 'rgba(255, 255, 255, 0.65)',
        colorTextTertiary: 'rgba(255, 255, 255, 0.45)',
        colorTextQuaternary: 'rgba(255, 255, 255, 0.25)',

        // Border colors - Dark mode
        colorBorder: '#424242',
        colorBorderSecondary: '#303030',

        // Shadows for dark mode
        boxShadow: '0 2px 8px rgba(0, 0, 0, 0.32)',
        boxShadowSecondary: '0 4px 16px rgba(0, 0, 0, 0.48)',
    },
    components: {
        ...lovableTheme.components,
        Table: {
            headerBg: '#1f1f1f',
            headerColor: 'rgba(255, 255, 255, 0.85)',
            headerSortActiveBg: '#2a2a2a',
            headerSortHoverBg: '#262626',
            rowHoverBg: '#262626',
            borderColor: '#303030',
        },
    },
};

export default lovableTheme;
