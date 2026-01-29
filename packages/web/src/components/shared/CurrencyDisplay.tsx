import React from 'react';
import { Typography, Space, Tooltip } from 'antd';

const { Text } = Typography;

interface CurrencyDisplayProps {
    amount: number;
    currency: string;
    showSymbol?: boolean;
    showCode?: boolean;
    size?: 'small' | 'default' | 'large';
    type?: 'default' | 'success' | 'warning' | 'danger' | 'secondary';
    precision?: number;
}

const currencySymbols: Record<string, string> = {
    NGN: '₦',
    USD: '$',
    GBP: '£',
    EUR: '€',
    CAD: 'CA$',
    AUD: 'A$',
};

const currencyFlags: Record<string, string> = {
    NGN: '🇳🇬',
    USD: '🇺🇸',
    GBP: '🇬🇧',
    EUR: '🇪🇺',
    CAD: '🇨🇦',
    AUD: '🇦🇺',
};

export const CurrencyDisplay: React.FC<CurrencyDisplayProps> = ({
    amount,
    currency,
    showSymbol = true,
    showCode = false,
    size = 'default',
    type = 'default',
    precision = 2,
}) => {
    const symbol = currencySymbols[currency] || currency;
    const flag = currencyFlags[currency] || '';

    const formattedAmount = amount.toLocaleString(undefined, {
        minimumFractionDigits: precision,
        maximumFractionDigits: precision,
    });

    const fontSize = size === 'large' ? 20 : size === 'small' ? 12 : 14;
    const fontWeight = size === 'large' ? 600 : 400;

    const getColor = () => {
        switch (type) {
            case 'success':
                return '#52c41a';
            case 'warning':
                return '#faad14';
            case 'danger':
                return '#ff4d4f';
            case 'secondary':
                return 'rgba(0,0,0,0.45)';
            default:
                return undefined;
        }
    };

    const displayValue = showSymbol ? `${symbol}${formattedAmount}` : formattedAmount;
    const tooltipContent = `${currency} ${formattedAmount}`;

    return (
        <Tooltip title={tooltipContent}>
            <Space size={4}>
                {flag && <span>{flag}</span>}
                <Text style={{ fontSize, fontWeight, color: getColor() }}>
                    {displayValue}
                </Text>
                {showCode && (
                    <Text type="secondary" style={{ fontSize: fontSize - 2 }}>
                        {currency}
                    </Text>
                )}
            </Space>
        </Tooltip>
    );
};

export default CurrencyDisplay;
