import React from 'react';
import { Result, Button, Typography, Space } from 'antd';
import {
    FrownOutlined,
    FileSearchOutlined,
    InboxOutlined,
    DisconnectOutlined,
    LockOutlined,
} from '@ant-design/icons';

const { Text } = Typography;

interface EmptyStateProps {
    type?: 'default' | 'search' | 'data' | 'error' | 'offline' | 'access';
    title?: string;
    description?: string;
    action?: {
        label: string;
        onClick: () => void;
    };
    secondaryAction?: {
        label: string;
        onClick: () => void;
    };
}

const emptyStateConfig = {
    default: {
        icon: <InboxOutlined style={{ fontSize: 64, color: '#bfbfbf' }} />,
        title: 'No Data',
        description: 'There are no items to display at this time.',
    },
    search: {
        icon: <FileSearchOutlined style={{ fontSize: 64, color: '#bfbfbf' }} />,
        title: 'No Results Found',
        description: 'Try adjusting your search or filters to find what you\'re looking for.',
    },
    data: {
        icon: <InboxOutlined style={{ fontSize: 64, color: '#bfbfbf' }} />,
        title: 'No Data Available',
        description: 'Start by adding some data to see it here.',
    },
    error: {
        icon: <FrownOutlined style={{ fontSize: 64, color: '#ff4d4f' }} />,
        title: 'Something Went Wrong',
        description: 'We encountered an error while loading this content.',
    },
    offline: {
        icon: <DisconnectOutlined style={{ fontSize: 64, color: '#faad14' }} />,
        title: 'You\'re Offline',
        description: 'Please check your internet connection and try again.',
    },
    access: {
        icon: <LockOutlined style={{ fontSize: 64, color: '#ff4d4f' }} />,
        title: 'Access Denied',
        description: 'You don\'t have permission to view this content.',
    },
};

/**
 * Customizable empty state component with illustrations
 */
export const EmptyState: React.FC<EmptyStateProps> = ({
    type = 'default',
    title,
    description,
    action,
    secondaryAction,
}) => {
    const config = emptyStateConfig[type];

    return (
        <div
            style={{
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                justifyContent: 'center',
                padding: '48px 24px',
                textAlign: 'center',
            }}
        >
            {config.icon}
            <Text
                strong
                style={{
                    fontSize: 18,
                    marginTop: 24,
                    marginBottom: 8,
                    display: 'block',
                }}
            >
                {title || config.title}
            </Text>
            <Text
                type="secondary"
                style={{
                    maxWidth: 400,
                    marginBottom: action ? 24 : 0,
                }}
            >
                {description || config.description}
            </Text>
            {(action || secondaryAction) && (
                <Space style={{ marginTop: 16 }}>
                    {action && (
                        <Button type="primary" onClick={action.onClick}>
                            {action.label}
                        </Button>
                    )}
                    {secondaryAction && (
                        <Button onClick={secondaryAction.onClick}>
                            {secondaryAction.label}
                        </Button>
                    )}
                </Space>
            )}
        </div>
    );
};

interface NoFraudAlertsProps {
    onRefresh?: () => void;
}

/**
 * Empty state specifically for no fraud alerts
 */
export const NoFraudAlerts: React.FC<NoFraudAlertsProps> = ({ onRefresh }) => (
    <EmptyState
        title="All Clear! 🎉"
        description="No fraud alerts detected. Your network is secure."
        action={
            onRefresh
                ? {
                    label: 'Refresh',
                    onClick: onRefresh,
                }
                : undefined
        }
    />
);

interface NoTransactionsProps {
    onCreateTransfer?: () => void;
}

/**
 * Empty state for no transactions
 */
export const NoTransactions: React.FC<NoTransactionsProps> = ({ onCreateTransfer }) => (
    <EmptyState
        type="data"
        title="No Transactions Yet"
        description="Send money to Nigeria with competitive rates and real-time tracking."
        action={
            onCreateTransfer
                ? {
                    label: 'Send Money',
                    onClick: onCreateTransfer,
                }
                : undefined
        }
    />
);

interface NoBeneficiariesProps {
    onAddBeneficiary?: () => void;
}

/**
 * Empty state for no beneficiaries
 */
export const NoBeneficiaries: React.FC<NoBeneficiariesProps> = ({ onAddBeneficiary }) => (
    <EmptyState
        type="data"
        title="No Beneficiaries Added"
        description="Add your first beneficiary to start sending money quickly."
        action={
            onAddBeneficiary
                ? {
                    label: 'Add Beneficiary',
                    onClick: onAddBeneficiary,
                }
                : undefined
        }
    />
);

export default { EmptyState, NoFraudAlerts, NoTransactions, NoBeneficiaries };
