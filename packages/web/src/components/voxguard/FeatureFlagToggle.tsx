import React, { useState } from 'react';
import { Switch, message } from 'antd';
import { voxguardApi } from '../../api/voxguard';

interface Props {
  flagId: string;
  enabled: boolean;
}

export const FeatureFlagToggle: React.FC<Props> = ({ flagId, enabled: initialEnabled }) => {
  const [enabled, setEnabled] = useState(initialEnabled);
  const [loading, setLoading] = useState(false);

  const handleToggle = async (checked: boolean) => {
    setLoading(true);
    try {
      await voxguardApi.updateFeatureFlag(flagId, checked);
      setEnabled(checked);
      message.success(`Flag ${checked ? 'enabled' : 'disabled'}`);
    } catch {
      message.error('Failed to update flag');
    } finally {
      setLoading(false);
    }
  };

  return <Switch checked={enabled} onChange={handleToggle} loading={loading} />;
};
