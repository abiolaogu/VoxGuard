import React from 'react';
import { Select, Space, Typography, Avatar, Tag } from 'antd';
import { BankOutlined } from '@ant-design/icons';

const { Text } = Typography;

// Nigerian Banks Data
export const NIGERIAN_BANKS = [
    { code: '044', name: 'Access Bank', shortName: 'Access', type: 'commercial' },
    { code: '063', name: 'Access Bank (Diamond)', shortName: 'Diamond', type: 'commercial' },
    { code: '050', name: 'Ecobank Nigeria', shortName: 'Ecobank', type: 'commercial' },
    { code: '070', name: 'Fidelity Bank', shortName: 'Fidelity', type: 'commercial' },
    { code: '011', name: 'First Bank of Nigeria', shortName: 'First Bank', type: 'commercial' },
    { code: '214', name: 'First City Monument Bank', shortName: 'FCMB', type: 'commercial' },
    { code: '058', name: 'Guaranty Trust Bank', shortName: 'GTBank', type: 'commercial' },
    { code: '030', name: 'Heritage Bank', shortName: 'Heritage', type: 'commercial' },
    { code: '301', name: 'Jaiz Bank', shortName: 'Jaiz', type: 'commercial' },
    { code: '082', name: 'Keystone Bank', shortName: 'Keystone', type: 'commercial' },
    { code: '101', name: 'Providus Bank', shortName: 'Providus', type: 'commercial' },
    { code: '076', name: 'Polaris Bank', shortName: 'Polaris', type: 'commercial' },
    { code: '221', name: 'Stanbic IBTC Bank', shortName: 'Stanbic', type: 'commercial' },
    { code: '068', name: 'Standard Chartered', shortName: 'StanChart', type: 'commercial' },
    { code: '232', name: 'Sterling Bank', shortName: 'Sterling', type: 'commercial' },
    { code: '032', name: 'Union Bank of Nigeria', shortName: 'Union Bank', type: 'commercial' },
    { code: '033', name: 'United Bank for Africa', shortName: 'UBA', type: 'commercial' },
    { code: '215', name: 'Unity Bank', shortName: 'Unity', type: 'commercial' },
    { code: '035', name: 'Wema Bank', shortName: 'Wema', type: 'commercial' },
    { code: '057', name: 'Zenith Bank', shortName: 'Zenith', type: 'commercial' },
    // Digital Banks
    { code: '999992', name: 'Kuda Bank', shortName: 'Kuda', type: 'digital' },
    { code: '999991', name: 'OPay', shortName: 'OPay', type: 'digital' },
    { code: '999990', name: 'PalmPay', shortName: 'PalmPay', type: 'digital' },
    { code: '999989', name: 'Moniepoint', shortName: 'Moniepoint', type: 'digital' },
    { code: '999988', name: 'Carbon', shortName: 'Carbon', type: 'digital' },
] as const;

export type NigerianBank = (typeof NIGERIAN_BANKS)[number];

interface NigerianBankSelectProps {
    value?: string;
    onChange?: (value: string, bank?: NigerianBank) => void;
    placeholder?: string;
    disabled?: boolean;
    showDigitalBanks?: boolean;
    style?: React.CSSProperties;
}

export const NigerianBankSelect: React.FC<NigerianBankSelectProps> = ({
    value,
    onChange,
    placeholder = 'Select a bank',
    disabled = false,
    showDigitalBanks = true,
    style,
}) => {
    const filteredBanks = showDigitalBanks
        ? NIGERIAN_BANKS
        : NIGERIAN_BANKS.filter((b) => b.type === 'commercial');

    const commercialBanks = filteredBanks.filter((b) => b.type === 'commercial');
    const digitalBanks = filteredBanks.filter((b) => b.type === 'digital');

    const handleChange = (code: string) => {
        const bank = NIGERIAN_BANKS.find((b) => b.code === code);
        onChange?.(code, bank);
    };

    return (
        <Select
            value={value}
            onChange={handleChange}
            placeholder={placeholder}
            disabled={disabled}
            style={{ width: '100%', ...style }}
            showSearch
            filterOption={(input, option) =>
                (option?.label as string)?.toLowerCase().includes(input.toLowerCase())
            }
            optionLabelProp="label"
        >
            <Select.OptGroup label="Commercial Banks">
                {commercialBanks.map((bank) => (
                    <Select.Option key={bank.code} value={bank.code} label={bank.name}>
                        <Space>
                            <Avatar
                                size="small"
                                style={{ backgroundColor: getBankColor(bank.shortName) }}
                                icon={<BankOutlined />}
                            />
                            <Text>{bank.name}</Text>
                            <Text type="secondary" style={{ fontSize: 12 }}>
                                ({bank.code})
                            </Text>
                        </Space>
                    </Select.Option>
                ))}
            </Select.OptGroup>
            {showDigitalBanks && (
                <Select.OptGroup label="Digital Banks">
                    {digitalBanks.map((bank) => (
                        <Select.Option key={bank.code} value={bank.code} label={bank.name}>
                            <Space>
                                <Avatar
                                    size="small"
                                    style={{ backgroundColor: getDigitalBankColor(bank.shortName) }}
                                    icon={<BankOutlined />}
                                />
                                <Text>{bank.name}</Text>
                                <Tag color="purple" style={{ fontSize: 10 }}>
                                    Digital
                                </Tag>
                            </Space>
                        </Select.Option>
                    ))}
                </Select.OptGroup>
            )}
        </Select>
    );
};

// Get bank brand colors
const getBankColor = (shortName: string): string => {
    const colors: Record<string, string> = {
        GTBank: '#E27B00',
        'First Bank': '#002D6A',
        Zenith: '#E30613',
        UBA: '#E30613',
        Access: '#F68B1E',
        FCMB: '#6C3C97',
        Fidelity: '#00A551',
        Stanbic: '#0033A0',
        Sterling: '#E31837',
        Ecobank: '#0066B3',
    };
    return colors[shortName] || '#1890ff';
};

const getDigitalBankColor = (shortName: string): string => {
    const colors: Record<string, string> = {
        Kuda: '#40196D',
        OPay: '#1DCF9F',
        PalmPay: '#8B5CF6',
        Moniepoint: '#0066FF',
        Carbon: '#00C853',
    };
    return colors[shortName] || '#722ed1';
};

export default NigerianBankSelect;
