import React from 'react';
import { Tag } from 'antd';

interface Props {
  phase: string;
}

export const PhaseIndicator: React.FC<Props> = ({ phase }) => {
  const config: Record<string, { color: string; label: string }> = {
    shadow: { color: 'default', label: 'Shadow' },
    composite: { color: 'blue', label: 'Composite' },
    active: { color: 'green', label: 'Active' },
  };
  const c = config[phase] || { color: 'default', label: phase };
  return <Tag color={c.color}>{c.label}</Tag>;
};
