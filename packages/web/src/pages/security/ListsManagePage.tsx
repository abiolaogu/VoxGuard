import React, { useState, useEffect } from 'react';
import { Card, Table, Tag, Button, Tabs, Typography, Space, Modal, Input, message } from 'antd';
import { PlusOutlined, DeleteOutlined } from '@ant-design/icons';
import { voxguardApi, type ListEntry } from '../../api/voxguard';

const { Title, Text } = Typography;

export const ListsManagePage: React.FC = () => {
  const [blacklist, setBlacklist] = useState<ListEntry[]>([]);
  const [whitelist, setWhitelist] = useState<ListEntry[]>([]);
  const [loading, setLoading] = useState(false);
  const [modalOpen, setModalOpen] = useState(false);
  const [activeTab, setActiveTab] = useState('blacklist');
  const [newEntry, setNewEntry] = useState<Partial<ListEntry>>({
    pattern: '',
    pattern_type: 'number',
    reason: '',
    source: 'manual',
  });

  const loadEntries = () => {
    setLoading(true);
    Promise.all([
      voxguardApi.getListEntries('blacklist').then(setBlacklist).catch(() => {}),
      voxguardApi.getListEntries('whitelist').then(setWhitelist).catch(() => {}),
    ]).finally(() => setLoading(false));
  };

  useEffect(() => {
    loadEntries();
  }, []);

  const handleAdd = async () => {
    try {
      await voxguardApi.createListEntry({ ...newEntry, list_type: activeTab as 'blacklist' | 'whitelist' });
      message.success('Entry added successfully');
      setModalOpen(false);
      setNewEntry({ pattern: '', pattern_type: 'number', reason: '', source: 'manual' });
      loadEntries();
    } catch {
      message.error('Failed to add entry');
    }
  };

  const handleDelete = async (id: string) => {
    try {
      await voxguardApi.deleteListEntry(id);
      message.success('Entry deleted successfully');
      loadEntries();
    } catch {
      message.error('Failed to delete entry');
    }
  };

  const columns = [
    { title: 'Pattern', dataIndex: 'pattern', key: 'pattern' },
    {
      title: 'Type',
      dataIndex: 'pattern_type',
      key: 'pattern_type',
      render: (type: string) => <Tag>{type}</Tag>,
    },
    { title: 'Reason', dataIndex: 'reason', key: 'reason', ellipsis: true },
    { title: 'Added By', dataIndex: 'added_by', key: 'added_by' },
    { title: 'Hit Count', dataIndex: 'hit_count', key: 'hit_count' },
    {
      title: 'Expires',
      dataIndex: 'expires_at',
      key: 'expires_at',
      render: (date: string | undefined) => date || '—',
    },
    {
      title: 'Source',
      dataIndex: 'source',
      key: 'source',
      render: (source: string) => (
        <Tag color={source === 'manual' ? 'blue' : source === 'auto' ? 'purple' : 'default'}>
          {source}
        </Tag>
      ),
    },
    {
      title: 'Actions',
      key: 'actions',
      render: (_: unknown, record: ListEntry) => (
        <Button
          type="link"
          danger
          icon={<DeleteOutlined />}
          onClick={() => handleDelete(record.id)}
        >
          Delete
        </Button>
      ),
    },
  ];

  const tabItems = [
    {
      key: 'blacklist',
      label: `Blacklist (${blacklist.length})`,
      children: (
        <Card
          title="Blacklist Entries"
          extra={
            <Button type="primary" icon={<PlusOutlined />} onClick={() => setModalOpen(true)}>
              Add Entry
            </Button>
          }
        >
          <Table
            columns={columns}
            dataSource={blacklist}
            rowKey="id"
            size="small"
            loading={loading}
          />
        </Card>
      ),
    },
    {
      key: 'whitelist',
      label: `Whitelist (${whitelist.length})`,
      children: (
        <Card
          title="Whitelist Entries"
          extra={
            <Button type="primary" icon={<PlusOutlined />} onClick={() => setModalOpen(true)}>
              Add Entry
            </Button>
          }
        >
          <Table
            columns={columns}
            dataSource={whitelist}
            rowKey="id"
            size="small"
            loading={loading}
          />
        </Card>
      ),
    },
  ];

  return (
    <div style={{ padding: 24 }}>
      <Title level={3}>List Management</Title>
      <Text type="secondary">Manage blacklist and whitelist entries</Text>
      <div style={{ marginTop: 24 }}>
        <Tabs items={tabItems} activeKey={activeTab} onChange={setActiveTab} />
      </div>

      <Modal
        title={`Add ${activeTab === 'blacklist' ? 'Blacklist' : 'Whitelist'} Entry`}
        open={modalOpen}
        onOk={handleAdd}
        onCancel={() => setModalOpen(false)}
        okText="Add"
      >
        <Space direction="vertical" style={{ width: '100%' }} size="middle">
          <div>
            <Text strong>Pattern</Text>
            <Input
              placeholder="e.g. +44123456789 or +44*"
              value={newEntry.pattern}
              onChange={(e) => setNewEntry({ ...newEntry, pattern: e.target.value })}
            />
          </div>
          <div>
            <Text strong>Pattern Type</Text>
            <Input
              placeholder="number, prefix, regex"
              value={newEntry.pattern_type}
              onChange={(e) => setNewEntry({ ...newEntry, pattern_type: e.target.value })}
            />
          </div>
          <div>
            <Text strong>Reason</Text>
            <Input
              placeholder="Reason for adding"
              value={newEntry.reason}
              onChange={(e) => setNewEntry({ ...newEntry, reason: e.target.value })}
            />
          </div>
        </Space>
      </Modal>
    </div>
  );
};

export default ListsManagePage;
