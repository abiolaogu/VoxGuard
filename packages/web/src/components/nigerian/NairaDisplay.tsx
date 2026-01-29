import React from 'react';
import { Typography, Statistic, StatisticProps } from 'antd';

const { Text } = Typography;

// Currency formatter options
interface FormatNairaOptions {
    decimals?: number;
    symbol?: string;
    symbolPosition?: 'before' | 'after';
}

/**
 * Format number as Nigerian Naira currency
 */
export const formatNaira = (
    amount: number | string | null | undefined,
    options: FormatNairaOptions = {}
): string => {
    const {
        decimals = 2,
        symbol = '₦',
        symbolPosition = 'before'
    } = options;

    if (amount === null || amount === undefined) {
        return `${symbol}0`;
    }

    const numAmount = typeof amount === 'string' ? parseFloat(amount) : amount;

    if (isNaN(numAmount)) {
        return `${symbol}0`;
    }

    const formatted = numAmount.toLocaleString('en-NG', {
        minimumFractionDigits: decimals,
        maximumFractionDigits: decimals,
    });

    return symbolPosition === 'before'
        ? `${symbol}${formatted}`
        : `${formatted}${symbol}`;
};

// Naira Display Props
interface NairaDisplayProps extends Omit<StatisticProps, 'value' | 'prefix'> {
    amount: number | string | null | undefined;
    size?: 'small' | 'default' | 'large';
    showSymbol?: boolean;
    decimals?: number;
    color?: string;
}

/**
 * Display Naira amount with Nigerian formatting
 */
export const NairaDisplay: React.FC<NairaDisplayProps> = ({
    amount,
    size = 'default',
    showSymbol = true,
    decimals = 2,
    color,
    ...rest
}) => {
    const numAmount = typeof amount === 'string' ? parseFloat(amount || '0') : (amount || 0);

    const fontSize = {
        small: 14,
        default: 24,
        large: 32,
    }[size];

    return (
        <Statistic
            value={numAmount}
            precision={decimals}
            prefix={showSymbol ? '₦' : undefined}
            valueStyle={{
                fontSize,
                color: color || (numAmount >= 0 ? '#52c41a' : '#cf1322'),
                fontWeight: size === 'large' ? 700 : 500,
            }}
            {...rest}
        />
    );
};

// Simple text Naira display
interface NairaTextProps {
    amount: number | string | null | undefined;
    decimals?: number;
    type?: 'default' | 'success' | 'danger' | 'warning' | 'secondary';
    strong?: boolean;
}

export const NairaText: React.FC<NairaTextProps> = ({
    amount,
    decimals = 2,
    type = 'default',
    strong = false,
}) => {
    return (
        <Text type={type === 'default' ? undefined : type} strong={strong}>
            {formatNaira(amount, { decimals })}
        </Text>
    );
};

export default NairaDisplay;
