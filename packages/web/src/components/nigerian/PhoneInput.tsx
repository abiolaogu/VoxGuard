import React, { useState, useCallback } from 'react';
import { Input, Select, Space, Typography, InputProps } from 'antd';
import { PhoneOutlined } from '@ant-design/icons';

const { Text } = Typography;

/**
 * Nigerian mobile network operators
 */
export const nigerianMNOs = [
    { prefix: ['0703', '0706', '0803', '0806', '0810', '0813', '0814', '0816', '0903', '0906', '0913', '0916'], name: 'MTN', color: '#FFCC00' },
    { prefix: ['0805', '0807', '0811', '0815', '0905', '0915'], name: 'Glo', color: '#009933' },
    { prefix: ['0701', '0708', '0802', '0808', '0812', '0902', '0901', '0904', '0907', '0912'], name: 'Airtel', color: '#ED1C24' },
    { prefix: ['0809', '0817', '0818', '0909', '0908'], name: '9mobile', color: '#006838' },
];

/**
 * Detect MNO from phone number
 */
export const detectMNO = (phoneNumber: string): string | null => {
    const cleaned = phoneNumber.replace(/\D/g, '');
    let normalized = cleaned;

    // Handle +234 prefix
    if (cleaned.startsWith('234')) {
        normalized = '0' + cleaned.slice(3);
    }

    const prefix = normalized.slice(0, 4);

    for (const mno of nigerianMNOs) {
        if (mno.prefix.includes(prefix)) {
            return mno.name;
        }
    }

    return null;
};

/**
 * Format Nigerian phone number
 */
export const formatNigerianPhone = (
    phone: string,
    format: 'local' | 'international' = 'local'
): string => {
    const cleaned = phone.replace(/\D/g, '');

    // Normalize to local format first
    let local = cleaned;
    if (cleaned.startsWith('234')) {
        local = '0' + cleaned.slice(3);
    }

    if (local.length !== 11) {
        return phone; // Return original if invalid
    }

    if (format === 'international') {
        return `+234 ${local.slice(1, 4)} ${local.slice(4, 7)} ${local.slice(7)}`;
    }

    return `${local.slice(0, 4)} ${local.slice(4, 7)} ${local.slice(7)}`;
};

/**
 * Validate Nigerian phone number
 */
export const validateNigerianPhone = (phone: string): boolean => {
    const cleaned = phone.replace(/\D/g, '');

    // Check length
    if (cleaned.length === 11 && cleaned.startsWith('0')) {
        return detectMNO(cleaned) !== null;
    }

    if (cleaned.length === 13 && cleaned.startsWith('234')) {
        return detectMNO(cleaned) !== null;
    }

    return false;
};

interface NigerianPhoneInputProps extends Omit<InputProps, 'onChange' | 'value'> {
    value?: string;
    onChange?: (value: string, isValid: boolean) => void;
    showMNO?: boolean;
    format?: 'local' | 'international';
}

/**
 * Nigerian phone number input with MNO detection
 */
export const NigerianPhoneInput: React.FC<NigerianPhoneInputProps> = ({
    value = '',
    onChange,
    showMNO = true,
    format = 'local',
    ...props
}) => {
    const [internalValue, setInternalValue] = useState(value);
    const [mno, setMNO] = useState<string | null>(detectMNO(value));

    const handleChange = useCallback(
        (e: React.ChangeEvent<HTMLInputElement>) => {
            const raw = e.target.value.replace(/[^0-9+]/g, '');
            setInternalValue(raw);

            const detectedMNO = detectMNO(raw);
            setMNO(detectedMNO);

            const isValid = validateNigerianPhone(raw);
            onChange?.(raw, isValid);
        },
        [onChange]
    );

    const getMNOColor = () => {
        const found = nigerianMNOs.find((m) => m.name === mno);
        return found?.color || '#d9d9d9';
    };

    return (
        <Space direction="vertical" size={4} style={{ width: '100%' }}>
            <Input
                {...props}
                value={internalValue}
                onChange={handleChange}
                prefix={<PhoneOutlined style={{ color: getMNOColor() }} />}
                placeholder="0803 123 4567"
                maxLength={15}
                suffix={
                    showMNO && mno ? (
                        <Text
                            style={{
                                fontSize: 11,
                                color: getMNOColor(),
                                fontWeight: 500,
                            }}
                        >
                            {mno}
                        </Text>
                    ) : null
                }
            />
            {internalValue && !validateNigerianPhone(internalValue) && internalValue.length > 5 && (
                <Text type="danger" style={{ fontSize: 11 }}>
                    Invalid Nigerian phone number
                </Text>
            )}
        </Space>
    );
};

interface PhoneDisplayProps {
    phone: string;
    format?: 'local' | 'international';
    showMNO?: boolean;
}

/**
 * Display formatted Nigerian phone number
 */
export const PhoneDisplay: React.FC<PhoneDisplayProps> = ({
    phone,
    format = 'local',
    showMNO = true,
}) => {
    const mno = detectMNO(phone);
    const found = nigerianMNOs.find((m) => m.name === mno);

    return (
        <Space size={8}>
            <Text copyable style={{ fontFamily: 'monospace' }}>
                {formatNigerianPhone(phone, format)}
            </Text>
            {showMNO && mno && (
                <Text
                    style={{
                        fontSize: 11,
                        color: found?.color,
                        fontWeight: 500,
                    }}
                >
                    {mno}
                </Text>
            )}
        </Space>
    );
};

export default {
    NigerianPhoneInput,
    PhoneDisplay,
    formatNigerianPhone,
    validateNigerianPhone,
    detectMNO,
    nigerianMNOs,
};
