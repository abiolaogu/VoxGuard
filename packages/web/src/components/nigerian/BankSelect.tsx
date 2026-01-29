import React, { useMemo } from 'react';
import { Select, Space, Avatar, Typography, Tooltip, SelectProps } from 'antd';
import { BankOutlined } from '@ant-design/icons';

const { Text } = Typography;

/**
 * Nigerian banks with codes
 */
export const nigerianBanks = [
    { code: '044', name: 'Access Bank', shortName: 'Access', color: '#F68B1E' },
    { code: '023', name: 'Citibank Nigeria', shortName: 'Citibank', color: '#003DA5' },
    { code: '050', name: 'Ecobank Nigeria', shortName: 'Ecobank', color: '#009639' },
    { code: '070', name: 'Fidelity Bank', shortName: 'Fidelity', color: '#2E3192' },
    { code: '011', name: 'First Bank of Nigeria', shortName: 'First Bank', color: '#002D72' },
    { code: '214', name: 'First City Monument Bank', shortName: 'FCMB', color: '#691D72' },
    { code: '058', name: 'Guaranty Trust Bank', shortName: 'GTBank', color: '#E37021' },
    { code: '030', name: 'Heritage Bank', shortName: 'Heritage', color: '#C41230' },
    { code: '301', name: 'Jaiz Bank', shortName: 'Jaiz', color: '#006838' },
    { code: '082', name: 'Keystone Bank', shortName: 'Keystone', color: '#00529B' },
    { code: '101', name: 'Providus Bank', shortName: 'Providus', color: '#EE2E24' },
    { code: '076', name: 'Polaris Bank', shortName: 'Polaris', color: '#542488' },
    { code: '039', name: 'Stanbic IBTC Bank', shortName: 'Stanbic', color: '#004A8F' },
    { code: '232', name: 'Sterling Bank', shortName: 'Sterling', color: '#D70A3E' },
    { code: '032', name: 'Union Bank of Nigeria', shortName: 'Union Bank', color: '#003366' },
    { code: '033', name: 'United Bank for Africa', shortName: 'UBA', color: '#E4002B' },
    { code: '215', name: 'Unity Bank', shortName: 'Unity', color: '#006633' },
    { code: '035', name: 'Wema Bank', shortName: 'Wema', color: '#722F37' },
    { code: '057', name: 'Zenith Bank', shortName: 'Zenith', color: '#C41230' },
    { code: '100', name: 'Kuda Bank', shortName: 'Kuda', color: '#40196D' },
    { code: '303', name: 'OPay', shortName: 'OPay', color: '#1DCF9F' },
    { code: '304', name: 'PalmPay', shortName: 'PalmPay', color: '#7B41D8' },
    { code: '305', name: 'Moniepoint', shortName: 'Moniepoint', color: '#002F87' },
];

interface BankSelectProps extends Omit<SelectProps, 'options'> {
    showLogo?: boolean;
    showFullName?: boolean;
}

/**
 * Nigerian bank selector with logos
 */
export const BankSelect: React.FC<BankSelectProps> = ({
    showLogo = true,
    showFullName = false,
    ...props
}) => {
    const options = useMemo(
        () =>
            nigerianBanks.map((bank) => ({
                value: bank.code,
                label: (
                    <Space>
                        {showLogo && (
                            <Avatar
                                size="small"
                                style={{
                                    backgroundColor: bank.color,
                                    fontSize: 10,
                                    fontWeight: 600,
                                }}
                            >
                                {bank.shortName.substring(0, 2).toUpperCase()}
                            </Avatar>
                        )}
                        <span>{showFullName ? bank.name : bank.shortName}</span>
                    </Space>
                ),
                searchLabel: `${bank.name} ${bank.shortName} ${bank.code}`,
            })),
        [showLogo, showFullName]
    );

    return (
        <Select
            showSearch
            placeholder="Select bank"
            optionFilterProp="searchLabel"
            filterOption={(input, option) =>
                option?.searchLabel?.toLowerCase().includes(input.toLowerCase()) ?? false
            }
            options={options}
            {...props}
        />
    );
};

interface BankDisplayProps {
    code: string;
    showName?: boolean;
    size?: 'small' | 'default' | 'large';
}

/**
 * Display a bank with logo
 */
export const BankDisplay: React.FC<BankDisplayProps> = ({
    code,
    showName = true,
    size = 'default',
}) => {
    const bank = nigerianBanks.find((b) => b.code === code);

    if (!bank) {
        return (
            <Space>
                <Avatar size={size} icon={<BankOutlined />} />
                {showName && <Text>{code}</Text>}
            </Space>
        );
    }

    const avatarSize = size === 'small' ? 20 : size === 'large' ? 40 : 28;

    return (
        <Tooltip title={bank.name}>
            <Space>
                <Avatar
                    size={avatarSize}
                    style={{
                        backgroundColor: bank.color,
                        fontSize: avatarSize * 0.4,
                        fontWeight: 600,
                    }}
                >
                    {bank.shortName.substring(0, 2).toUpperCase()}
                </Avatar>
                {showName && <Text>{bank.shortName}</Text>}
            </Space>
        </Tooltip>
    );
};

/**
 * Get bank by code
 */
export const getBankByCode = (code: string) =>
    nigerianBanks.find((b) => b.code === code);

export default { BankSelect, BankDisplay, nigerianBanks, getBankByCode };
