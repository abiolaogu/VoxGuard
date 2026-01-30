import type { ResourceProps } from '@refinedev/core';
import React from 'react';
import {
  DashboardOutlined,
  AlertOutlined,
  UserOutlined,
  BarChartOutlined,
  SettingOutlined,
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
    text: 'ACM Monitor',
    icon: '/favicon.ico',
  },
};
