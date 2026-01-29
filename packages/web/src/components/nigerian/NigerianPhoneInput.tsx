import React from 'react';
import { Input, InputProps, Space, Typography } from 'antd';
import { PhoneOutlined } from '@ant-design/icons';

const { Text } = Typography;

// Nigerian phone number prefixes by carrier
export const NIGERIAN_CARRIERS = {
    MTN: ['0703', '0706', '0803', '0806', '0810', '0813', '0814', '0816', '0903', '0906', '0913'],
    Glo: ['0705', '0805', '0807', '0811', '0815', '0905'],
    Airtel: ['0701', '0708', '0802', '0808', '0812', '0901', '0902', '0904', '0907', '0912'],
    '9mobile': ['0809', '0817', '0818', '0908', '0909'],
} as const;

export type NigerianCarrier = keyof typeof NIGERIAN_CARRIERS;

// Detect carrier from phone number
export const detectCarrier = (phone: string): NigerianCarrier | null => {
    const cleaned = phone.replace(/\D/g, '');
    const prefix = cleaned.startsWith('234') ? '0' + cleaned.slice(3, 6) : cleaned.slice(0, 4);

    for (const [carrier, prefixes] of Object.entries(NIGERIAN_CARRIERS)) {
        if (prefixes.includes(prefix)) {
            return carrier as NigerianCarrier;
        }
    }
    return null;
};

// Format Nigerian phone number
export const formatNigerianPhone = (phone: string): string => {
    const cleaned = phone.replace(/\D/g, '');

    // Handle +234 format
    if (cleaned.startsWith('234')) {
        const local = '0' + cleaned.slice(3);
        return formatLocalNumber(local);
    }

    return formatLocalNumber(cleaned);
};

const formatLocalNumber = (phone: string): string => {
    if (phone.length <= 4) return phone;
    if (phone.length <= 7) return `${phone.slice(0, 4)} ${phone.slice(4)}`;
    return `${phone.slice(0, 4)} ${phone.slice(4, 7)} ${phone.slice(7, 11)}`;
};

// Convert to international format
export const toInternationalFormat = (phone: string): string => {
    const cleaned = phone.replace(/\D/g, '');

    if (cleaned.startsWith('234')) {
        return '+' + cleaned;
    }

    if (cleaned.startsWith('0')) {
        return '+234' + cleaned.slice(1);
    }

    return '+234' + cleaned;
};

// Carrier colors for UI
const CARRIER_COLORS: Record<NigerianCarrier, string> = {
    MTN: '#FFCC00',
    Glo: '#00A651',
    Airtel: '#E30613',
    '9mobile': '#00A859',
};

interface NigerianPhoneInputProps extends Omit<InputProps, 'onChange'> {
    value?: string;
    onChange?: (value: string, internationalFormat: string) => void;
    showCarrier?: boolean;
}

export const NigerianPhoneInput: React.FC<NigerianPhoneInputProps> = ({
    value = '',
    onChange,
    showCarrier = true,
    ...props
}) => {
    const carrier = detectCarrier(value);

    const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const rawValue = e.target.value.replace(/\D/g, '');
        const formatted = formatNigerianPhone(rawValue);
        const international = toInternationalFormat(rawValue);
        onChange?.(formatted, international);
    };

    return (
        <Space direction="vertical" style={{ width: '100%' }}>
            <Input
                {...props}
                value={value}
                onChange={handleChange}
                addonBefore={
                    <Space>
                        <span>🇳🇬</span>
                        <Text strong>+234</Text>
                    </Space>
                }
                prefix={<PhoneOutlined />}
                placeholder="0803 XXX XXXX"
                maxLength={14} // Formatted length with spaces
            />
            {showCarrier && carrier && (
                <Space size="small">
                    <span
                        style={{
                            display: 'inline-block',
                            width: 8,
                            height: 8,
                            borderRadius: '50%',
                            backgroundColor: CARRIER_COLORS[carrier],
                        }}
                    />
                    <Text type="secondary" style={{ fontSize: 12 }}>
                        {carrier} Network
                    </Text>
                </Space>
            )}
        </Space>
    );
};

export default NigerianPhoneInput;
