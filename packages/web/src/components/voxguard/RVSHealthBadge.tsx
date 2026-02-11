import React from 'react';
import { Badge, Tag } from 'antd';
import { CheckCircleOutlined, ExclamationCircleOutlined, CloseCircleOutlined } from '@ant-design/icons';

interface Props {
  status: 'connected' | 'degraded' | 'disconnected' | string;
}

export const RVSHealthBadge: React.FC<Props> = ({ status }) => {
  const config = {
    connected: { color: 'green' as const, icon: <CheckCircleOutlined />, text: 'Connected' },
    degraded: { color: 'orange' as const, icon: <ExclamationCircleOutlined />, text: 'Degraded' },
    disconnected: { color: 'red' as const, icon: <CloseCircleOutlined />, text: 'Disconnected' },
  };
  const c = config[status as keyof typeof config] || config.disconnected;
  return <Tag color={c.color} icon={c.icon}>{c.text}</Tag>;
};
