import React from 'react';
import { Progress, Typography } from 'antd';

const { Text } = Typography;

interface Props {
  score: number;
  size?: number;
}

export const CompositeScoreGauge: React.FC<Props> = ({ score, size = 120 }) => {
  const percent = Math.round(score * 100);
  const color = percent >= 70 ? '#52c41a' : percent >= 40 ? '#faad14' : '#ff4d4f';
  const label = percent >= 70 ? 'Low Risk' : percent >= 40 ? 'Medium Risk' : 'High Risk';

  return (
    <div style={{ textAlign: 'center' }}>
      <Progress
        type="dashboard"
        percent={percent}
        size={size}
        strokeColor={color}
        format={() => `${percent}%`}
      />
      <div style={{ marginTop: 8 }}>
        <Text type="secondary">{label}</Text>
      </div>
    </div>
  );
};
