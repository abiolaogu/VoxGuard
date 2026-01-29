import React, { useMemo } from 'react';
import { Select, Space, Tag, SelectProps } from 'antd';
import { EnvironmentOutlined } from '@ant-design/icons';

/**
 * Nigerian states
 */
export const nigerianStates = [
    { code: 'AB', name: 'Abia', region: 'South East' },
    { code: 'AD', name: 'Adamawa', region: 'North East' },
    { code: 'AK', name: 'Akwa Ibom', region: 'South South' },
    { code: 'AN', name: 'Anambra', region: 'South East' },
    { code: 'BA', name: 'Bauchi', region: 'North East' },
    { code: 'BY', name: 'Bayelsa', region: 'South South' },
    { code: 'BE', name: 'Benue', region: 'North Central' },
    { code: 'BO', name: 'Borno', region: 'North East' },
    { code: 'CR', name: 'Cross River', region: 'South South' },
    { code: 'DE', name: 'Delta', region: 'South South' },
    { code: 'EB', name: 'Ebonyi', region: 'South East' },
    { code: 'ED', name: 'Edo', region: 'South South' },
    { code: 'EK', name: 'Ekiti', region: 'South West' },
    { code: 'EN', name: 'Enugu', region: 'South East' },
    { code: 'FC', name: 'Abuja FCT', region: 'North Central' },
    { code: 'GO', name: 'Gombe', region: 'North East' },
    { code: 'IM', name: 'Imo', region: 'South East' },
    { code: 'JI', name: 'Jigawa', region: 'North West' },
    { code: 'KD', name: 'Kaduna', region: 'North West' },
    { code: 'KN', name: 'Kano', region: 'North West' },
    { code: 'KT', name: 'Katsina', region: 'North West' },
    { code: 'KE', name: 'Kebbi', region: 'North West' },
    { code: 'KO', name: 'Kogi', region: 'North Central' },
    { code: 'KW', name: 'Kwara', region: 'North Central' },
    { code: 'LA', name: 'Lagos', region: 'South West' },
    { code: 'NA', name: 'Nasarawa', region: 'North Central' },
    { code: 'NI', name: 'Niger', region: 'North Central' },
    { code: 'OG', name: 'Ogun', region: 'South West' },
    { code: 'ON', name: 'Ondo', region: 'South West' },
    { code: 'OS', name: 'Osun', region: 'South West' },
    { code: 'OY', name: 'Oyo', region: 'South West' },
    { code: 'PL', name: 'Plateau', region: 'North Central' },
    { code: 'RI', name: 'Rivers', region: 'South South' },
    { code: 'SO', name: 'Sokoto', region: 'North West' },
    { code: 'TA', name: 'Taraba', region: 'North East' },
    { code: 'YO', name: 'Yobe', region: 'North East' },
    { code: 'ZA', name: 'Zamfara', region: 'North West' },
];

const regionColors: Record<string, string> = {
    'North Central': '#1890ff',
    'North East': '#faad14',
    'North West': '#722ed1',
    'South East': '#52c41a',
    'South South': '#fa541c',
    'South West': '#eb2f96',
};

interface StateSelectProps extends Omit<SelectProps, 'options'> {
    showRegion?: boolean;
    regionFilter?: string;
}

/**
 * Nigerian state selector with regions
 */
export const StateSelect: React.FC<StateSelectProps> = ({
    showRegion = true,
    regionFilter,
    ...props
}) => {
    const filteredStates = useMemo(() => {
        if (regionFilter) {
            return nigerianStates.filter((s) => s.region === regionFilter);
        }
        return nigerianStates;
    }, [regionFilter]);

    const options = useMemo(
        () =>
            filteredStates.map((state) => ({
                value: state.code,
                label: (
                    <Space>
                        <EnvironmentOutlined />
                        <span>{state.name}</span>
                        {showRegion && (
                            <Tag
                                color={regionColors[state.region]}
                                style={{ fontSize: 10, padding: '0 4px' }}
                            >
                                {state.region}
                            </Tag>
                        )}
                    </Space>
                ),
                searchLabel: `${state.name} ${state.region} ${state.code}`,
            })),
        [filteredStates, showRegion]
    );

    return (
        <Select
            showSearch
            placeholder="Select state"
            optionFilterProp="searchLabel"
            filterOption={(input, option) =>
                option?.searchLabel?.toLowerCase().includes(input.toLowerCase()) ?? false
            }
            options={options}
            {...props}
        />
    );
};

interface RegionSelectProps extends Omit<SelectProps, 'options'> {
    showCount?: boolean;
}

/**
 * Nigerian region selector
 */
export const RegionSelect: React.FC<RegionSelectProps> = ({
    showCount = true,
    ...props
}) => {
    const regions = useMemo(() => {
        const regionMap = new Map<string, number>();
        nigerianStates.forEach((state) => {
            regionMap.set(state.region, (regionMap.get(state.region) || 0) + 1);
        });
        return Array.from(regionMap.entries()).map(([region, count]) => ({
            region,
            count,
        }));
    }, []);

    return (
        <Select
            placeholder="Select region"
            options={regions.map((r) => ({
                value: r.region,
                label: (
                    <Space>
                        <Tag color={regionColors[r.region]}>{r.region}</Tag>
                        {showCount && <span style={{ color: '#999' }}>({r.count} states)</span>}
                    </Space>
                ),
            }))}
            {...props}
        />
    );
};

/**
 * Get state by code
 */
export const getStateByCode = (code: string) =>
    nigerianStates.find((s) => s.code === code);

export default { StateSelect, RegionSelect, nigerianStates, getStateByCode };
