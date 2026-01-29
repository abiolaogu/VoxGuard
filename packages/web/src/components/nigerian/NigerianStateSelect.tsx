import React, { useMemo } from 'react';
import { Select, Space, Typography, Tag } from 'antd';
import { EnvironmentOutlined } from '@ant-design/icons';

const { Text } = Typography;

// Nigerian States Data
export const NIGERIAN_STATES = [
    { code: 'ABI', name: 'Abia', capital: 'Umuahia', zone: 'South East' },
    { code: 'ADA', name: 'Adamawa', capital: 'Yola', zone: 'North East' },
    { code: 'AKW', name: 'Akwa Ibom', capital: 'Uyo', zone: 'South South' },
    { code: 'ANA', name: 'Anambra', capital: 'Awka', zone: 'South East' },
    { code: 'BAU', name: 'Bauchi', capital: 'Bauchi', zone: 'North East' },
    { code: 'BAY', name: 'Bayelsa', capital: 'Yenagoa', zone: 'South South' },
    { code: 'BEN', name: 'Benue', capital: 'Makurdi', zone: 'North Central' },
    { code: 'BOR', name: 'Borno', capital: 'Maiduguri', zone: 'North East' },
    { code: 'CRO', name: 'Cross River', capital: 'Calabar', zone: 'South South' },
    { code: 'DEL', name: 'Delta', capital: 'Asaba', zone: 'South South' },
    { code: 'EBO', name: 'Ebonyi', capital: 'Abakaliki', zone: 'South East' },
    { code: 'EDO', name: 'Edo', capital: 'Benin City', zone: 'South South' },
    { code: 'EKI', name: 'Ekiti', capital: 'Ado-Ekiti', zone: 'South West' },
    { code: 'ENU', name: 'Enugu', capital: 'Enugu', zone: 'South East' },
    { code: 'FCT', name: 'FCT', capital: 'Abuja', zone: 'North Central' },
    { code: 'GOM', name: 'Gombe', capital: 'Gombe', zone: 'North East' },
    { code: 'IMO', name: 'Imo', capital: 'Owerri', zone: 'South East' },
    { code: 'JIG', name: 'Jigawa', capital: 'Dutse', zone: 'North West' },
    { code: 'KAD', name: 'Kaduna', capital: 'Kaduna', zone: 'North West' },
    { code: 'KAN', name: 'Kano', capital: 'Kano', zone: 'North West' },
    { code: 'KAT', name: 'Katsina', capital: 'Katsina', zone: 'North West' },
    { code: 'KEB', name: 'Kebbi', capital: 'Birnin Kebbi', zone: 'North West' },
    { code: 'KOG', name: 'Kogi', capital: 'Lokoja', zone: 'North Central' },
    { code: 'KWA', name: 'Kwara', capital: 'Ilorin', zone: 'North Central' },
    { code: 'LAG', name: 'Lagos', capital: 'Ikeja', zone: 'South West' },
    { code: 'NAS', name: 'Nasarawa', capital: 'Lafia', zone: 'North Central' },
    { code: 'NIG', name: 'Niger', capital: 'Minna', zone: 'North Central' },
    { code: 'OGU', name: 'Ogun', capital: 'Abeokuta', zone: 'South West' },
    { code: 'OND', name: 'Ondo', capital: 'Akure', zone: 'South West' },
    { code: 'OSU', name: 'Osun', capital: 'Osogbo', zone: 'South West' },
    { code: 'OYO', name: 'Oyo', capital: 'Ibadan', zone: 'South West' },
    { code: 'PLA', name: 'Plateau', capital: 'Jos', zone: 'North Central' },
    { code: 'RIV', name: 'Rivers', capital: 'Port Harcourt', zone: 'South South' },
    { code: 'SOK', name: 'Sokoto', capital: 'Sokoto', zone: 'North West' },
    { code: 'TAR', name: 'Taraba', capital: 'Jalingo', zone: 'North East' },
    { code: 'YOB', name: 'Yobe', capital: 'Damaturu', zone: 'North East' },
    { code: 'ZAM', name: 'Zamfara', capital: 'Gusau', zone: 'North West' },
] as const;

export type NigerianState = (typeof NIGERIAN_STATES)[number];
export type GeopoliticalZone = NigerianState['zone'];

const ZONE_COLORS: Record<GeopoliticalZone, string> = {
    'North Central': 'blue',
    'North East': 'orange',
    'North West': 'gold',
    'South East': 'green',
    'South South': 'cyan',
    'South West': 'purple',
};

interface NigerianStateSelectProps {
    value?: string;
    onChange?: (value: string, state?: NigerianState) => void;
    placeholder?: string;
    disabled?: boolean;
    groupByZone?: boolean;
    showCapital?: boolean;
    style?: React.CSSProperties;
}

export const NigerianStateSelect: React.FC<NigerianStateSelectProps> = ({
    value,
    onChange,
    placeholder = 'Select a state',
    disabled = false,
    groupByZone = true,
    showCapital = false,
    style,
}) => {
    const handleChange = (code: string) => {
        const state = NIGERIAN_STATES.find((s) => s.code === code);
        onChange?.(code, state);
    };

    const groupedStates = useMemo(() => {
        if (!groupByZone) return null;

        const groups: Record<GeopoliticalZone, NigerianState[]> = {
            'North Central': [],
            'North East': [],
            'North West': [],
            'South East': [],
            'South South': [],
            'South West': [],
        };

        NIGERIAN_STATES.forEach((state) => {
            groups[state.zone].push(state);
        });

        return groups;
    }, [groupByZone]);

    const renderOption = (state: NigerianState) => (
        <Select.Option key={state.code} value={state.code} label={state.name}>
            <Space>
                <EnvironmentOutlined />
                <Text>{state.name}</Text>
                {showCapital && (
                    <Text type="secondary" style={{ fontSize: 12 }}>
                        ({state.capital})
                    </Text>
                )}
                <Tag color={ZONE_COLORS[state.zone]} style={{ fontSize: 10 }}>
                    {state.zone}
                </Tag>
            </Space>
        </Select.Option>
    );

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
            {groupByZone && groupedStates ? (
                Object.entries(groupedStates).map(([zone, states]) => (
                    <Select.OptGroup key={zone} label={zone}>
                        {states.map(renderOption)}
                    </Select.OptGroup>
                ))
            ) : (
                NIGERIAN_STATES.map(renderOption)
            )}
        </Select>
    );
};

export default NigerianStateSelect;
