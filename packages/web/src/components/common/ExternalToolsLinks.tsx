import { Card, List, Typography, Space, Tag, Tooltip } from 'antd';
import {
  LineChartOutlined,
  FireOutlined,
  ApiOutlined,
  TableOutlined,
  FieldTimeOutlined,
  PhoneOutlined,
  ExportOutlined,
} from '@ant-design/icons';
import { generateAlertContextLinks } from '../../config/external-services';
import { VG_COLORS } from '../../config/antd-theme';

const { Text } = Typography;

// Map icon names to components
const iconMap: Record<string, React.ReactNode> = {
  LineChartOutlined: <LineChartOutlined style={{ color: VG_COLORS.primary }} />,
  FireOutlined: <FireOutlined style={{ color: VG_COLORS.warning }} />,
  ApiOutlined: <ApiOutlined style={{ color: VG_COLORS.info }} />,
  TableOutlined: <TableOutlined style={{ color: VG_COLORS.success }} />,
  FieldTimeOutlined: <FieldTimeOutlined style={{ color: VG_COLORS.medium }} />,
  PhoneOutlined: <PhoneOutlined style={{ color: VG_COLORS.high }} />,
};

interface ExternalToolsLinksProps {
  alert: {
    carrier_name?: string;
    carrier_id?: string;
    b_number?: string;
    a_number?: string;
    created_at?: string;
  };
  compact?: boolean;
}

export const ExternalToolsLinks: React.FC<ExternalToolsLinksProps> = ({
  alert,
  compact = false,
}) => {
  const links = generateAlertContextLinks(alert);

  if (compact) {
    return (
      <Space wrap size="small">
        {links.map((link) => (
          <Tooltip key={link.id} title={link.description}>
            <Tag
              icon={iconMap[link.icon]}
              style={{ cursor: 'pointer' }}
              onClick={() => window.open(link.url, '_blank')}
            >
              {link.label} <ExportOutlined style={{ fontSize: 10 }} />
            </Tag>
          </Tooltip>
        ))}
      </Space>
    );
  }

  return (
    <Card
      title="External Analysis Tools"
      bordered={false}
      size="small"
      extra={
        <Text type="secondary" style={{ fontSize: 11 }}>
          Opens in new tab
        </Text>
      }
    >
      <List
        size="small"
        dataSource={links}
        renderItem={(link) => (
          <List.Item
            style={{ cursor: 'pointer', padding: '8px 0' }}
            onClick={() => window.open(link.url, '_blank')}
          >
            <List.Item.Meta
              avatar={iconMap[link.icon]}
              title={
                <Space>
                  <Text style={{ fontSize: 13 }}>{link.label}</Text>
                  <ExportOutlined style={{ fontSize: 10, color: VG_COLORS.textSecondary }} />
                </Space>
              }
              description={
                <Text type="secondary" style={{ fontSize: 11 }}>
                  {link.description}
                </Text>
              }
            />
          </List.Item>
        )}
      />
    </Card>
  );
};

export default ExternalToolsLinks;
