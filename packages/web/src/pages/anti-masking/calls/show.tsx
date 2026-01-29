import { Show } from '@refinedev/antd';
import { Card, Descriptions, Tag, Space, Typography, Row, Col, Timeline } from 'antd';
import { useShow } from '@refinedev/core';
import dayjs from 'dayjs';

import type { Call, CallStatus } from '@/types';

const { Text } = Typography;

const statusColors: Record<CallStatus, string> = {
    RINGING: 'processing',
    ACTIVE: 'blue',
    COMPLETED: 'success',
    FAILED: 'error',
    BLOCKED: 'red',
};

export const CallShow: React.FC = () => {
    const { queryResult } = useShow<Call>({
        meta: {
            fields: [
                'id',
                'call_id',
                'a_number',
                'b_number',
                'source_ip',
                'status',
                'is_flagged',
                'masking_detected',
                'confidence_score',
                'raw_cli',
                'verified_cli',
                'p_asserted_identity',
                'remote_party_id',
                'started_at',
                'answered_at',
                'ended_at',
                'duration_seconds',
                'metadata',
                { gateway: ['id', 'name', 'ip_address', 'carrier_name'] },
                { a_carrier: ['name'] },
                { b_carrier: ['name'] },
                { alert: ['id', 'severity', 'status'] },
            ],
        },
    });

    const { data, isLoading } = queryResult;
    const record = data?.data as any;
    const call: Call = record || {};

    return (
        <Show isLoading={isLoading}>
            <Space direction="vertical" size="large" style={{ width: '100%' }}>
                {/* Status Header */}
                <Space>
                    <Tag color={statusColors[record?.status as CallStatus]} style={{ fontSize: 14, padding: '4px 12px' }}>
                        {record?.status}
                    </Tag>
                    {record?.is_flagged && <Tag color="warning">Flagged</Tag>}
                    {record?.masking_detected && <Tag color="error">Masking Detected</Tag>}
                </Space>

                <Row gutter={16}>
                    <Col span={12}>
                        <Card title="Call Details">
                            <Descriptions column={1}>
                                <Descriptions.Item label="Call ID">
                                    <Text code copyable>{record?.call_id || record?.id}</Text>
                                </Descriptions.Item>
                                <Descriptions.Item label="A-Number (Caller)">
                                    <Text strong copyable>{record?.a_number}</Text>
                                    {record?.a_carrier && (
                                        <Tag style={{ marginLeft: 8 }}>{record.a_carrier.name}</Tag>
                                    )}
                                </Descriptions.Item>
                                <Descriptions.Item label="B-Number (Callee)">
                                    <Text strong copyable>{record?.b_number}</Text>
                                    {record?.b_carrier && (
                                        <Tag style={{ marginLeft: 8 }}>{record.b_carrier.name}</Tag>
                                    )}
                                </Descriptions.Item>
                                <Descriptions.Item label="Source IP">
                                    <Text code>{record?.source_ip}</Text>
                                </Descriptions.Item>
                                <Descriptions.Item label="Duration">
                                    {record?.duration_seconds != null
                                        ? `${Math.floor(record.duration_seconds / 60)}:${String(record.duration_seconds % 60).padStart(2, '0')}`
                                        : '-'}
                                </Descriptions.Item>
                            </Descriptions>
                        </Card>
                    </Col>

                    <Col span={12}>
                        <Card title="Gateway & Detection">
                            <Descriptions column={1}>
                                <Descriptions.Item label="Gateway">
                                    {record?.gateway?.name || '-'}
                                </Descriptions.Item>
                                <Descriptions.Item label="Gateway IP">
                                    <Text code>{record?.gateway?.ip_address || '-'}</Text>
                                </Descriptions.Item>
                                <Descriptions.Item label="Carrier">
                                    {record?.gateway?.carrier_name || '-'}
                                </Descriptions.Item>
                                <Descriptions.Item label="Confidence Score">
                                    {record?.confidence_score != null ? (
                                        <Text
                                            style={{
                                                color:
                                                    record.confidence_score >= 0.8
                                                        ? '#ff4d4f'
                                                        : record.confidence_score >= 0.5
                                                            ? '#faad14'
                                                            : '#52c41a',
                                            }}
                                        >
                                            {(record.confidence_score * 100).toFixed(1)}%
                                        </Text>
                                    ) : (
                                        '-'
                                    )}
                                </Descriptions.Item>
                            </Descriptions>
                        </Card>
                    </Col>
                </Row>

                {/* CLI Verification */}
                {(record?.raw_cli || record?.verified_cli) && (
                    <Card title="CLI Verification">
                        <Descriptions column={2}>
                            <Descriptions.Item label="Raw CLI">
                                <Text code>{record?.raw_cli || '-'}</Text>
                            </Descriptions.Item>
                            <Descriptions.Item label="Verified CLI">
                                <Text code>{record?.verified_cli || '-'}</Text>
                                {record?.raw_cli && record?.verified_cli && record.raw_cli !== record.verified_cli && (
                                    <Tag color="error" style={{ marginLeft: 8 }}>Mismatch</Tag>
                                )}
                            </Descriptions.Item>
                            <Descriptions.Item label="P-Asserted-Identity">
                                <Text code>{record?.p_asserted_identity || '-'}</Text>
                            </Descriptions.Item>
                            <Descriptions.Item label="Remote-Party-ID">
                                <Text code>{record?.remote_party_id || '-'}</Text>
                            </Descriptions.Item>
                        </Descriptions>
                    </Card>
                )}

                {/* Timeline */}
                <Card title="Call Timeline">
                    <Timeline
                        items={[
                            {
                                color: 'blue',
                                children: `Started at ${dayjs(record?.started_at).format('HH:mm:ss.SSS')}`,
                            },
                            ...(record?.answered_at
                                ? [{
                                    color: 'green',
                                    children: `Answered at ${dayjs(record.answered_at).format('HH:mm:ss.SSS')}`,
                                }]
                                : []),
                            ...(record?.ended_at
                                ? [{
                                    color: record?.status === 'COMPLETED' ? 'green' : 'red',
                                    children: `Ended at ${dayjs(record.ended_at).format('HH:mm:ss.SSS')}`,
                                }]
                                : []),
                        ]}
                    />
                </Card>

                {/* Related Alert */}
                {record?.alert && (
                    <Card title="Related Alert">
                        <Descriptions column={3}>
                            <Descriptions.Item label="Alert ID">
                                <Text copyable>{record.alert.id}</Text>
                            </Descriptions.Item>
                            <Descriptions.Item label="Severity">
                                <Tag color={record.alert.severity === 'CRITICAL' ? 'red' : 'orange'}>
                                    {record.alert.severity}
                                </Tag>
                            </Descriptions.Item>
                            <Descriptions.Item label="Status">
                                <Tag>{record.alert.status}</Tag>
                            </Descriptions.Item>
                        </Descriptions>
                    </Card>
                )}
            </Space>
        </Show>
    );
};

export default CallShow;
