import React from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Alert, Badge, Tag, Typography, Space, Button } from 'antd';
import {
    AlertOutlined,
    CheckCircleOutlined,
    CloseCircleOutlined,
    ExclamationCircleOutlined,
    SoundOutlined,
} from '@ant-design/icons';
import { alertPulse, alertShake } from '@/theme/animations';

const { Text } = Typography;

interface MaskingAlertProps {
    detected: boolean;
    bNumber?: string;
    score?: number;
    onAcknowledge?: () => void;
    onDismiss?: () => void;
    enableSound?: boolean;
}

/**
 * Call Masking Detection Alert with pulsing animation
 */
export const MaskingAlert: React.FC<MaskingAlertProps> = ({
    detected,
    bNumber,
    score = 0,
    onAcknowledge,
    onDismiss,
    enableSound = false,
}) => {
    const audioRef = React.useRef<HTMLAudioElement | null>(null);

    React.useEffect(() => {
        if (detected && enableSound && audioRef.current) {
            audioRef.current.play().catch(() => {
                // Audio play prevented by browser
            });
        }
    }, [detected, enableSound]);

    return (
        <AnimatePresence mode="wait">
            {detected ? (
                <motion.div
                    key="alert"
                    initial={{ opacity: 0, scale: 0.9, y: -20 }}
                    animate={{ opacity: 1, scale: 1, y: 0 }}
                    exit={{ opacity: 0, scale: 0.9, y: -20 }}
                    transition={{ type: 'spring', stiffness: 400, damping: 25 }}
                >
                    <motion.div
                        variants={alertPulse}
                        initial="initial"
                        animate="pulse"
                    >
                        <Alert
                            type="error"
                            showIcon
                            icon={
                                <motion.div
                                    animate={{ rotate: [0, -10, 10, -10, 0] }}
                                    transition={{ duration: 0.5, repeat: Infinity, repeatDelay: 2 }}
                                >
                                    <AlertOutlined style={{ fontSize: 24 }} />
                                </motion.div>
                            }
                            message={
                                <Space>
                                    <Text strong style={{ fontSize: 16, color: '#ff4d4f' }}>
                                        CLI Masking Detected!
                                    </Text>
                                    <Badge
                                        count={`${(score * 100).toFixed(0)}%`}
                                        style={{ backgroundColor: '#ff4d4f' }}
                                    />
                                </Space>
                            }
                            description={
                                <Space direction="vertical" size={8}>
                                    <Text>
                                        Suspicious activity detected on B-Number: <Text code>{bNumber}</Text>
                                    </Text>
                                    <Space>
                                        <Button
                                            type="primary"
                                            danger
                                            size="small"
                                            onClick={onAcknowledge}
                                        >
                                            Acknowledge
                                        </Button>
                                        <Button size="small" onClick={onDismiss}>
                                            Dismiss
                                        </Button>
                                        {enableSound && (
                                            <Button
                                                type="text"
                                                size="small"
                                                icon={<SoundOutlined />}
                                                onClick={() => audioRef.current?.play()}
                                            />
                                        )}
                                    </Space>
                                </Space>
                            }
                            style={{
                                borderRadius: 12,
                                border: '2px solid #ff4d4f',
                                boxShadow: '0 4px 16px rgba(255, 77, 79, 0.3)',
                            }}
                        />
                    </motion.div>
                    {enableSound && (
                        <audio ref={audioRef} preload="auto">
                            <source src="/sounds/alert.mp3" type="audio/mpeg" />
                        </audio>
                    )}
                </motion.div>
            ) : (
                <motion.div
                    key="verified"
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                    exit={{ opacity: 0 }}
                >
                    <Alert
                        type="success"
                        showIcon
                        icon={<CheckCircleOutlined style={{ fontSize: 20 }} />}
                        message="CLI Verified"
                        description="No masking detected. Call origin verified."
                        style={{
                            borderRadius: 12,
                            border: '1px solid #b7eb8f',
                        }}
                    />
                </motion.div>
            )}
        </AnimatePresence>
    );
};

interface SeverityBadgeProps {
    severity: 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';
    pulse?: boolean;
    size?: 'small' | 'default';
}

/**
 * Animated severity badge with optional pulse
 */
export const SeverityBadge: React.FC<SeverityBadgeProps> = ({
    severity,
    pulse = false,
    size = 'default',
}) => {
    const colorMap = {
        LOW: '#1890ff',
        MEDIUM: '#faad14',
        HIGH: '#fa8c16',
        CRITICAL: '#ff4d4f',
    };

    const BadgeContent = (
        <Tag
            color={colorMap[severity]}
            style={{
                borderRadius: 4,
                fontWeight: 500,
                fontSize: size === 'small' ? 11 : 12,
                padding: size === 'small' ? '0 6px' : '2px 10px',
            }}
        >
            {severity}
        </Tag>
    );

    if (pulse && severity === 'CRITICAL') {
        return (
            <motion.span
                animate={{
                    scale: [1, 1.1, 1],
                    opacity: [1, 0.8, 1],
                }}
                transition={{
                    duration: 1,
                    repeat: Infinity,
                }}
            >
                {BadgeContent}
            </motion.span>
        );
    }

    return BadgeContent;
};

interface FraudScoreIndicatorProps {
    score: number;
    showLabel?: boolean;
    size?: 'small' | 'default' | 'large';
    animated?: boolean;
}

/**
 * Animated fraud score indicator with color gradient
 */
export const FraudScoreIndicator: React.FC<FraudScoreIndicatorProps> = ({
    score,
    showLabel = true,
    size = 'default',
    animated = true,
}) => {
    const percentage = score * 100;

    const getColor = () => {
        if (percentage >= 80) return '#ff4d4f';
        if (percentage >= 60) return '#fa8c16';
        if (percentage >= 40) return '#faad14';
        return '#52c41a';
    };

    const sizeMap = {
        small: { width: 40, height: 4, fontSize: 11 },
        default: { width: 60, height: 6, fontSize: 13 },
        large: { width: 80, height: 8, fontSize: 16 },
    };

    const { width, height, fontSize } = sizeMap[size];

    return (
        <Space direction="vertical" size={2} align="center">
            <motion.span
                key={score}
                initial={animated ? { opacity: 0, scale: 0.8 } : false}
                animate={animated ? { opacity: 1, scale: 1 } : false}
                style={{
                    color: getColor(),
                    fontWeight: 600,
                    fontSize,
                }}
            >
                {percentage.toFixed(0)}%
            </motion.span>
            <div
                style={{
                    width,
                    height,
                    backgroundColor: '#f0f0f0',
                    borderRadius: height / 2,
                    overflow: 'hidden',
                }}
            >
                <motion.div
                    initial={animated ? { width: 0 } : false}
                    animate={{ width: `${percentage}%` }}
                    transition={{ duration: 0.8, ease: [0.215, 0.61, 0.355, 1] }}
                    style={{
                        height: '100%',
                        backgroundColor: getColor(),
                        borderRadius: height / 2,
                    }}
                />
            </div>
            {showLabel && (
                <Text type="secondary" style={{ fontSize: 10 }}>
                    Risk Score
                </Text>
            )}
        </Space>
    );
};

export default { MaskingAlert, SeverityBadge, FraudScoreIndicator };
