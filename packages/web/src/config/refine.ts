import type { ResourceProps } from '@refinedev/core';
import React from 'react';
import {
  DashboardOutlined,
  AlertOutlined,
  UserOutlined,
  BarChartOutlined,
  SettingOutlined,
  SafetyCertificateOutlined,
  AimOutlined,
  UnorderedListOutlined,
  PhoneOutlined,
  DollarOutlined,
  ControlOutlined,
  CheckCircleOutlined,
  FileTextOutlined,
  SwapOutlined,
} from '@ant-design/icons';

// Resource definitions for Refine
export const resources: ResourceProps[] = [
  {
    name: 'dashboard',
    list: '/dashboard',
    meta: {
      label: 'Dashboard',
      icon: React.createElement(DashboardOutlined),
    },
  },
  {
    name: 'acm_alerts',
    list: '/alerts',
    show: '/alerts/show/:id',
    edit: '/alerts/edit/:id',
    meta: {
      label: 'Alerts',
      icon: React.createElement(AlertOutlined),
      canDelete: false,
    },
  },
  {
    name: 'acm_users',
    list: '/users',
    show: '/users/show/:id',
    create: '/users/create',
    edit: '/users/edit/:id',
    meta: {
      label: 'Users',
      icon: React.createElement(UserOutlined),
    },
  },
  {
    name: 'analytics',
    list: '/analytics',
    meta: {
      label: 'Analytics',
      icon: React.createElement(BarChartOutlined),
    },
  },
  {
    name: 'acm_settings',
    list: '/settings',
    edit: '/settings',
    meta: {
      label: 'Settings',
      icon: React.createElement(SettingOutlined),
      canDelete: false,
    },
  },
  // VoxGuard Security Pages (from VoxSwitch-IM)
  {
    name: 'rvs_dashboard',
    list: '/security/rvs-dashboard',
    meta: {
      label: 'RVS Dashboard',
      icon: React.createElement(SafetyCertificateOutlined),
      parent: 'security',
    },
  },
  {
    name: 'composite_scoring',
    list: '/security/composite-scoring',
    meta: {
      label: 'Composite Scoring',
      icon: React.createElement(AimOutlined),
      parent: 'security',
    },
  },
  {
    name: 'lists_manage',
    list: '/security/lists-manage',
    meta: {
      label: 'Lists Management',
      icon: React.createElement(UnorderedListOutlined),
      parent: 'security',
    },
  },
  {
    name: 'multicall_detection',
    list: '/security/multicall-detection',
    meta: {
      label: 'Multi-Call Detection',
      icon: React.createElement(PhoneOutlined),
      parent: 'security',
    },
  },
  {
    name: 'revenue_fraud',
    list: '/security/revenue-fraud',
    meta: {
      label: 'Revenue Fraud',
      icon: React.createElement(DollarOutlined),
      parent: 'security',
    },
  },
  {
    name: 'traffic_control',
    list: '/security/traffic-control',
    meta: {
      label: 'Traffic Control',
      icon: React.createElement(ControlOutlined),
      parent: 'security',
    },
  },
  {
    name: 'false_positives',
    list: '/security/false-positives',
    meta: {
      label: 'False Positives',
      icon: React.createElement(CheckCircleOutlined),
      parent: 'security',
    },
  },
  // NCC Compliance
  {
    name: 'ncc_compliance',
    list: '/ncc/reports',
    meta: {
      label: 'NCC Compliance',
      icon: React.createElement(FileTextOutlined),
    },
  },
  // MNP Lookup
  {
    name: 'mnp_lookup',
    list: '/mnp/lookup',
    meta: {
      label: 'MNP Lookup',
      icon: React.createElement(SwapOutlined),
    },
  },
];

// Navigation items for the sidebar
export const menuItems = [
  {
    key: 'dashboard',
    label: 'Dashboard',
    route: '/dashboard',
    icon: 'DashboardOutlined',
  },
  {
    key: 'alerts',
    label: 'Alerts',
    route: '/alerts',
    icon: 'AlertOutlined',
  },
  {
    key: 'security',
    label: 'Security',
    icon: 'SafetyCertificateOutlined',
    children: [
      { key: 'rvs-dashboard', label: 'RVS Dashboard', route: '/security/rvs-dashboard' },
      { key: 'composite-scoring', label: 'Composite Scoring', route: '/security/composite-scoring' },
      { key: 'lists-manage', label: 'Lists Management', route: '/security/lists-manage' },
      { key: 'multicall-detection', label: 'Multi-Call Detection', route: '/security/multicall-detection' },
      { key: 'revenue-fraud', label: 'Revenue Fraud', route: '/security/revenue-fraud' },
      { key: 'traffic-control', label: 'Traffic Control', route: '/security/traffic-control' },
      { key: 'false-positives', label: 'False Positives', route: '/security/false-positives' },
    ],
  },
  {
    key: 'ncc',
    label: 'NCC Compliance',
    route: '/ncc/reports',
    icon: 'FileTextOutlined',
  },
  {
    key: 'mnp',
    label: 'MNP Lookup',
    route: '/mnp/lookup',
    icon: 'SwapOutlined',
  },
  {
    key: 'users',
    label: 'Users',
    route: '/users',
    icon: 'UserOutlined',
  },
  {
    key: 'analytics',
    label: 'Analytics',
    route: '/analytics',
    icon: 'BarChartOutlined',
  },
  {
    key: 'settings',
    label: 'Settings',
    route: '/settings',
    icon: 'SettingOutlined',
  },
];

// Refine options
export const refineOptions = {
  syncWithLocation: true,
  warnWhenUnsavedChanges: true,
  useNewQueryKeys: true,
  projectId: 'acm-admin-dashboard',
  title: {
    text: 'VoxGuard',
    icon: '/favicon.ico',
  },
};
