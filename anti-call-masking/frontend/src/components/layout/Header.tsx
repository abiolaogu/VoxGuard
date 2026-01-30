import { useGetIdentity, useLogout } from '@refinedev/core';
import {
  Layout,
  Space,
  Avatar,
  Dropdown,
  Typography,
  Badge,
  Button,
  Tooltip,
} from 'antd';
import {
  BellOutlined,
  UserOutlined,
  SettingOutlined,
  LogoutOutlined,
  SunOutlined,
  MoonOutlined,
} from '@ant-design/icons';
import { useSubscription } from '@apollo/client';
import { UNRESOLVED_ALERTS_COUNT_SUBSCRIPTION } from '../../graphql/subscriptions';
import { useThemeMode } from '../../hooks/useThemeMode';
import { ACM_COLORS } from '../../config/antd-theme';

const { Text } = Typography;

interface Identity {
  id: string;
  name: string;
  email: string;
  avatar?: string;
  role: string;
}

export const Header: React.FC = () => {
  const { data: identity } = useGetIdentity<Identity>();
  const { mutate: logout } = useLogout();
  const { mode, toggleMode } = useThemeMode();

  // Subscribe to unresolved alerts count
  const { data: alertsData } = useSubscription(UNRESOLVED_ALERTS_COUNT_SUBSCRIPTION);

  const unresolvedCount =
    (alertsData?.new_count?.aggregate?.count || 0) +
    (alertsData?.investigating_count?.aggregate?.count || 0) +
    (alertsData?.confirmed_count?.aggregate?.count || 0);

  const criticalCount = alertsData?.critical_count?.aggregate?.count || 0;

  const userMenuItems = [
    {
      key: 'profile',
      icon: <UserOutlined />,
      label: 'Profile',
    },
    {
      key: 'settings',
      icon: <SettingOutlined />,
      label: 'Settings',
    },
    {
      type: 'divider' as const,
    },
    {
      key: 'logout',
      icon: <LogoutOutlined />,
      label: 'Logout',
      danger: true,
    },
  ];

  const handleMenuClick = ({ key }: { key: string }) => {
    if (key === 'logout') {
      logout();
    }
  };

  return (
    <Layout.Header
      style={{
        display: 'flex',
        justifyContent: 'flex-end',
        alignItems: 'center',
        padding: '0 24px',
        height: 64,
        background: mode === 'dark' ? '#1F1F1F' : '#FFFFFF',
        borderBottom: `1px solid ${mode === 'dark' ? '#303030' : '#DEE2E6'}`,
      }}
    >
      <Space size="middle">
        {/* Theme Toggle */}
        <Tooltip title={mode === 'dark' ? 'Light Mode' : 'Dark Mode'}>
          <Button
            type="text"
            icon={mode === 'dark' ? <SunOutlined /> : <MoonOutlined />}
            onClick={toggleMode}
            style={{ fontSize: 18 }}
          />
        </Tooltip>

        {/* Notifications */}
        <Tooltip title={`${unresolvedCount} unresolved alerts`}>
          <Badge
            count={unresolvedCount}
            overflowCount={99}
            style={{
              backgroundColor: criticalCount > 0 ? ACM_COLORS.critical : ACM_COLORS.warning,
            }}
          >
            <Button
              type="text"
              icon={<BellOutlined style={{ fontSize: 18 }} />}
            />
          </Badge>
        </Tooltip>

        {/* User Menu */}
        <Dropdown
          menu={{
            items: userMenuItems,
            onClick: handleMenuClick,
          }}
          placement="bottomRight"
          arrow
        >
          <Space style={{ cursor: 'pointer' }}>
            <Avatar
              size="small"
              src={identity?.avatar}
              icon={<UserOutlined />}
              style={{ backgroundColor: ACM_COLORS.primary }}
            />
            <div style={{ lineHeight: 1.2 }}>
              <Text strong style={{ display: 'block', fontSize: 13 }}>
                {identity?.name || 'User'}
              </Text>
              <Text
                type="secondary"
                style={{ display: 'block', fontSize: 11, textTransform: 'capitalize' }}
              >
                {identity?.role || 'viewer'}
              </Text>
            </div>
          </Space>
        </Dropdown>
      </Space>
    </Layout.Header>
  );
};

export default Header;
