import { useState } from 'react';
import { Layout, theme, Typography, Space, Avatar, Dropdown, Badge, Button } from 'antd';
import {
    BellOutlined,
    SettingOutlined,
    UserOutlined,
    LogoutOutlined,
    MoonOutlined,
    SunOutlined,
} from '@ant-design/icons';
import { useGetIdentity, useLogout } from '@refinedev/core';

const { Header: AntHeader } = Layout;
const { Text } = Typography;

interface UserIdentity {
    id: string;
    name: string;
    email: string;
    avatar?: string;
    role: string;
}

export const Header: React.FC = () => {
    const { token } = theme.useToken();
    const { data: user } = useGetIdentity<UserIdentity>();
    const { mutate: logout } = useLogout();
    const [isDark, setIsDark] = useState(false);

    const menuItems = [
        {
            key: 'profile',
            label: 'Profile',
            icon: <UserOutlined />,
        },
        {
            key: 'settings',
            label: 'Settings',
            icon: <SettingOutlined />,
        },
        {
            type: 'divider' as const,
        },
        {
            key: 'logout',
            label: 'Logout',
            icon: <LogoutOutlined />,
            danger: true,
            onClick: () => logout(),
        },
    ];

    return (
        <AntHeader
            style={{
                backgroundColor: token.colorBgContainer,
                borderBottom: `1px solid ${token.colorBorderSecondary}`,
                padding: '0 24px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                position: 'sticky',
                top: 0,
                zIndex: 100,
            }}
        >
            <div>
                <Text strong style={{ fontSize: 18 }}>
                    Anti-Call Masking Platform
                </Text>
            </div>

            <Space size="large">
                <Button
                    type="text"
                    icon={isDark ? <SunOutlined /> : <MoonOutlined />}
                    onClick={() => setIsDark(!isDark)}
                />

                <Badge count={5} size="small">
                    <Button type="text" icon={<BellOutlined />} />
                </Badge>

                <Dropdown menu={{ items: menuItems }} trigger={['click']}>
                    <Space style={{ cursor: 'pointer' }}>
                        <Avatar
                            src={user?.avatar}
                            icon={!user?.avatar && <UserOutlined />}
                            style={{ backgroundColor: token.colorPrimary }}
                        />
                        <div style={{ lineHeight: 1.2 }}>
                            <Text strong style={{ display: 'block' }}>
                                {user?.name || 'Guest'}
                            </Text>
                            <Text type="secondary" style={{ fontSize: 12 }}>
                                {user?.role || 'User'}
                            </Text>
                        </div>
                    </Space>
                </Dropdown>
            </Space>
        </AntHeader>
    );
};

export default Header;
