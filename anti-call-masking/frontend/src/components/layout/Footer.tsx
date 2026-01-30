import { Layout, Typography, Space } from 'antd';

const { Text, Link } = Typography;

export const Footer: React.FC = () => {
  const currentYear = new Date().getFullYear();

  return (
    <Layout.Footer
      style={{
        textAlign: 'center',
        padding: '16px 24px',
        background: 'transparent',
      }}
    >
      <Space direction="vertical" size={4}>
        <Text type="secondary" style={{ fontSize: 12 }}>
          ACM Monitor - Anti-Call Masking Detection Platform
        </Text>
        <Text type="secondary" style={{ fontSize: 11 }}>
          &copy; {currentYear} Nigerian ICL Compliance System. All rights reserved.
        </Text>
        <Space split={<Text type="secondary">|</Text>} size={8}>
          <Link href="#" style={{ fontSize: 11 }}>
            Documentation
          </Link>
          <Link href="#" style={{ fontSize: 11 }}>
            Support
          </Link>
          <Link href="#" style={{ fontSize: 11 }}>
            Privacy Policy
          </Link>
        </Space>
      </Space>
    </Layout.Footer>
  );
};

export default Footer;
