import React from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Steps, Progress, Card, Typography, Space, Tag, Badge } from 'antd';
import {
    DollarOutlined,
    LoadingOutlined,
    CheckCircleOutlined,
    CloseCircleOutlined,
    BankOutlined,
    SendOutlined,
    ClockCircleOutlined,
} from '@ant-design/icons';
import { stepVariants, progressFill } from '@/theme/animations';

const { Text, Title } = Typography;

interface TransferProgressProps {
    currentStep: number;
    status?: 'process' | 'finish' | 'error' | 'wait';
    amount?: {
        sent: number;
        received: number;
        currencySent: string;
        currencyReceived: string;
    };
}

/**
 * Animated transfer progress indicator
 */
export const TransferProgress: React.FC<TransferProgressProps> = ({
    currentStep,
    status = 'process',
    amount,
}) => {
    const steps = [
        { title: 'Initiated', icon: <DollarOutlined /> },
        { title: 'Payment', icon: <BankOutlined /> },
        { title: 'Processing', icon: <LoadingOutlined /> },
        { title: 'Sent', icon: <SendOutlined /> },
        { title: 'Complete', icon: <CheckCircleOutlined /> },
    ];

    return (
        <Card
            style={{
                borderRadius: 12,
                overflow: 'hidden',
            }}
        >
            {amount && (
                <motion.div
                    initial={{ opacity: 0, y: -10 }}
                    animate={{ opacity: 1, y: 0 }}
                    style={{
                        textAlign: 'center',
                        marginBottom: 24,
                        padding: '16px 0',
                        background: 'linear-gradient(135deg, #f6ffed 0%, #e6f7ff 100%)',
                        borderRadius: 8,
                    }}
                >
                    <Space direction="vertical" size={4}>
                        <Text type="secondary">Converting</Text>
                        <Space size="large" align="center">
                            <motion.div
                                key={amount.sent}
                                initial={{ scale: 0.9 }}
                                animate={{ scale: 1 }}
                            >
                                <Title level={4} style={{ margin: 0, color: '#1890ff' }}>
                                    {amount.currencySent} {amount.sent.toLocaleString()}
                                </Title>
                            </motion.div>
                            <motion.div
                                animate={{ x: [0, 5, 0] }}
                                transition={{ duration: 1, repeat: Infinity }}
                            >
                                →
                            </motion.div>
                            <motion.div
                                key={amount.received}
                                initial={{ scale: 0.9 }}
                                animate={{ scale: 1 }}
                            >
                                <Title level={4} style={{ margin: 0, color: '#52c41a' }}>
                                    ₦{amount.received.toLocaleString()}
                                </Title>
                            </motion.div>
                        </Space>
                    </Space>
                </motion.div>
            )}

            <Steps
                current={currentStep}
                status={status}
                items={steps.map((step, index) => ({
                    title: (
                        <motion.span
                            initial={false}
                            animate={{
                                fontWeight: index === currentStep ? 600 : 400,
                                color: index <= currentStep ? '#1890ff' : 'rgba(0,0,0,0.45)',
                            }}
                        >
                            {step.title}
                        </motion.span>
                    ),
                    icon: (
                        <motion.div
                            variants={stepVariants}
                            animate={
                                index < currentStep
                                    ? 'complete'
                                    : index === currentStep
                                        ? 'active'
                                        : 'inactive'
                            }
                            style={{
                                display: 'flex',
                                alignItems: 'center',
                                justifyContent: 'center',
                            }}
                        >
                            {index === currentStep && status === 'process' ? (
                                <LoadingOutlined spin />
                            ) : (
                                step.icon
                            )}
                        </motion.div>
                    ),
                }))}
            />

            <motion.div
                initial={{ width: 0 }}
                animate={{ width: `${(currentStep / (steps.length - 1)) * 100}%` }}
                transition={{ duration: 0.5, ease: 'easeOut' }}
                style={{
                    height: 4,
                    background: 'linear-gradient(90deg, #1890ff, #52c41a)',
                    borderRadius: 2,
                    marginTop: 16,
                }}
            />
        </Card>
    );
};

interface ExchangeRateDisplayProps {
    sourceCurrency: string;
    targetCurrency: string;
    rate: number;
    lastUpdated?: Date;
    loading?: boolean;
}

/**
 * Animated exchange rate display with live updates
 */
