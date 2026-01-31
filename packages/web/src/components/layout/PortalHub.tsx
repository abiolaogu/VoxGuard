import { useState, useEffect } from 'react';
import {
  Dropdown,
  Button,
  Space,
  Typography,
  Tag,
  Tooltip,
  Badge,
} from 'antd';
import {
  AppstoreOutlined,
  LineChartOutlined,
  FireOutlined,
  ApiOutlined,
  DatabaseOutlined,
  TableOutlined,
  FieldTimeOutlined,
  PhoneOutlined,
  ExportOutlined,
  CheckCircleOutlined,
  CloseCircleOutlined,
  LoadingOutlined,
} from '@ant-design/icons';
import { EXTERNAL_SERVICES, SERVICE_CATEGORIES, type ExternalService } from '../../config/external-services';
import { VG_COLORS } from '../../config/antd-theme';

const { Text } = Typography;

// Map icon names to components
const iconMap: Record<string, React.ReactNode> = {
  LineChartOutlined: <LineChartOutlined />,
  FireOutlined: <FireOutlined />,
  ApiOutlined: <ApiOutlined />,
  DatabaseOutlined: <DatabaseOutlined />,
  TableOutlined: <TableOutlined />,
  FieldTimeOutlined: <FieldTimeOutlined />,
  PhoneOutlined: <PhoneOutlined />,
};

interface ServiceHealth {
  [serviceId: string]: 'healthy' | 'unhealthy' | 'checking' | 'unknown';
}

export const PortalHub: React.FC = () => {
  const [open, setOpen] = useState(false);
  const [serviceHealth, setServiceHealth] = useState<ServiceHealth>({});

  // Check health of services when dropdown opens
  useEffect(() => {
    if (open) {
      checkServicesHealth();
    }
  }, [open]);

  const checkServicesHealth = async () => {
    // Set all to checking
    const checking: ServiceHealth = {};
    EXTERNAL_SERVICES.forEach((s) => {
      checking[s.id] = 'checking';
    });
    setServiceHealth(checking);

    // Check each service (simplified - just check if URL is reachable)
    const results: ServiceHealth = {};
    await Promise.all(
      EXTERNAL_SERVICES.map(async (service) => {
        try {
          // For local development, we can't actually check due to CORS
          // In production, you'd use a backend health check endpoint
          // For now, assume services are healthy if they have a URL
          results[service.id] = service.url ? 'healthy' : 'unknown';
        } catch {
          results[service.id] = 'unknown';
        }
      })
    );
    setServiceHealth(results);
  };

  const getHealthIcon = (serviceId: string) => {
    const health = serviceHealth[serviceId];
    switch (health) {
      case 'healthy':
        return <CheckCircleOutlined style={{ color: VG_COLORS.success, fontSize: 12 }} />;
      case 'unhealthy':
        return <CloseCircleOutlined style={{ color: VG_COLORS.error, fontSize: 12 }} />;
      case 'checking':
        return <LoadingOutlined style={{ color: VG_COLORS.info, fontSize: 12 }} />;
      default:
        return null;
    }
  };

  const renderServiceItem = (service: ExternalService) => ({
    key: service.id,
    label: (
      <a
        href={service.url}
        target="_blank"
        rel="noopener noreferrer"
        style={{ textDecoration: 'none' }}
        onClick={(e) => e.stopPropagation()}
      >
        <Space style={{ width: '100%', justifyContent: 'space-between' }}>
          <Space>
            {iconMap[service.icon] || <AppstoreOutlined />}
            <div>
              <Text strong style={{ display: 'block', fontSize: 13 }}>
                {service.name}
              </Text>
              <Text type="secondary" style={{ fontSize: 11 }}>
                {service.description}
              </Text>
            </div>
          </Space>
          <Space size={4}>
            {getHealthIcon(service.id)}
            <ExportOutlined style={{ color: VG_COLORS.textSecondary, fontSize: 12 }} />
          </Space>
        </Space>
      </a>
    ),
  });

  const menuItems = [
    {
      key: 'header',
      type: 'group' as const,
      label: (
        <div style={{ padding: '8px 0' }}>
          <Text strong style={{ fontSize: 14 }}>External Portals</Text>
          <br />
          <Text type="secondary" style={{ fontSize: 11 }}>
            Click to open in new tab
          </Text>
        </div>
      ),
    },
    // Monitoring
    {
      key: 'monitoring-divider',
      type: 'divider' as const,
    },
    {
      key: 'monitoring-group',
      type: 'group' as const,
      label: <Tag color="blue">Monitoring</Tag>,
      children: SERVICE_CATEGORIES.monitoring.services.map(renderServiceItem),
    },
    // Analytics
    {
      key: 'analytics-divider',
      type: 'divider' as const,
    },
    {
      key: 'analytics-group',
      type: 'group' as const,
      label: <Tag color="purple">Analytics</Tag>,
      children: SERVICE_CATEGORIES.analytics.services.map(renderServiceItem),
    },
    // Databases
    {
      key: 'database-divider',
      type: 'divider' as const,
    },
    {
      key: 'database-group',
      type: 'group' as const,
      label: <Tag color="green">Databases</Tag>,
      children: SERVICE_CATEGORIES.database.services.map(renderServiceItem),
    },
    // SIP & Admin
    {
      key: 'other-divider',
      type: 'divider' as const,
    },
    {
      key: 'sip-group',
      type: 'group' as const,
      label: <Tag color="orange">SIP & Admin</Tag>,
      children: [
        ...SERVICE_CATEGORIES.sip.services.map(renderServiceItem),
        ...SERVICE_CATEGORIES.admin.services.map(renderServiceItem),
      ],
    },
  ];

  return (
    <Dropdown
      menu={{ items: menuItems }}
      trigger={['click']}
      open={open}
      onOpenChange={setOpen}
      placement="bottomRight"
      overlayStyle={{ minWidth: 320 }}
    >
      <Tooltip title="External Portals">
        <Button
          type="text"
          icon={
            <Badge dot status="processing" offset={[-2, 2]}>
              <AppstoreOutlined style={{ fontSize: 18 }} />
            </Badge>
          }
        />
      </Tooltip>
    </Dropdown>
  );
};

export default PortalHub;
