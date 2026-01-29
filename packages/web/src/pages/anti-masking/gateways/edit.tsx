import { Edit, useForm } from '@refinedev/antd';
import { Form, Input, Select, InputNumber, Card, Row, Col, Descriptions, Tag } from 'antd';

import type { Gateway, UpdateGatewayInput } from '@/types';

export const GatewayEdit: React.FC = () => {
    const { formProps, saveButtonProps, queryResult } = useForm<Gateway, unknown, UpdateGatewayInput>({
        resource: 'gateways',
        action: 'edit',
        redirect: 'list',
        meta: {
            fields: [
                'id',
                'name',
                'ip_address',
                'carrier_name',
                'gateway_type',
                'is_active',
                'is_blacklisted',
                'fraud_threshold',
                'cpm_limit',
                'acd_threshold',
                'total_calls',
                'fraud_calls',
                'created_at',
            ],
        },
    });

    const gateway = queryResult?.data?.data as any;

    return (
        <Edit saveButtonProps={saveButtonProps}>
            <Row gutter={16}>
                <Col span={16}>
                    <Form {...formProps} layout="vertical">
                        <Card title="Gateway Configuration" style={{ marginBottom: 16 }}>
                            <Form.Item
                                label="Gateway Name"
                                name="name"
                                rules={[{ required: true }]}
                            >
                                <Input />
                            </Form.Item>

                            <Row gutter={16}>
                                <Col span={12}>
                                    <Form.Item
                                        label="Fraud Threshold"
                                        name="fraud_threshold"
                                    >
                                        <InputNumber
                                            min={0}
                                            max={1}
                                            step={0.05}
                                            style={{ width: '100%' }}
                                            formatter={(value) => `${(Number(value) * 100).toFixed(0)}%`}
                                            parser={(value) => Number(value?.replace('%', '')) / 100}
                                        />
                                    </Form.Item>
                                </Col>
                                <Col span={12}>
                                    <Form.Item
                                        label="CPM Limit"
                                        name="cpm_limit"
                                    >
                                        <InputNumber min={1} max={1000} style={{ width: '100%' }} />
                                    </Form.Item>
                                </Col>
                            </Row>

                            <Form.Item
                                label="ACD Threshold (seconds)"
                                name="acd_threshold"
                            >
                                <InputNumber min={1} max={600} step={0.5} style={{ width: '100%' }} />
                            </Form.Item>
                        </Card>
                    </Form>
                </Col>

                <Col span={8}>
                    <Card title="Gateway Info">
                        <Descriptions column={1} size="small">
                            <Descriptions.Item label="IP Address">
                                {gateway?.ip_address}
                            </Descriptions.Item>
                            <Descriptions.Item label="Carrier">
                                {gateway?.carrier_name}
                            </Descriptions.Item>
                            <Descriptions.Item label="Type">
                                <Tag>{gateway?.gateway_type}</Tag>
                            </Descriptions.Item>
                            <Descriptions.Item label="Status">
                                {gateway?.is_blacklisted ? (
                                    <Tag color="error">Blacklisted</Tag>
                                ) : gateway?.is_active ? (
                                    <Tag color="success">Active</Tag>
                                ) : (
                                    <Tag>Inactive</Tag>
                                )}
                            </Descriptions.Item>
                            <Descriptions.Item label="Total Calls">
                                {gateway?.total_calls?.toLocaleString() || 0}
                            </Descriptions.Item>
                            <Descriptions.Item label="Flagged Calls">
                                {gateway?.fraud_calls || 0}
                            </Descriptions.Item>
                        </Descriptions>
                    </Card>
                </Col>
            </Row>
        </Edit>
    );
};

export default GatewayEdit;
