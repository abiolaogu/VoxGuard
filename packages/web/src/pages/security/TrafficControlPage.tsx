import React, { useState, useEffect } from 'react';
import { Card, Table, Tag, Button, Switch, Typography, Space, Modal, Input, message } from 'antd';
import { PlusOutlined, DeleteOutlined } from '@ant-design/icons';
import { voxguardApi, type TrafficRule } from '../../api/voxguard';
import { AIDDTierBadge } from '../../components/common';

const { Title, Text } = Typography;

export const TrafficControlPage: React.FC = () => {
  const [rules, setRules] = useState<TrafficRule[]>([]);
  const [loading, setLoading] = useState(false);
  const [modalOpen, setModalOpen] = useState(false);
  const [newRule, setNewRule] = useState<Partial<TrafficRule>>({
    name: '',
    description: '',
    enabled: true,
    priority: 0,
    action: 'block',
  });

  const loadRules = () => {
    setLoading(true);
    voxguardApi
      .getTrafficRules()
      .then(setRules)
      .catch(() => {})
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    loadRules();
  }, []);

  const handleCreate = async () => {
    try {
      await voxguardApi.createTrafficRule(newRule);
      message.success('Rule created successfully');
      setModalOpen(false);
      setNewRule({ name: '', description: '', enabled: true, priority: 0, action: 'block' });
      loadRules();
    } catch {
      message.error('Failed to create rule');
    }
  };

  const handleDelete = async (id: string) => {
    try {
      await voxguardApi.deleteTrafficRule(id);
      message.success('Rule deleted successfully');
      loadRules();
    } catch {
      message.error('Failed to delete rule');
    }
  };

  const actionColor: Record<string, string> = {
    block: 'red',
    allow: 'green',
    throttle: 'orange',
    log: 'blue',
  };

  const columns = [
    { title: 'Name', dataIndex: 'name', key: 'name' },
    { title: 'Description', dataIndex: 'description', key: 'description', ellipsis: true },
    {
      title: 'Enabled',
      dataIndex: 'enabled',
      key: 'enabled',
      render: (enabled: boolean) => <Switch checked={enabled} size="small" />,
    },
    {
      title: 'Priority',
      dataIndex: 'priority',
      key: 'priority',
      sorter: (a: TrafficRule, b: TrafficRule) => a.priority - b.priority,
    },
    {
      title: 'Action',
      dataIndex: 'action',
      key: 'action',
      render: (action: string) => (
        <Tag color={actionColor[action] || 'default'}>{action.toUpperCase()}</Tag>
      ),
    },
    {
      title: 'Conditions',
      dataIndex: 'conditions',
      key: 'conditions',
      render: (conditions: TrafficRule['conditions']) => conditions?.length ?? 0,
    },
    { title: 'Hit Count', dataIndex: 'hit_count', key: 'hit_count' },
    {
      title: 'Actions',
      key: 'actions',
      render: (_: unknown, record: TrafficRule) => (
        <Space>
          <Button
            type="link"
            danger
            icon={<DeleteOutlined />}
            onClick={() => handleDelete(record.id)}
          >
            Delete
          </Button>
          <AIDDTierBadge tier={1} compact />
        </Space>
      ),
    },
  ];

  return (
    <div style={{ padding: 24 }}>
      <Title level={3}>Traffic Control</Title>
      <Text type="secondary">Manage traffic rules and filtering policies</Text>
      <div style={{ marginTop: 24 }}>
        <Card
          title={`Traffic Rules (${rules.length})`}
          extra={
            <Space>
              <Button type="primary" icon={<PlusOutlined />} onClick={() => setModalOpen(true)}>
                Create Rule
              </Button>
              <AIDDTierBadge tier={1} compact />
            </Space>
          }
        >
          <Table
            columns={columns}
            dataSource={rules}
            rowKey="id"
            size="small"
            loading={loading}
          />
        </Card>
      </div>

      <Modal
        title="Create Traffic Rule"
        open={modalOpen}
        onOk={handleCreate}
        onCancel={() => setModalOpen(false)}
        okText="Create"
      >
        <Space direction="vertical" style={{ width: '100%' }} size="middle">
          <div>
            <Text strong>Name</Text>
            <Input
              placeholder="Rule name"
              value={newRule.name}
              onChange={(e) => setNewRule({ ...newRule, name: e.target.value })}
            />
          </div>
          <div>
            <Text strong>Description</Text>
            <Input
              placeholder="Rule description"
              value={newRule.description}
              onChange={(e) => setNewRule({ ...newRule, description: e.target.value })}
            />
          </div>
          <div>
            <Text strong>Priority</Text>
            <Input
              type="number"
              placeholder="0"
              value={newRule.priority}
              onChange={(e) => setNewRule({ ...newRule, priority: parseInt(e.target.value, 10) || 0 })}
            />
          </div>
          <div>
            <Text strong>Action</Text>
            <Input
              placeholder="block, allow, throttle, log"
              value={newRule.action}
              onChange={(e) => setNewRule({ ...newRule, action: e.target.value })}
            />
          </div>
        </Space>
      </Modal>
    </div>
  );
};

export default TrafficControlPage;
