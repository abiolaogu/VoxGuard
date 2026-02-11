import { Tag, Tooltip } from 'antd';
import { LockOutlined, SafetyCertificateOutlined } from '@ant-design/icons';

interface AIDDTierBadgeProps {
  tier: 0 | 1 | 2;
  compact?: boolean;
}

const tierConfig = {
  0: {
    color: 'default',
    label: 'AIDD T0',
    compactLabel: 'T0',
    icon: null,
    tooltip: 'Tier 0 — Auto-merge safe (documentation, tests, text)',
  },
  1: {
    color: 'warning',
    label: 'AIDD T1',
    compactLabel: 'T1',
    icon: <LockOutlined />,
    tooltip: 'Tier 1 — Requires review (features, logic, blocking actions)',
  },
  2: {
    color: 'error',
    label: 'AIDD T2',
    compactLabel: 'T2',
    icon: <SafetyCertificateOutlined />,
    tooltip: 'Tier 2 — Requires admin approval (auth, payments, infra)',
  },
} as const;

export const AIDDTierBadge: React.FC<AIDDTierBadgeProps> = ({ tier, compact = false }) => {
  const config = tierConfig[tier];

  return (
    <Tooltip title={config.tooltip}>
      <Tag
        icon={!compact ? config.icon : undefined}
        color={config.color}
        style={{
          fontWeight: 600,
          fontSize: compact ? 10 : 11,
          padding: compact ? '0 4px' : '1px 6px',
          margin: 0,
          lineHeight: compact ? '18px' : '20px',
          borderRadius: 10,
        }}
      >
        {compact ? config.compactLabel : config.label}
      </Tag>
    </Tooltip>
  );
};

export default AIDDTierBadge;