export const ExchangeRateDisplay: React.FC<ExchangeRateDisplayProps> = ({
    sourceCurrency,
    targetCurrency,
    rate,
    lastUpdated,
    loading = false,
}) => {
    return (
        <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            style={{
                padding: 16,
                background: 'linear-gradient(135deg, #e6f7ff 0%, #f0f5ff 100%)',
                borderRadius: 8,
                textAlign: 'center',
            }}
        >
            <Space direction="vertical" size={4}>
                <Text type="secondary">Exchange Rate</Text>
                <Space align="baseline">
                    <Text style={{ fontSize: 14 }}>1 {sourceCurrency}</Text>
                    <Text type="secondary">=</Text>
                    <AnimatePresence mode="wait">
                        <motion.span
                            key={rate}
                            initial={{ opacity: 0, y: -10 }}
                            animate={{ opacity: 1, y: 0 }}
                            exit={{ opacity: 0, y: 10 }}
                            style={{ fontSize: 20, fontWeight: 600, color: '#1890ff' }}
                        >
                            {loading ? '...' : rate.toLocaleString()}
                        </motion.span>
                    </AnimatePresence>
                    <Text style={{ fontSize: 14 }}>{targetCurrency}</Text>
                </Space>
                {lastUpdated && (
                    <Space size={4}>
                        <ClockCircleOutlined style={{ fontSize: 10 }} />
                        <Text type="secondary" style={{ fontSize: 11 }}>
                            Updated {lastUpdated.toLocaleTimeString()}
                        </Text>
                    </Space>
                )}
            </Space>
        </motion.div>
    );
};

interface SuccessConfettiProps {
    show: boolean;
    message?: string;
    amount?: string;
}

/**
 * Success celebration with confetti animation
 */
export const SuccessConfetti: React.FC<SuccessConfettiProps> = ({
    show,
    message = 'Transfer Complete!',
    amount,
}) => {
    const confettiColors = ['#ff4d4f', '#faad14', '#52c41a', '#1890ff', '#722ed1'];
    const particles = Array.from({ length: 30 });

    return (
        <AnimatePresence>
            {show && (
                <motion.div
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                    exit={{ opacity: 0 }}
                    style={{
                        position: 'fixed',
                        inset: 0,
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        background: 'rgba(0, 0, 0, 0.6)',
                        zIndex: 1000,
                    }}
                >
                    {/* Confetti particles */}
                    {particles.map((_, i) => (
                        <motion.div
                            key={i}
                            initial={{
                                opacity: 1,
                                x: 0,
                                y: 0,
                                scale: 1,
                                rotate: 0,
                            }}
                            animate={{
                                opacity: [1, 1, 0],
                                y: [0, -150 - Math.random() * 100, 300],
                                x: (Math.random() - 0.5) * 400,
                                rotate: Math.random() * 720 - 360,
                                scale: [1, 1.2, 0.5],
                            }}
                            transition={{
                                duration: 1.5 + Math.random() * 0.5,
                                ease: 'easeOut',
                            }}
                            style={{
                                position: 'absolute',
                                width: 8 + Math.random() * 8,
                                height: 8 + Math.random() * 8,
                                backgroundColor: confettiColors[Math.floor(Math.random() * confettiColors.length)],
                                borderRadius: Math.random() > 0.5 ? '50%' : 2,
                            }}
                        />
                    ))}

                    {/* Success message */}
                    <motion.div
                        initial={{ scale: 0, rotate: -10 }}
                        animate={{ scale: 1, rotate: 0 }}
                        transition={{ type: 'spring', stiffness: 400, damping: 20, delay: 0.2 }}
                        style={{
                            background: '#fff',
                            borderRadius: 16,
                            padding: 32,
                            textAlign: 'center',
                            boxShadow: '0 20px 60px rgba(0, 0, 0, 0.3)',
                        }}
                    >
                        <motion.div
                            animate={{ scale: [1, 1.1, 1] }}
                            transition={{ duration: 0.5, delay: 0.5 }}
                        >
                            <CheckCircleOutlined
                                style={{ fontSize: 64, color: '#52c41a' }}
                            />
                        </motion.div>
                        <Title level={3} style={{ marginTop: 16, marginBottom: 8 }}>
                            {message}
                        </Title>
                        {amount && (
                            <motion.div
                                initial={{ opacity: 0, y: 10 }}
                                animate={{ opacity: 1, y: 0 }}
                                transition={{ delay: 0.7 }}
                            >
                                <Text style={{ fontSize: 24, fontWeight: 600, color: '#52c41a' }}>
                                    {amount}
                                </Text>
                            </motion.div>
                        )}
                    </motion.div>
                </motion.div>
            )}
        </AnimatePresence>
    );
};

export default { TransferProgress, ExchangeRateDisplay, SuccessConfetti };
