import { Link } from 'react-router-dom';
import { Space, Typography } from 'antd';
import { SafetyCertificateOutlined } from '@ant-design/icons';
import { VG_COLORS } from '../../config/antd-theme';

const { Title: AntTitle } = Typography;

interface TitleProps {
  collapsed: boolean;
}

export const Title: React.FC<TitleProps> = ({ collapsed }) => {
  return (
    <Link to="/dashboard" style={{ textDecoration: 'none' }}>
      <Space
        style={{
          padding: collapsed ? '12px 8px' : '12px 16px',
          display: 'flex',
          justifyContent: collapsed ? 'center' : 'flex-start',
          alignItems: 'center',
          width: '100%',
        }}
      >
        <SafetyCertificateOutlined
          style={{
            fontSize: 28,
            color: VG_COLORS.secondary,
          }}
        />
        {!collapsed && (
          <div style={{ lineHeight: 1.2 }}>
            <AntTitle
              level={5}
              style={{
                margin: 0,
                color: '#FFFFFF',
                fontWeight: 700,
                letterSpacing: '-0.5px',
              }}
            >
              VoxGuard
            </AntTitle>
            <span
              style={{
                fontSize: 10,
                color: 'rgba(255, 255, 255, 0.65)',
                textTransform: 'uppercase',
                letterSpacing: '1px',
              }}
            >
              Fraud Detection
            </span>
          </div>
        )}
      </Space>
    </Link>
  );
};

export default Title;
