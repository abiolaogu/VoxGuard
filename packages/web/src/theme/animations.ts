import type { Variants, Transition } from 'framer-motion';

/**
 * Lovable Animation System
 * Smooth, delightful animations for enhanced UX
 */

// ============================================================================
// Transitions
// ============================================================================

export const easeOut: Transition = {
    type: 'tween',
    ease: [0.215, 0.61, 0.355, 1],
    duration: 0.3,
};

export const easeInOut: Transition = {
    type: 'tween',
    ease: [0.645, 0.045, 0.355, 1],
    duration: 0.3,
};

export const spring: Transition = {
    type: 'spring',
    stiffness: 400,
    damping: 30,
};

export const springBouncy: Transition = {
    type: 'spring',
    stiffness: 500,
    damping: 25,
};

export const springGentle: Transition = {
    type: 'spring',
    stiffness: 300,
    damping: 35,
};

// ============================================================================
// Page Transitions
// ============================================================================

export const pageTransition: Variants = {
    initial: { opacity: 0, y: 20 },
    animate: {
        opacity: 1,
        y: 0,
        transition: { duration: 0.3, ease: [0.215, 0.61, 0.355, 1] },
    },
    exit: {
        opacity: 0,
        y: -20,
        transition: { duration: 0.2, ease: [0.645, 0.045, 0.355, 1] },
    },
};

export const pageSlideIn: Variants = {
    initial: { opacity: 0, x: 20 },
    animate: {
        opacity: 1,
        x: 0,
        transition: { duration: 0.4, ease: [0.215, 0.61, 0.355, 1] },
    },
    exit: {
        opacity: 0,
        x: -20,
        transition: { duration: 0.2 },
    },
};

export const pageFade: Variants = {
    initial: { opacity: 0 },
    animate: {
        opacity: 1,
        transition: { duration: 0.4 },
    },
    exit: {
        opacity: 0,
        transition: { duration: 0.2 },
    },
};

// ============================================================================
// Card Animations
// ============================================================================

export const cardHover = {
    whileHover: {
        scale: 1.02,
        boxShadow: '0 8px 24px rgba(0, 0, 0, 0.12)',
        transition: { duration: 0.2 },
    },
    whileTap: {
        scale: 0.98,
        transition: { duration: 0.1 },
    },
};

export const cardVariants: Variants = {
    hidden: {
        opacity: 0,
        y: 20,
        scale: 0.95,
    },
    visible: {
        opacity: 1,
        y: 0,
        scale: 1,
        transition: { duration: 0.3, ease: [0.215, 0.61, 0.355, 1] },
    },
};

export const cardGlassmorphism = {
    background: 'rgba(255, 255, 255, 0.7)',
    backdropFilter: 'blur(10px)',
    border: '1px solid rgba(255, 255, 255, 0.2)',
};

// ============================================================================
// List & Stagger Animations
// ============================================================================

export const staggerContainer: Variants = {
    hidden: { opacity: 0 },
    visible: {
        opacity: 1,
        transition: {
            staggerChildren: 0.08,
            delayChildren: 0.1,
        },
    },
};

export const staggerFast: Variants = {
    hidden: { opacity: 0 },
    visible: {
        opacity: 1,
        transition: {
            staggerChildren: 0.05,
        },
    },
};

export const staggerItem: Variants = {
    hidden: { opacity: 0, y: 10 },
    visible: {
        opacity: 1,
        y: 0,
        transition: { duration: 0.3, ease: [0.215, 0.61, 0.355, 1] },
    },
};

export const listItemVariants: Variants = {
    hidden: { opacity: 0, x: -10 },
    visible: {
        opacity: 1,
        x: 0,
        transition: { duration: 0.2 },
    },
    exit: {
        opacity: 0,
        x: 10,
        transition: { duration: 0.15 },
    },
};

// ============================================================================
// Alert & Notification Animations
// ============================================================================

export const alertPulse: Variants = {
    initial: { scale: 1 },
    pulse: {
        scale: [1, 1.05, 1],
        transition: {
            duration: 0.6,
            repeat: Infinity,
            repeatType: 'loop',
        },
    },
};

export const alertShake: Variants = {
    initial: { x: 0 },
    shake: {
        x: [-5, 5, -5, 5, 0],
        transition: { duration: 0.4 },
    },
};

export const notificationSlide: Variants = {
    initial: { opacity: 0, x: 100, scale: 0.9 },
    animate: {
        opacity: 1,
        x: 0,
        scale: 1,
        transition: { type: 'spring', stiffness: 400, damping: 30 },
    },
    exit: {
        opacity: 0,
        x: 100,
        transition: { duration: 0.2 },
    },
};

// ============================================================================
// Button Animations
// ============================================================================

