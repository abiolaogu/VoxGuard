import React from 'react';
import { Space, Tag, Tooltip, Typography } from 'antd';
import { SyncOutlined } from '@ant-design/icons';

const { Text } = Typography;

interface RealTimeIndicatorProps {
    isConnected?: boolean;
    lastUpdate?: Date | string;
    label?: string;
    showDot?: boolean;
}

export const RealTimeIndicator: React.FC<RealTimeIndicatorProps> = ({
    isConnected = true,
    lastUpdate,
    label = 'Real-time',
    showDot = true,
}) => {
    const formatTime = (date: Date | string) => {
        const d = typeof date === 'string' ? new Date(date) : date;
        return d.toLocaleTimeString('en-US', {
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit',
        });
    };

    return (
        <Tooltip
            title={
                lastUpdate
                    ? `Last updated: ${formatTime(lastUpdate)}`
                    : isConnected
                        ? 'Connected to real-time updates'
                        : 'Disconnected from real-time updates'
            }
        >
            <Tag
                color={isConnected ? 'success' : 'error'}
                style={{ cursor: 'help' }}
            >
                <Space size={4}>
                    {showDot && (
                        <span
                            style={{
                                width: 6,
                                height: 6,
                                borderRadius: '50%',
                                backgroundColor: isConnected ? '#52c41a' : '#ff4d4f',
                                display: 'inline-block',
                                animation: isConnected ? 'pulse 2s infinite' : 'none',
                            }}
                        />
                    )}
                    {isConnected ? (
                        <SyncOutlined spin style={{ fontSize: 10 }} />
                    ) : null}
                    <Text style={{ fontSize: 11 }}>{label}</Text>
                </Space>
            </Tag>
        </Tooltip>
    );
};

export default RealTimeIndicator;
