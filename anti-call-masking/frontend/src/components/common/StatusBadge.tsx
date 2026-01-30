import { Tag, Tooltip } from 'antd';
import {
  ClockCircleOutlined,
  SearchOutlined,
  CheckCircleOutlined,
  CloseCircleOutlined,
} from '@ant-design/icons';
import { statusColors } from '../../config/antd-theme';

interface StatusBadgeProps {
  status: string;
  showIcon?: boolean;
  size?: 'small' | 'default';
}

const statusIcons: Record<string, React.ReactNode> = {
  NEW: <ClockCircleOutlined />,
  INVESTIGATING: <SearchOutlined />,
  CONFIRMED: <CheckCircleOutlined />,
  RESOLVED: <CheckCircleOutlined />,
  FALSE_POSITIVE: <CloseCircleOutlined />,
};

const statusDescriptions: Record<string, string> = {
  NEW: 'Alert just detected, awaiting review',
  INVESTIGATING: 'Under active investigation by analyst',
  CONFIRMED: 'Verified as call masking attempt',
  RESOLVED: 'Action taken, issue resolved',
  FALSE_POSITIVE: 'Determined not to be a threat',
};

export const StatusBadge: React.FC<StatusBadgeProps> = ({
  status,
  showIcon = false,
  size = 'default',
}) => {
  const colors = statusColors[status] || statusColors.NEW;
  const displayStatus = status.replace('_', ' ');

  return (
    <Tooltip title={statusDescriptions[status]}>
      <Tag
        icon={showIcon ? statusIcons[status] : undefined}
        style={{
          backgroundColor: colors.background,
          color: colors.color,
          border: 'none',
          fontSize: size === 'small' ? 10 : 12,
          padding: size === 'small' ? '0 4px' : '2px 8px',
        }}
      >
        {displayStatus}
      </Tag>
    </Tooltip>
  );
};

export default StatusBadge;