export const buttonTap = {
    whileTap: { scale: 0.95 },
    transition: { duration: 0.1 },
};

export const buttonHover = {
    whileHover: { scale: 1.02 },
    whileTap: { scale: 0.98 },
};

export const buttonRipple: Variants = {
    initial: { scale: 0, opacity: 0.5 },
    animate: {
        scale: 4,
        opacity: 0,
        transition: { duration: 0.6 },
    },
};

// ============================================================================
// Loading Animations
// ============================================================================

export const loadingPulse: Variants = {
    initial: { opacity: 0.3 },
    animate: {
        opacity: [0.3, 1, 0.3],
        transition: {
            duration: 1.5,
            repeat: Infinity,
            ease: 'easeInOut',
        },
    },
};

export const loadingSpin = {
    animate: {
        rotate: 360,
        transition: {
            duration: 1,
            repeat: Infinity,
            ease: 'linear',
        },
    },
};

export const skeletonShimmer: Variants = {
    initial: {
        backgroundPosition: '-200% 0',
    },
    animate: {
        backgroundPosition: ['200% 0', '-200% 0'],
        transition: {
            duration: 1.5,
            repeat: Infinity,
            ease: 'linear',
        },
    },
};

// ============================================================================
// Success & Celebration Animations
// ============================================================================

export const successCheck: Variants = {
    initial: { pathLength: 0, opacity: 0 },
    animate: {
        pathLength: 1,
        opacity: 1,
        transition: { duration: 0.5, ease: 'easeOut' },
    },
};

export const successBounce: Variants = {
    initial: { scale: 0, opacity: 0 },
    animate: {
        scale: [0, 1.2, 1],
        opacity: 1,
        transition: {
            duration: 0.5,
            times: [0, 0.6, 1],
            ease: 'easeOut',
        },
    },
};

export const confettiParticle = (index: number): Variants => ({
    initial: {
        opacity: 1,
        y: 0,
        x: 0,
        rotate: 0,
        scale: 1,
    },
    animate: {
        opacity: [1, 1, 0],
        y: [0, -100 - Math.random() * 100, 200],
        x: (Math.random() - 0.5) * 300,
        rotate: Math.random() * 720 - 360,
        scale: [1, 1.2, 0.5],
        transition: {
            duration: 1.5 + Math.random() * 0.5,
            ease: 'easeOut',
        },
    },
});

// ============================================================================
// Number Counter Animation
// ============================================================================

export const counterVariants: Variants = {
    initial: { opacity: 0, y: 10 },
    animate: {
        opacity: 1,
        y: 0,
        transition: { duration: 0.3 },
    },
};

// ============================================================================
// Modal & Drawer Animations
// ============================================================================

export const modalOverlay: Variants = {
    initial: { opacity: 0 },
    animate: { opacity: 1 },
    exit: { opacity: 0 },
};

export const modalContent: Variants = {
    initial: { opacity: 0, scale: 0.95, y: 20 },
    animate: {
        opacity: 1,
        scale: 1,
        y: 0,
        transition: { type: 'spring', stiffness: 400, damping: 30 },
    },
    exit: {
        opacity: 0,
        scale: 0.95,
        transition: { duration: 0.15 },
    },
};

export const drawerSlide: Variants = {
    initial: { x: '100%' },
    animate: {
        x: 0,
        transition: { type: 'spring', stiffness: 400, damping: 40 },
    },
    exit: {
        x: '100%',
        transition: { duration: 0.2 },
    },
};

// ============================================================================
// Tooltip & Popover Animations
// ============================================================================

export const tooltipVariants: Variants = {
    initial: { opacity: 0, scale: 0.95 },
    animate: {
        opacity: 1,
        scale: 1,
        transition: { duration: 0.15 },
    },
    exit: {
        opacity: 0,
        scale: 0.95,
        transition: { duration: 0.1 },
    },
};

// ============================================================================
// Progress & Step Animations
// ============================================================================

export const progressFill: Variants = {
    initial: { width: 0 },
    animate: (custom: number) => ({
        width: `${custom}%`,
        transition: { duration: 0.8, ease: [0.215, 0.61, 0.355, 1] },
    }),
};

export const stepVariants: Variants = {
    inactive: { scale: 1, backgroundColor: '#e6e6e6' },
    active: {
        scale: 1.1,
        backgroundColor: '#1890ff',
        transition: { type: 'spring', stiffness: 400, damping: 20 },
    },
    complete: {
        scale: 1,
        backgroundColor: '#52c41a',
        transition: { duration: 0.2 },
    },
};

export default {
    pageTransition,
    cardHover,
    staggerContainer,
    staggerItem,
    alertPulse,
    buttonTap,
    loadingPulse,
    successBounce,
};
