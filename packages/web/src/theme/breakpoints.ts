/**
 * Responsive breakpoints for mobile-first design
 */
export const breakpoints = {
    xs: 480,
    sm: 576,
    md: 768,
    lg: 992,
    xl: 1200,
    xxl: 1600,
} as const;

/**
 * Media query helpers
 */
export const media = {
    xs: `@media (min-width: ${breakpoints.xs}px)`,
    sm: `@media (min-width: ${breakpoints.sm}px)`,
    md: `@media (min-width: ${breakpoints.md}px)`,
    lg: `@media (min-width: ${breakpoints.lg}px)`,
    xl: `@media (min-width: ${breakpoints.xl}px)`,
    xxl: `@media (min-width: ${breakpoints.xxl}px)`,

    // Max-width queries
    xsMax: `@media (max-width: ${breakpoints.xs - 1}px)`,
    smMax: `@media (max-width: ${breakpoints.sm - 1}px)`,
    mdMax: `@media (max-width: ${breakpoints.md - 1}px)`,
    lgMax: `@media (max-width: ${breakpoints.lg - 1}px)`,
    xlMax: `@media (max-width: ${breakpoints.xl - 1}px)`,
    xxlMax: `@media (max-width: ${breakpoints.xxl - 1}px)`,
} as const;

/**
 * Grid configuration
 */
export const grid = {
    columns: 24,
    gutter: 16,
    gutterLg: 24,
    containerMaxWidth: 1440,
    containerPadding: 24,
} as const;

/**
 * Spacing scale (in pixels)
 */
export const spacing = {
    xs: 4,
    sm: 8,
    md: 16,
    lg: 24,
    xl: 32,
    xxl: 48,
    xxxl: 64,
} as const;

/**
 * Z-index scale
 */
export const zIndex = {
    dropdown: 1000,
    sticky: 1020,
    fixed: 1030,
    modalBackdrop: 1040,
    modal: 1050,
    popover: 1060,
    tooltip: 1070,
    toast: 1080,
} as const;

/**
 * Hook for responsive breakpoint detection
 */
export const useBreakpoint = () => {
    if (typeof window === 'undefined') {
        return {
            isMobile: false,
            isTablet: false,
            isDesktop: true,
            isXs: false,
            isSm: false,
            isMd: false,
            isLg: false,
            isXl: true,
            isXxl: false,
        };
    }

    const width = window.innerWidth;

    return {
        isMobile: width < breakpoints.md,
        isTablet: width >= breakpoints.md && width < breakpoints.lg,
        isDesktop: width >= breakpoints.lg,
        isXs: width < breakpoints.sm,
        isSm: width >= breakpoints.sm && width < breakpoints.md,
        isMd: width >= breakpoints.md && width < breakpoints.lg,
        isLg: width >= breakpoints.lg && width < breakpoints.xl,
        isXl: width >= breakpoints.xl && width < breakpoints.xxl,
        isXxl: width >= breakpoints.xxl,
    };
};

export default { breakpoints, media, grid, spacing, zIndex };
