import React, { useState } from 'react';
import { Card, Table, Tag, Button, Typography, Space, Input, message } from 'antd';
import { UploadOutlined, SearchOutlined } from '@ant-design/icons';
import { AIDDTierBadge } from '../../components/common';

const { Title, Text } = Typography;

interface MNPRecord {
  id: string;
  msisdn: string;
  donor_network: string;
  recipient_network: string;
  ported_date: string;
  status: string;
}

const mockMNPData: MNPRecord[] = [
  { id: '1', msisdn: '+2348012345678', donor_network: 'MTN Nigeria', recipient_network: 'Airtel Nigeria', ported_date: '2025-04-10', status: 'active' },
  { id: '2', msisdn: '+2348098765432', donor_network: 'Glo Mobile', recipient_network: 'MTN Nigeria', ported_date: '2025-04-08', status: 'active' },
  { id: '3', msisdn: '+2349011223344', donor_network: 'Airtel Nigeria', recipient_network: '9mobile', ported_date: '2025-03-25', status: 'pending' },
  { id: '4', msisdn: '+2348055667788', donor_network: '9mobile', recipient_network: 'Glo Mobile', ported_date: '2025-03-15', status: 'active' },
];

export const MNPLookupPage: React.FC = () => {
  const [records] = useState<MNPRecord[]>(mockMNPData);
  const [searchValue, setSearchValue] = useState('');

  const handleImport = () => {
    message.success('MNP data import initiated');
  };

  const filteredRecords = records.filter(
    (r) =>
      r.msisdn.includes(searchValue) ||
      r.donor_network.toLowerCase().includes(searchValue.toLowerCase()) ||
      r.recipient_network.toLowerCase().includes(searchValue.toLowerCase())
  );

  const columns = [
    { title: 'MSISDN', dataIndex: 'msisdn', key: 'msisdn' },
    { title: 'Donor Network', dataIndex: 'donor_network', key: 'donor_network' },
    { title: 'Recipient Network', dataIndex: 'recipient_network', key: 'recipient_network' },
    { title: 'Ported Date', dataIndex: 'ported_date', key: 'ported_date' },
    {
      title: 'Status',
      dataIndex: 'status',
      key: 'status',
      render: (status: string) => (
        <Tag color={status === 'active' ? 'green' : status === 'pending' ? 'orange' : 'default'}>
          {status.toUpperCase()}
        </Tag>
      ),
    },
  ];

  return (
    <div style={{ padding: 24 }}>
      <Title level={3}>MNP Lookup</Title>
      <Text type="secondary">Mobile Number Portability database lookup and data import</Text>
      <div style={{ marginTop: 24 }}>
        <Card
          title={`MNP Records (${filteredRecords.length})`}
          extra={
            <Space>
              <Input
                placeholder="Search MSISDN or network"
                prefix={<SearchOutlined />}
                value={searchValue}
                onChange={(e) => setSearchValue(e.target.value)}
                style={{ width: 220 }}
                allowClear
              />
              <Button type="primary" icon={<UploadOutlined />} onClick={handleImport}>
                Import MNP Data
              </Button>
              <AIDDTierBadge tier={2} compact />
            </Space>
          }
        >
          <Table columns={columns} dataSource={filteredRecords} rowKey="id" size="small" />
        </Card>
      </div>
    </div>
  );
};

export default MNPLookupPage;
