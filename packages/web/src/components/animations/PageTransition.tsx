import React from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { pageTransition, pageSlideIn, pageFade } from '@/theme/animations';

interface PageTransitionProps {
    children: React.ReactNode;
    variant?: 'fade' | 'slide' | 'default';
    className?: string;
}

/**
 * Animated page wrapper for smooth page transitions
 */
export const PageTransition: React.FC<PageTransitionProps> = ({
    children,
    variant = 'default',
    className,
}) => {
    const variants = {
        default: pageTransition,
        slide: pageSlideIn,
        fade: pageFade,
    };

    return (
        <motion.div
            className={className}
            initial="initial"
            animate="animate"
            exit="exit"
            variants={variants[variant]}
        >
            {children}
        </motion.div>
    );
};

interface FadeInProps {
    children: React.ReactNode;
    delay?: number;
    duration?: number;
    className?: string;
}

/**
 * Simple fade-in animation wrapper
 */
export const FadeIn: React.FC<FadeInProps> = ({
    children,
    delay = 0,
    duration = 0.3,
    className,
}) => (
    <motion.div
        className={className}
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay, duration }}
    >
        {children}
    </motion.div>
);

interface SlideInProps {
    children: React.ReactNode;
    direction?: 'up' | 'down' | 'left' | 'right';
    delay?: number;
    distance?: number;
    className?: string;
}

/**
 * Slide-in animation wrapper
 */
export const SlideIn: React.FC<SlideInProps> = ({
    children,
    direction = 'up',
    delay = 0,
    distance = 20,
    className,
}) => {
    const getInitialPosition = () => {
        switch (direction) {
            case 'up':
                return { y: distance };
            case 'down':
                return { y: -distance };
            case 'left':
                return { x: distance };
            case 'right':
                return { x: -distance };
        }
    };

    return (
        <motion.div
            className={className}
            initial={{ opacity: 0, ...getInitialPosition() }}
            animate={{ opacity: 1, x: 0, y: 0 }}
            transition={{ delay, duration: 0.3, ease: [0.215, 0.61, 0.355, 1] }}
        >
            {children}
        </motion.div>
    );
};

interface ScaleInProps {
    children: React.ReactNode;
    delay?: number;
    className?: string;
}

/**
 * Scale-in animation wrapper
 */
export const ScaleIn: React.FC<ScaleInProps> = ({
    children,
    delay = 0,
    className,
}) => (
    <motion.div
        className={className}
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ delay, duration: 0.3, ease: [0.215, 0.61, 0.355, 1] }}
    >
        {children}
    </motion.div>
);

interface StaggerListProps {
    children: React.ReactNode;
    staggerDelay?: number;
    className?: string;
}

/**
 * Staggered animation container for lists
 */
export const StaggerList: React.FC<StaggerListProps> = ({
    children,
    staggerDelay = 0.08,
    className,
}) => (
    <motion.div
        className={className}
        initial="hidden"
        animate="visible"
        variants={{
            hidden: { opacity: 0 },
            visible: {
                opacity: 1,
                transition: {
                    staggerChildren: staggerDelay,
                },
            },
        }}
    >
        {children}
    </motion.div>
);

interface StaggerItemProps {
    children: React.ReactNode;
    className?: string;
}

/**
 * Individual item for staggered lists
 */
export const StaggerItem: React.FC<StaggerItemProps> = ({ children, className }) => (
    <motion.div
        className={className}
        variants={{
            hidden: { opacity: 0, y: 10 },
            visible: {
                opacity: 1,
                y: 0,
                transition: { duration: 0.3 },
            },
        }}
    >
        {children}
    </motion.div>
);

interface AnimatedCounterProps {
    value: number;
    duration?: number;
    formatValue?: (value: number) => string;
    className?: string;
}

/**
 * Animated number counter
 */
export const AnimatedCounter: React.FC<AnimatedCounterProps> = ({
    value,
    duration = 1,
    formatValue = (v) => v.toLocaleString(),
    className,
}) => {
    const [displayValue, setDisplayValue] = React.useState(0);

    React.useEffect(() => {
        const startTime = Date.now();
        const startValue = displayValue;

        const animate = () => {
            const elapsed = Date.now() - startTime;
            const progress = Math.min(elapsed / (duration * 1000), 1);
            const eased = 1 - Math.pow(1 - progress, 3); // Cubic ease out

            setDisplayValue(Math.floor(startValue + (value - startValue) * eased));

            if (progress < 1) {
                requestAnimationFrame(animate);
            }
        };

        requestAnimationFrame(animate);
    }, [value, duration]);

    return (
        <motion.span
            className={className}
            key={value}
            initial={{ opacity: 0.5, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ duration: 0.2 }}
        >
            {formatValue(displayValue)}
        </motion.span>
    );
};

interface PresenceContainerProps {
    children: React.ReactNode;
    show: boolean;
    mode?: 'wait' | 'sync' | 'popLayout';
}

/**
 * AnimatePresence wrapper for conditional rendering
 */
export const PresenceContainer: React.FC<PresenceContainerProps> = ({
    children,
    show,
    mode = 'wait',
}) => (
    <AnimatePresence mode={mode}>
        {show && children}
    </AnimatePresence>
);

export default {
    PageTransition,
    FadeIn,
    SlideIn,
    ScaleIn,
    StaggerList,
    StaggerItem,
    AnimatedCounter,
    PresenceContainer,
};
