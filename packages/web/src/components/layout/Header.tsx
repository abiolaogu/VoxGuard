import { useState } from 'react';
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
  Tag,
} from 'antd';
import {
  BellOutlined,
  UserOutlined,
  SettingOutlined,
  LogoutOutlined,
  SunOutlined,
  MoonOutlined,
  WarningOutlined,
  FileTextOutlined,
  SyncOutlined,
  RightOutlined,
} from '@ant-design/icons';
import { useSubscription } from '@apollo/client';
import { useNavigate } from 'react-router-dom';
import { UNRESOLVED_ALERTS_COUNT_SUBSCRIPTION } from '../../graphql/subscriptions';
import { useThemeMode } from '../../hooks/useThemeMode';
import { VG_COLORS } from '../../config/antd-theme';
import { PortalHub } from './PortalHub';
import { LanguageSwitcher } from '../common/LanguageSwitcher';
import { CurrencySwitcher } from '../common/CurrencySwitcher';

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
  const navigate = useNavigate();

  // Subscribe to unresolved alerts count
  const { data: alertsData } = useSubscription(UNRESOLVED_ALERTS_COUNT_SUBSCRIPTION);

  const unresolvedCount =
    (alertsData?.new_count?.aggregate?.count || 0) +
    (alertsData?.investigating_count?.aggregate?.count || 0) +
    (alertsData?.confirmed_count?.aggregate?.count || 0);

  const criticalCount = alertsData?.critical_count?.aggregate?.count || 0;

  const [notificationsOpen, setNotificationsOpen] = useState(false);

  const mockNotifications = [
    {
      key: 'n1',
      icon: <WarningOutlined style={{ color: VG_COLORS.error }} />,
      title: 'Fraud Alert: Call Masking Detected',
      description: 'Suspicious CLI spoofing from +234-prefix routes',
      time: '2 min ago',
      unread: true,
    },
    {
      key: 'n2',
      icon: <FileTextOutlined style={{ color: VG_COLORS.info }} />,
      title: 'NCC Compliance Report Ready',
      description: 'Monthly NCC submission report generated',
      time: '15 min ago',
      unread: true,
    },
    {
      key: 'n3',
      icon: <SyncOutlined style={{ color: VG_COLORS.success }} />,
      title: 'System Update Complete',
      description: 'VoxGuard engine v2.4.1 deployed successfully',
      time: '1 hr ago',
      unread: false,
    },
    {
      key: 'n4',
      icon: <WarningOutlined style={{ color: VG_COLORS.warning }} />,
      title: 'Wangiri Spike Detected',
      description: '12 new wangiri incidents from Sierra Leone range',
      time: '3 hr ago',
      unread: false,
    },
  ];

  const unreadNotifCount = mockNotifications.filter((n) => n.unread).length;

  const notificationMenuItems = [
    {
      key: 'notif-header',
      type: 'group' as const,
      label: (
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '4px 0' }}>
          <Text strong style={{ fontSize: 14 }}>Notifications</Text>
          {unreadNotifCount > 0 && <Tag color="blue">{unreadNotifCount} new</Tag>}
        </div>
      ),
    },
    { key: 'notif-divider-top', type: 'divider' as const },
    ...mockNotifications.map((notif) => ({
      key: notif.key,
      label: (
        <div style={{ display: 'flex', gap: 10, alignItems: 'flex-start', padding: '4px 0', maxWidth: 300 }}>
          <div style={{ fontSize: 16, marginTop: 2 }}>{notif.icon}</div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
              <Text strong style={{ fontSize: 13 }}>{notif.title}</Text>
              {notif.unread && (
                <span style={{ width: 6, height: 6, borderRadius: '50%', backgroundColor: VG_COLORS.info, display: 'inline-block', flexShrink: 0 }} />
              )}
            </div>
            <Text type="secondary" style={{ fontSize: 11, display: 'block' }}>{notif.description}</Text>
            <Text type="secondary" style={{ fontSize: 10 }}>{notif.time}</Text>
          </div>
        </div>
      ),
    })),
    { key: 'notif-divider-bottom', type: 'divider' as const },
    {
      key: 'view-all',
      label: (
        <div style={{ textAlign: 'center' }}>
          <Text type="secondary" style={{ fontSize: 12 }}>
            View all notifications <RightOutlined style={{ fontSize: 10 }} />
          </Text>
        </div>
      ),
    },
  ];

  const handleNotificationClick = ({ key }: { key: string }) => {
    if (key === 'view-all') {
      navigate('/alerts');
      setNotificationsOpen(false);
    }
  };

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
    switch (key) {
      case 'logout':
        logout();
        break;
      case 'profile':
        navigate('/settings');
        break;
      case 'settings':
        navigate('/settings');
        break;
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
        {/* Language Switcher */}
        <LanguageSwitcher />

        {/* Currency Switcher */}
        <CurrencySwitcher />

        {/* Theme Toggle */}
        <Tooltip title={mode === 'dark' ? 'Light Mode' : 'Dark Mode'}>
          <Button
            type="text"
            icon={mode === 'dark' ? <SunOutlined /> : <MoonOutlined />}
            onClick={toggleMode}
            style={{ fontSize: 18 }}
          />
        </Tooltip>

        {/* Portal Hub - External Tools */}
        <PortalHub />

        {/* Notifications */}
        <Dropdown
          menu={{ items: notificationMenuItems, onClick: handleNotificationClick }}
          trigger={['click']}
          open={notificationsOpen}
          onOpenChange={setNotificationsOpen}
          placement="bottomRight"
          overlayStyle={{ minWidth: 340 }}
        >
          <Badge
            count={unresolvedCount || unreadNotifCount}
            overflowCount={99}
            style={{
              backgroundColor: criticalCount > 0 ? VG_COLORS.critical : VG_COLORS.warning,
            }}
          >
            <Button
              type="text"
              icon={<BellOutlined style={{ fontSize: 18 }} />}
            />
          </Badge>
        </Dropdown>

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
              style={{ backgroundColor: VG_COLORS.primary }}
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
