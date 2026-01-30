import { Tag, Tooltip } from 'antd';
import {
  ExclamationCircleOutlined,
  WarningOutlined,
  InfoCircleOutlined,
} from '@ant-design/icons';
import { severityColors } from '../../config/antd-theme';

interface SeverityBadgeProps {
  severity: string;
  showIcon?: boolean;
  size?: 'small' | 'default';
}

const severityIcons: Record<string, React.ReactNode> = {
  CRITICAL: <ExclamationCircleOutlined />,
  HIGH: <WarningOutlined />,
  MEDIUM: <InfoCircleOutlined />,
  LOW: <InfoCircleOutlined />,
};

const severityDescriptions: Record<string, string> = {
  CRITICAL: 'Immediate action required - confirmed call masking attack',
  HIGH: 'High probability of call masking - requires investigation',
  MEDIUM: 'Suspicious activity detected - monitor closely',
  LOW: 'Minor anomaly - may be false positive',
};

export const SeverityBadge: React.FC<SeverityBadgeProps> = ({
  severity,
  showIcon = false,
  size = 'default',
}) => {
  const colors = severityColors[severity] || severityColors.LOW;

  return (
    <Tooltip title={severityDescriptions[severity]}>
      <Tag
        icon={showIcon ? severityIcons[severity] : undefined}
        style={{
          backgroundColor: colors.background,
          color: colors.color,
          border: 'none',
          fontWeight: 600,
          fontSize: size === 'small' ? 10 : 12,
          padding: size === 'small' ? '0 4px' : '2px 8px',
        }}
      >
        {severity}
      </Tag>
    </Tooltip>
  );
};

export default SeverityBadge;
