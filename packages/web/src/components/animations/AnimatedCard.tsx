import React from 'react';
import { motion } from 'framer-motion';
import { Card as AntCard, CardProps as AntCardProps } from 'antd';
import { cardHover, cardVariants } from '@/theme/animations';

interface AnimatedCardProps extends AntCardProps {
    enableHover?: boolean;
    enableGlassmorphism?: boolean;
    delay?: number;
}

/**
 * Animated Card with hover effects and glassmorphism option
 */
export const AnimatedCard: React.FC<AnimatedCardProps> = ({
    enableHover = true,
    enableGlassmorphism = false,
    delay = 0,
    style,
    children,
    ...props
}) => {
    const glassmorphismStyle = enableGlassmorphism
        ? {
            background: 'rgba(255, 255, 255, 0.7)',
            backdropFilter: 'blur(10px)',
            WebkitBackdropFilter: 'blur(10px)',
            border: '1px solid rgba(255, 255, 255, 0.2)',
        }
        : {};

    const hoverProps = enableHover
        ? {
            whileHover: cardHover.whileHover,
            whileTap: cardHover.whileTap,
        }
        : {};

    return (
        <motion.div
            variants={cardVariants}
            initial="hidden"
            animate="visible"
            transition={{ delay }}
            {...hoverProps}
            style={{ height: '100%' }}
        >
            <AntCard
                {...props}
                style={{
                    ...glassmorphismStyle,
                    ...style,
                    height: '100%',
                    transition: 'box-shadow 0.2s ease, transform 0.2s ease',
                }}
            >
                {children}
            </AntCard>
        </motion.div>
    );
};

interface StatCardProps {
    title: string;
    value: string | number;
    prefix?: React.ReactNode;
    suffix?: React.ReactNode;
    trend?: {
        value: number;
        direction: 'up' | 'down';
    };
    color?: 'primary' | 'success' | 'warning' | 'error';
    loading?: boolean;
    delay?: number;
}

/**
 * Animated statistic card with trend indicator
 */
export const StatCard: React.FC<StatCardProps> = ({
    title,
    value,
    prefix,
    suffix,
    trend,
    color = 'primary',
    loading = false,
    delay = 0,
}) => {
    const colorMap = {
        primary: '#1890ff',
        success: '#52c41a',
        warning: '#faad14',
        error: '#ff4d4f',
    };

    return (
        <motion.div
            variants={cardVariants}
            initial="hidden"
            animate="visible"
            transition={{ delay }}
            whileHover={cardHover.whileHover}
            style={{ height: '100%' }}
        >
            <AntCard
                loading={loading}
                style={{
                    height: '100%',
                    borderRadius: 12,
                    border: 'none',
                    boxShadow: '0 2px 8px rgba(0, 0, 0, 0.08)',
                }}
                bodyStyle={{ padding: 20 }}
            >
                <div style={{ marginBottom: 8 }}>
                    <span style={{ color: 'rgba(0, 0, 0, 0.45)', fontSize: 14 }}>{title}</span>
                </div>
                <div style={{ display: 'flex', alignItems: 'baseline', gap: 8 }}>
                    {prefix && (
                        <span style={{ color: colorMap[color], fontSize: 20 }}>{prefix}</span>
                    )}
                    <motion.span
                        key={value}
                        initial={{ opacity: 0, y: 10 }}
                        animate={{ opacity: 1, y: 0 }}
                        style={{
                            fontSize: 28,
                            fontWeight: 600,
                            color: colorMap[color],
                        }}
                    >
                        {value}
                    </motion.span>
                    {suffix && (
                        <span style={{ color: 'rgba(0, 0, 0, 0.45)', fontSize: 14 }}>{suffix}</span>
                    )}
                </div>
                {trend && (
                    <motion.div
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 1 }}
                        transition={{ delay: 0.2 }}
                        style={{
                            marginTop: 8,
                            display: 'flex',
                            alignItems: 'center',
                            gap: 4,
                        }}
                    >
                        <span
                            style={{
                                color: trend.direction === 'up' ? '#52c41a' : '#ff4d4f',
                                fontSize: 14,
                            }}
                        >
                            {trend.direction === 'up' ? '↑' : '↓'} {trend.value}%
                        </span>
                        <span style={{ color: 'rgba(0, 0, 0, 0.45)', fontSize: 12 }}>
                            vs last period
                        </span>
                    </motion.div>
                )}
            </AntCard>
        </motion.div>
    );
};

export default { AnimatedCard, StatCard };
