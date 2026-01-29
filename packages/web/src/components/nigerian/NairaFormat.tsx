import React, { useState, useCallback } from 'react';
import { Space, Typography, Tooltip, Input, InputProps } from 'antd';

const { Text } = Typography;

/**
 * Format number as Nigerian Naira
 */
export const formatNaira = (
    amount: number,
    options?: {
        showSymbol?: boolean;
        showCode?: boolean;
        decimals?: number;
    }
): string => {
    const { showSymbol = true, showCode = false, decimals = 2 } = options || {};

    const formatted = amount.toLocaleString('en-NG', {
        minimumFractionDigits: decimals,
        maximumFractionDigits: decimals,
    });

    if (showSymbol && showCode) {
        return `₦${formatted} NGN`;
    }
    if (showSymbol) {
        return `₦${formatted}`;
    }
    if (showCode) {
        return `${formatted} NGN`;
    }
    return formatted;
};

/**
 * Parse Naira string to number
 */
export const parseNaira = (value: string): number => {
    const cleaned = value.replace(/[₦,\s]/g, '');
    return parseFloat(cleaned) || 0;
};

interface NairaDisplayProps {
    amount: number;
    size?: 'small' | 'default' | 'large';
    type?: 'default' | 'success' | 'warning' | 'danger';
    showKobo?: boolean;
    abbrev?: boolean;
}

/**
 * Display amount as Nigerian Naira
 */
export const NairaDisplay: React.FC<NairaDisplayProps> = ({
    amount,
    size = 'default',
    type = 'default',
    showKobo = true,
    abbrev = false,
}) => {
    const getAbbreviated = () => {
        if (amount >= 1_000_000_000) {
            return `${(amount / 1_000_000_000).toFixed(1)}B`;
        }
        if (amount >= 1_000_000) {
            return `${(amount / 1_000_000).toFixed(1)}M`;
        }
        if (amount >= 1_000) {
            return `${(amount / 1_000).toFixed(1)}K`;
        }
        return amount.toString();
    };

    const colorMap = {
        default: undefined,
        success: '#52c41a',
        warning: '#faad14',
        danger: '#ff4d4f',
    };

    const sizeMap = {
        small: 12,
        default: 14,
        large: 24,
    };

    const displayValue = abbrev ? getAbbreviated() : formatNaira(amount, { decimals: showKobo ? 2 : 0 });

    return (
        <Tooltip title={formatNaira(amount)}>
            <Text
                style={{
                    fontSize: sizeMap[size],
                    fontWeight: size === 'large' ? 600 : 400,
                    color: colorMap[type],
                }}
            >
                {displayValue}
            </Text>
        </Tooltip>
    );
};

interface NairaInputProps extends Omit<InputProps, 'onChange' | 'value'> {
    value?: number;
    onChange?: (value: number) => void;
    showSymbol?: boolean;
}

/**
 * Input for Nigerian Naira amounts
 */
export const NairaInput: React.FC<NairaInputProps> = ({
    value = 0,
    onChange,
    showSymbol = true,
    ...props
}) => {
    const [displayValue, setDisplayValue] = useState(
        value > 0 ? value.toLocaleString('en-NG') : ''
    );

    const handleChange = useCallback(
        (e: React.ChangeEvent<HTMLInputElement>) => {
            const raw = e.target.value.replace(/[^0-9.]/g, '');
            const numeric = parseFloat(raw) || 0;

            // Format with commas
            const formatted = raw === '' ? '' : numeric.toLocaleString('en-NG');
            setDisplayValue(formatted);
            onChange?.(numeric);
        },
        [onChange]
    );

    const handleBlur = useCallback(() => {
        if (displayValue === '') {
            setDisplayValue('');
            onChange?.(0);
        }
    }, [displayValue, onChange]);

    return (
        <Input
            {...props}
            value={displayValue}
            onChange={handleChange}
            onBlur={handleBlur}
            prefix={showSymbol ? '₦' : undefined}
            style={{ textAlign: 'right', ...props.style }}
        />
    );
};

interface NairaRangeProps {
    min: number;
    max: number;
    separator?: string;
}

/**
 * Display a Naira range
 */
export const NairaRange: React.FC<NairaRangeProps> = ({
    min,
    max,
    separator = ' - ',
}) => (
    <Text>
        {formatNaira(min, { decimals: 0 })}
        {separator}
        {formatNaira(max, { decimals: 0 })}
    </Text>
);

export default { NairaDisplay, NairaInput, NairaRange, formatNaira, parseNaira };
