import { Create, useForm } from '@refinedev/antd';
import { Form, Input, Select, InputNumber, Card, Row, Col, Typography } from 'antd';

import type { CreateGatewayInput, GatewayType } from '@/types';

const { Text } = Typography;

export const GatewayCreate: React.FC = () => {
    const { formProps, saveButtonProps } = useForm<CreateGatewayInput>({
        resource: 'gateways',
        action: 'create',
        redirect: 'list',
    });

    return (
        <Create saveButtonProps={saveButtonProps}>
            <Form {...formProps} layout="vertical">
                <Row gutter={16}>
                    <Col span={12}>
                        <Card title="Basic Information" style={{ marginBottom: 16 }}>
                            <Form.Item
                                label="Gateway Name"
                                name="name"
                                rules={[{ required: true, message: 'Name is required' }]}
                            >
                                <Input placeholder="e.g., MTN Primary Gateway" />
                            </Form.Item>

                            <Form.Item
                                label="IP Address"
                                name="ip_address"
                                rules={[
                                    { required: true, message: 'IP address is required' },
                                    {
                                        pattern: /^(\d{1,3}\.){3}\d{1,3}$/,
                                        message: 'Invalid IP address format',
                                    },
                                ]}
                            >
                                <Input placeholder="e.g., 192.168.1.100" />
                            </Form.Item>

                            <Form.Item
                                label="Carrier Name"
                                name="carrier_name"
                                rules={[{ required: true, message: 'Carrier is required' }]}
                            >
                                <Select
                                    placeholder="Select carrier"
                                    options={[
                                        { label: 'MTN Nigeria', value: 'MTN Nigeria' },
                                        { label: 'Globacom', value: 'Globacom' },
                                        { label: 'Airtel Nigeria', value: 'Airtel Nigeria' },
                                        { label: '9mobile', value: '9mobile' },
                                        { label: 'Other', value: 'Other' },
                                    ]}
                                />
                            </Form.Item>

                            <Form.Item
                                label="Gateway Type"
                                name="gateway_type"
                                rules={[{ required: true }]}
                                initialValue="LOCAL"
                            >
                                <Select
                                    options={[
                                        { label: 'Local', value: 'LOCAL' },
                                        { label: 'International', value: 'INTERNATIONAL' },
                                        { label: 'Transit', value: 'TRANSIT' },
                                    ]}
                                />
                            </Form.Item>
                        </Card>
                    </Col>

                    <Col span={12}>
                        <Card title="Thresholds & Limits" style={{ marginBottom: 16 }}>
                            <Form.Item
                                label="Fraud Threshold"
                                name="fraud_threshold"
                                initialValue={0.85}
                                help="Fraud score threshold (0-1). Scores above this trigger alerts."
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

                            <Form.Item
                                label="CPM Limit"
                                name="cpm_limit"
                                initialValue={60}
                                help="Maximum calls per minute allowed"
                            >
                                <InputNumber min={1} max={1000} style={{ width: '100%' }} />
                            </Form.Item>

                            <Form.Item
                                label="ACD Threshold"
                                name="acd_threshold"
                                initialValue={10.0}
                                help="Average Call Duration threshold in seconds"
                            >
                                <InputNumber min={1} max={600} step={0.5} style={{ width: '100%' }} />
                            </Form.Item>
                        </Card>
                    </Col>
                </Row>
            </Form>
        </Create>
    );
};

export default GatewayCreate;
