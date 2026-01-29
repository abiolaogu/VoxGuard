import React, { useState, useEffect } from 'react';
import { Input, Form, Select, Space, Typography } from 'antd';
import type { InputProps } from 'antd';

const { Text } = Typography;

interface PhoneNumberInputProps extends Omit<InputProps, 'onChange'> {
    value?: string;
    onChange?: (value: string) => void;
    defaultCountry?: string;
    showLabel?: boolean;
}

const countryCodes = [
    { code: '+234', country: 'NG', label: '🇳🇬 +234' },
    { code: '+1', country: 'US', label: '🇺🇸 +1' },
    { code: '+44', country: 'GB', label: '🇬🇧 +44' },
    { code: '+1', country: 'CA', label: '🇨🇦 +1' },
    { code: '+61', country: 'AU', label: '🇦🇺 +61' },
    { code: '+353', country: 'IE', label: '🇮🇪 +353' },
    { code: '+49', country: 'DE', label: '🇩🇪 +49' },
];

export const PhoneNumberInput: React.FC<PhoneNumberInputProps> = ({
    value = '',
    onChange,
    defaultCountry = 'NG',
    showLabel = false,
    ...rest
}) => {
    const [countryCode, setCountryCode] = useState('+234');
    const [phoneNumber, setPhoneNumber] = useState('');

    useEffect(() => {
        // Parse initial value
        if (value) {
            const country = countryCodes.find((c) => value.startsWith(c.code));
            if (country) {
                setCountryCode(country.code);
                setPhoneNumber(value.slice(country.code.length));
            } else {
                setPhoneNumber(value);
            }
        }
    }, []);

    const handleCountryChange = (code: string) => {
        setCountryCode(code);
        onChange?.(`${code}${phoneNumber}`);
    };

    const handlePhoneChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const num = e.target.value.replace(/[^0-9]/g, '');
        setPhoneNumber(num);
        onChange?.(`${countryCode}${num}`);
    };

    const selectBefore = (
        <Select
            value={countryCode}
            onChange={handleCountryChange}
            style={{ width: 100 }}
            options={countryCodes.map((c) => ({
                value: c.code,
                label: c.label,
            }))}
        />
    );

    return (
        <Space direction="vertical" style={{ width: '100%' }}>
            {showLabel && <Text type="secondary">Phone Number</Text>}
            <Input
                addonBefore={selectBefore}
                value={phoneNumber}
                onChange={handlePhoneChange}
                placeholder="8012345678"
                maxLength={15}
                {...rest}
            />
        </Space>
    );
};

export default PhoneNumberInput;
