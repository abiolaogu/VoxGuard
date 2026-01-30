import { Spin } from 'antd';
import { LoadingOutlined } from '@ant-design/icons';

interface LoadingOverlayProps {
  loading: boolean;
  children: React.ReactNode;
  tip?: string;
}

export const LoadingOverlay: React.FC<LoadingOverlayProps> = ({
  loading,
  children,
  tip = 'Loading...',
}) => {
  const antIcon = <LoadingOutlined style={{ fontSize: 24 }} spin />;

  return (
    <Spin spinning={loading} indicator={antIcon} tip={tip}>
      {children}
    </Spin>
  );
};

export default LoadingOverlay;
