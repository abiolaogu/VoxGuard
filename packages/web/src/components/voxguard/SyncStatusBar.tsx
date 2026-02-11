import React from 'react';
import { Tag, Progress, Space, Typography } from 'antd';
import { SyncOutlined, CheckCircleOutlined, CloseCircleOutlined } from '@ant-design/icons';

const { Text } = Typography;

interface Props {
  status: 'success' | 'failed' | 'in_progress' | string;
  entriesPushed?: number;
  entriesPulled?: number;
  errors?: number;
}

export const SyncStatusBar: React.FC<Props> = ({ status, entriesPushed = 0, entriesPulled = 0, errors = 0 }) => {
  const statusConfig: Record<string, { color: string; icon: React.ReactNode }> = {
    success: { color: 'green', icon: <CheckCircleOutlined /> },
    failed: { color: 'red', icon: <CloseCircleOutlined /> },
    in_progress: { color: 'blue', icon: <SyncOutlined spin /> },
  };
  const c = statusConfig[status] || statusConfig.failed;

  return (
    <Space direction="vertical" size="small" style={{ width: '100%' }}>
      <Space>
        <Tag color={c.color} icon={c.icon}>{status.replace(/_/g, ' ')}</Tag>
        {status === 'in_progress' && <Progress percent={50} size="small" style={{ width: 100 }} />}
      </Space>
      <Space>
        <Text type="secondary" style={{ fontSize: 12 }}>Pushed: {entriesPushed}</Text>
        <Text type="secondary" style={{ fontSize: 12 }}>Pulled: {entriesPulled}</Text>
        {errors > 0 && <Text type="danger" style={{ fontSize: 12 }}>Errors: {errors}</Text>}
      </Space>
    </Space>
  );
};
