import { useState } from 'react';
import { Layout, Menu, theme } from 'antd';
import { useMenu, useNavigation, useResource } from '@refinedev/core';
import {
    DashboardOutlined,
    AlertOutlined,
    PhoneOutlined,
    ApiOutlined,
    SwapOutlined,
    BankOutlined,
    TeamOutlined,
    ShopOutlined,
    ShoppingCartOutlined,
    SafetyOutlined,
    SendOutlined,
    AppstoreOutlined,
} from '@ant-design/icons';
import type { MenuProps } from 'antd';

const { Sider: AntSider } = Layout;

type MenuItem = Required<MenuProps>['items'][number];

export const Sider: React.FC = () => {
    const { token } = theme.useToken();
    const [collapsed, setCollapsed] = useState(false);
    const { push } = useNavigation();
    const { resource } = useResource();

    const menuItems: MenuItem[] = [
        {
            key: 'dashboard',
            icon: <DashboardOutlined />,
            label: 'Dashboard',
            onClick: () => push('/dashboard'),
        },
        {
            key: 'anti-masking',
            icon: <SafetyOutlined />,
            label: 'Anti-Masking',
            children: [
                {
                    key: 'fraud-alerts',
                    icon: <AlertOutlined />,
                    label: 'Fraud Alerts',
                    onClick: () => push('/anti-masking/fraud-alerts'),
                },
                {
                    key: 'gateways',
                    icon: <ApiOutlined />,
                    label: 'Gateways',
                    onClick: () => push('/anti-masking/gateways'),
                },
                {
                    key: 'calls',
                    icon: <PhoneOutlined />,
                    label: 'Call Log',
                    onClick: () => push('/anti-masking/calls'),
                },
            ],
        },
        {
            key: 'remittance',
            icon: <SendOutlined />,
            label: 'Remittance',
            children: [
                {
                    key: 'corridors',
                    icon: <SwapOutlined />,
                    label: 'Corridors',
                    onClick: () => push('/remittance/corridors'),
                },
                {
                    key: 'transactions',
                    icon: <BankOutlined />,
                    label: 'Transactions',
                    onClick: () => push('/remittance/transactions'),
                },
                {
                    key: 'beneficiaries',
                    icon: <TeamOutlined />,
                    label: 'Beneficiaries',
                    onClick: () => push('/remittance/beneficiaries'),
                },
            ],
        },
        {
            key: 'marketplace',
            icon: <AppstoreOutlined />,
            label: 'Marketplace',
            children: [
                {
                    key: 'listings',
                    icon: <ShopOutlined />,
                    label: 'Listings',
                    onClick: () => push('/marketplace/listings'),
                },
                {
                    key: 'orders',
                    icon: <ShoppingCartOutlined />,
                    label: 'Orders',
                    onClick: () => push('/marketplace/orders'),
                },
            ],
        },
    ];

    return (
        <AntSider
            collapsible
            collapsed={collapsed}
            onCollapse={setCollapsed}
            breakpoint="lg"
            style={{
                backgroundColor: token.colorBgContainer,
                borderRight: `1px solid ${token.colorBorderSecondary}`,
                overflow: 'auto',
                height: '100vh',
                position: 'fixed',
                left: 0,
                top: 0,
                bottom: 0,
            }}
        >
            <div
                style={{
                    height: 64,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    borderBottom: `1px solid ${token.colorBorderSecondary}`,
                }}
            >
                <img
                    src="/logo.svg"
                    alt="ACM"
                    style={{
                        height: 32,
                        transition: 'all 0.3s',
                    }}
                />
                {!collapsed && (
                    <span
                        style={{
                            marginLeft: 12,
                            fontWeight: 600,
                            fontSize: 16,
                            color: token.colorText,
                        }}
                    >
                        ACM
                    </span>
                )}
            </div>

            <Menu
                mode="inline"
                selectedKeys={[resource?.name || 'dashboard']}
                defaultOpenKeys={['anti-masking']}
                items={menuItems}
                style={{
                    borderRight: 0,
                    marginTop: 8,
                }}
            />
        </AntSider>
    );
};

export default Sider;
