import React from 'react';
import { Typography, Space, Tooltip } from 'antd';
import { SwapOutlined, ArrowRightOutlined } from '@ant-design/icons';

const { Text } = Typography;

// Currency symbols and flags
export const CURRENCIES = {
    NGN: { symbol: '₦', name: 'Nigerian Naira', flag: '🇳🇬' },
    USD: { symbol: '$', name: 'US Dollar', flag: '🇺🇸' },
    GBP: { symbol: '£', name: 'British Pound', flag: '🇬🇧' },
    EUR: { symbol: '€', name: 'Euro', flag: '🇪🇺' },
    CAD: { symbol: 'C$', name: 'Canadian Dollar', flag: '🇨🇦' },
    ZAR: { symbol: 'R', name: 'South African Rand', flag: '🇿🇦' },
    AED: { symbol: 'د.إ', name: 'UAE Dirham', flag: '🇦🇪' },
} as const;

export type CurrencyCode = keyof typeof CURRENCIES;

interface NairaDisplayProps {
    amount: number;
    showSymbol?: boolean;
    showFlag?: boolean;
    size?: 'small' | 'default' | 'large';
    decimals?: number;
    style?: React.CSSProperties;
}

export const NairaDisplay: React.FC<NairaDisplayProps> = ({
    amount,
    showSymbol = true,
    showFlag = false,
    size = 'default',
    decimals = 2,
    style,
}) => {
    const formattedAmount = new Intl.NumberFormat('en-NG', {
        minimumFractionDigits: decimals,
        maximumFractionDigits: decimals,
    }).format(amount);

    const fontSize = size === 'small' ? 12 : size === 'large' ? 24 : 14;

    return (
        <Text style={{ fontSize, ...style }}>
            {showFlag && '🇳🇬 '}
            {showSymbol && <Text strong style={{ color: '#52c41a' }}>₦</Text>}
            {formattedAmount}
        </Text>
    );
};

interface CurrencyDisplayProps {
    amount: number;
    currency: CurrencyCode;
    showSymbol?: boolean;
    showFlag?: boolean;
    size?: 'small' | 'default' | 'large';
    decimals?: number;
    style?: React.CSSProperties;
}

export const CurrencyDisplay: React.FC<CurrencyDisplayProps> = ({
    amount,
    currency,
    showSymbol = true,
    showFlag = false,
    size = 'default',
    decimals = 2,
    style,
}) => {
    const currencyInfo = CURRENCIES[currency];

    const formattedAmount = new Intl.NumberFormat('en-US', {
        minimumFractionDigits: decimals,
        maximumFractionDigits: decimals,
    }).format(amount);

    const fontSize = size === 'small' ? 12 : size === 'large' ? 24 : 14;

    return (
        <Text style={{ fontSize, ...style }}>
            {showFlag && `${currencyInfo.flag} `}
            {showSymbol && <Text strong>{currencyInfo.symbol}</Text>}
            {formattedAmount}
        </Text>
    );
};

interface ExchangeRateDisplayProps {
    sourceCurrency: CurrencyCode;
    targetCurrency: CurrencyCode;
    rate: number;
    inverse?: boolean;
    showFlags?: boolean;
    style?: React.CSSProperties;
}

export const ExchangeRateDisplay: React.FC<ExchangeRateDisplayProps> = ({
    sourceCurrency,
    targetCurrency,
    rate,
    inverse = false,
    showFlags = true,
    style,
}) => {
    const sourceInfo = CURRENCIES[sourceCurrency];
    const targetInfo = CURRENCIES[targetCurrency];

    const displayRate = inverse ? 1 / rate : rate;
    const formattedRate = new Intl.NumberFormat('en-US', {
        minimumFractionDigits: 2,
        maximumFractionDigits: 2,
    }).format(displayRate);

    return (
        <Tooltip title={`Exchange rate as of now`}>
            <Space style={style}>
                <Text>
                    {showFlags && sourceInfo.flag} 1 {sourceInfo.symbol}
                </Text>
                <ArrowRightOutlined />
                <Text strong style={{ color: '#1890ff' }}>
                    {showFlags && targetInfo.flag} {formattedRate} {targetInfo.symbol}
                </Text>
            </Space>
        </Tooltip>
    );
};

interface RemittanceConversionProps {
    sourceAmount: number;
    sourceCurrency: CurrencyCode;
    targetAmount: number;
    targetCurrency: CurrencyCode;
    rate: number;
    fee?: number;
    style?: React.CSSProperties;
}

export const RemittanceConversion: React.FC<RemittanceConversionProps> = ({
    sourceAmount,
    sourceCurrency,
    targetAmount,
    targetCurrency,
    rate,
    fee,
    style,
}) => {
    const sourceInfo = CURRENCIES[sourceCurrency];
    const targetInfo = CURRENCIES[targetCurrency];

    return (
        <div style={{ padding: 16, background: '#f5f5f5', borderRadius: 8, ...style }}>
            <Space direction="vertical" style={{ width: '100%' }}>
                <Space style={{ width: '100%', justifyContent: 'space-between' }}>
                    <Text type="secondary">You send</Text>
                    <Text strong style={{ fontSize: 18 }}>
                        {sourceInfo.flag} {sourceInfo.symbol}
                        {sourceAmount.toLocaleString('en-US', { minimumFractionDigits: 2 })}
                    </Text>
                </Space>

                {fee !== undefined && fee > 0 && (
                    <Space style={{ width: '100%', justifyContent: 'space-between' }}>
                        <Text type="secondary">Fee</Text>
                        <Text>
                            {sourceInfo.symbol}
                            {fee.toLocaleString('en-US', { minimumFractionDigits: 2 })}
                        </Text>
                    </Space>
                )}

                <div style={{ textAlign: 'center', margin: '8px 0' }}>
                    <SwapOutlined style={{ fontSize: 20, color: '#1890ff' }} />
                    <br />
                    <Text type="secondary" style={{ fontSize: 12 }}>
                        1 {sourceInfo.symbol} = {rate.toLocaleString()} {targetInfo.symbol}
                    </Text>
                </div>

                <Space style={{ width: '100%', justifyContent: 'space-between' }}>
                    <Text type="secondary">They receive</Text>
                    <Text strong style={{ fontSize: 24, color: '#52c41a' }}>
                        {targetInfo.flag} {targetInfo.symbol}
                        {targetAmount.toLocaleString('en-NG', { minimumFractionDigits: 2 })}
                    </Text>
                </Space>
            </Space>
        </div>
    );
};

export default { NairaDisplay, CurrencyDisplay, ExchangeRateDisplay, RemittanceConversion };
