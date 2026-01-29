import { Show } from '@refinedev/antd';
import {
    Card,
    Descriptions,
    Tag,
    Space,
    Button,
    Typography,
    Timeline,
    Table,
    Row,
    Col,
    Divider,
    Modal,
    Input,
    Select,
    message,
} from 'antd';
import {
    CheckCircleOutlined,
    ExclamationCircleOutlined,
    SendOutlined,
    AlertOutlined,
} from '@ant-design/icons';
import { useShow, useUpdate, useCustomMutation } from '@refinedev/core';
import { useState } from 'react';
import dayjs from 'dayjs';

import type { FraudAlert, Call, Severity, AlertStatus, ResolutionType } from '@/types';

const { Title, Text } = Typography;
const { TextArea } = Input;

const severityColors: Record<Severity, string> = {
    LOW: 'blue',
    MEDIUM: 'gold',
    HIGH: 'orange',
    CRITICAL: 'red',
};

export const FraudAlertShow: React.FC = () => {
    const { queryResult } = useShow<FraudAlert>({
        meta: {
            fields: [
                'id',
                'b_number',
                'fraud_type',
                'score',
                'severity',
                'distinct_callers',
                'a_numbers',
                'source_ips',
                'status',
                'acknowledged_by',
                'acknowledged_at',
                'resolved_by',
                'resolved_at',
                'resolution',
                'resolution_notes',
                'ncc_reported',
                'ncc_report_id',
                'detected_at',
                'window_start',
                'window_end',
                {
                    calls: [
                        'id',
                        'a_number',
                        'source_ip',
                        'status',
                        'confidence_score',
                        'started_at',
                    ],
                },
            ],
        },
    });

    const { data, isLoading } = queryResult;
    const record = data?.data as any;
    const alert: FraudAlert = record ? {
        ...record,
        bNumber: record.b_number,
        fraudType: record.fraud_type,
        distinctCallers: record.distinct_callers,
        aNumbers: record.a_numbers,
        sourceIps: record.source_ips,
        acknowledgedBy: record.acknowledged_by,
        acknowledgedAt: record.acknowledged_at,
        resolvedBy: record.resolved_by,
        resolvedAt: record.resolved_at,
        resolutionNotes: record.resolution_notes,
        nccReportId: record.ncc_report_id,
        detectedAt: record.detected_at,
        windowStart: record.window_start,
        windowEnd: record.window_end,
    } : {} as FraudAlert;

    const [resolveModalOpen, setResolveModalOpen] = useState(false);
    const [resolution, setResolution] = useState<ResolutionType>('CONFIRMED_FRAUD');
    const [notes, setNotes] = useState('');

    const { mutate: updateAlert } = useUpdate();
    const { mutate: reportToNCC, isLoading: isReporting } = useCustomMutation();

    const handleAcknowledge = () => {
        updateAlert({
            resource: 'fraud_alerts',
            id: alert.id,
            values: {
                status: 'ACKNOWLEDGED',
                acknowledged_at: new Date().toISOString(),
                acknowledged_by: 'current_user', // Replace with actual user
            },
        });
    };

    const handleResolve = () => {
        updateAlert({
            resource: 'fraud_alerts',
            id: alert.id,
            values: {
                status: 'RESOLVED',
                resolved_at: new Date().toISOString(),
                resolved_by: 'current_user',
                resolution,
                resolution_notes: notes,
            },
        });
        setResolveModalOpen(false);
        message.success('Alert resolved');
    };

    const handleReportNCC = () => {
        Modal.confirm({
            title: 'Report to NCC',
            content: 'Are you sure you want to submit this alert to NCC ATRS?',
            onOk: () => {
                reportToNCC({
                    url: '',
                    method: 'post',
                    values: { alertId: alert.id },
                    meta: {
                        gqlMutation: `
              mutation ReportToNCC($alertId: uuid!) {
                reportToNCC(alert_id: $alertId) {
                  success
                  message
                }
              }
            `,
                        variables: { alertId: alert.id },
                    },
                });
            },
        });
    };

    const callColumns = [
        { title: 'A-Number', dataIndex: 'a_number', key: 'a_number' },
        { title: 'Source IP', dataIndex: 'source_ip', key: 'source_ip' },
        {
            title: 'Score',
            dataIndex: 'confidence_score',
            key: 'confidence_score',
            render: (val: number) => `${(val * 100).toFixed(0)}%`,
        },
        {
            title: 'Time',
            dataIndex: 'started_at',
            key: 'started_at',
            render: (val: string) => dayjs(val).format('HH:mm:ss'),
        },
        {
            title: 'Status',
            dataIndex: 'status',
            key: 'status',
            render: (val: string) => <Tag>{val}</Tag>,
        },
    ];

    return (
        <Show isLoading={isLoading}>
            <Space direction="vertical" size="large" style={{ width: '100%' }}>
                {/* Header Actions */}
                <Row justify="space-between">
                    <Col>
                        <Space>
                            <Tag color={severityColors[alert.severity]} style={{ fontSize: 14, padding: '4px 12px' }}>
                                {alert.severity}
                            </Tag>
                            <Tag style={{ fontSize: 14, padding: '4px 12px' }}>
                                {alert.status?.replace('_', ' ')}
                            </Tag>
                            {alert.nccReported && <Tag color="purple">NCC Reported</Tag>}
                        </Space>
                    </Col>
                    <Col>
                        <Space>
                            {alert.status === 'PENDING' && (
                                <Button
                                    type="primary"
                                    icon={<CheckCircleOutlined />}
                                    onClick={handleAcknowledge}
                                >
                                    Acknowledge
                                </Button>
                            )}
                            {['PENDING', 'ACKNOWLEDGED', 'INVESTIGATING'].includes(alert.status) && (
                                <Button
                                    icon={<ExclamationCircleOutlined />}
                                    onClick={() => setResolveModalOpen(true)}
                                >
                                    Resolve
                                </Button>
                            )}
                            {!alert.nccReported && alert.status !== 'PENDING' && (
                                <Button
                                    danger
                                    icon={<SendOutlined />}
                                    loading={isReporting}
                                    onClick={handleReportNCC}
                                >
                                    Report to NCC
                                </Button>
                            )}
                        </Space>
                    </Col>
                </Row>

                {/* Alert Details */}
                <Card title="Alert Details">
                    <Descriptions column={2}>
                        <Descriptions.Item label="B-Number">
                            <Text strong copyable style={{ fontSize: 16 }}>{alert.bNumber}</Text>
                        </Descriptions.Item>
                        <Descriptions.Item label="Fraud Type">
                            <Tag color="red">{alert.fraudType?.replace('_', ' ')}</Tag>
                        </Descriptions.Item>
                        <Descriptions.Item label="Confidence Score">
                            {((alert.score || 0) * 100).toFixed(1)}%
                        </Descriptions.Item>
                        <Descriptions.Item label="Distinct Callers">
                            {alert.distinctCallers}
                        </Descriptions.Item>
                        <Descriptions.Item label="Detection Window">
                            {alert.windowStart && alert.windowEnd
                                ? `${dayjs(alert.windowStart).format('HH:mm:ss')} - ${dayjs(alert.windowEnd).format('HH:mm:ss')}`
                                : '-'}
                        </Descriptions.Item>
                        <Descriptions.Item label="Detected At">
                            {dayjs(alert.detectedAt).format('YYYY-MM-DD HH:mm:ss')}
                        </Descriptions.Item>
                    </Descriptions>
                </Card>

                {/* A-Numbers and IPs */}
                <Row gutter={16}>
                    <Col span={12}>
                        <Card title="Source A-Numbers" size="small">
                            <Space wrap>
                                {(alert.aNumbers || []).slice(0, 20).map((num: string, i: number) => (
                                    <Tag key={i}>{num}</Tag>
                                ))}
                                {(alert.aNumbers?.length || 0) > 20 && (
                                    <Tag>+{alert.aNumbers!.length - 20} more</Tag>
                                )}
                            </Space>
                        </Card>
                    </Col>
                    <Col span={12}>
                        <Card title="Source IPs" size="small">
                            <Space wrap>
                                {(alert.sourceIps || []).slice(0, 10).map((ip: string, i: number) => (
                                    <Tag key={i} color="geekblue">{ip}</Tag>
                                ))}
                            </Space>
                        </Card>
                    </Col>
                </Row>

                {/* Related Calls */}
                <Card title="Related Calls">
                    <Table
                        dataSource={record?.calls || []}
                        columns={callColumns}
                        rowKey="id"
                        size="small"
                        pagination={{ pageSize: 10 }}
                    />
                </Card>

                {/* Resolution Timeline */}
                {(alert.acknowledgedAt || alert.resolvedAt) && (
                    <Card title="Timeline">
                        <Timeline
                            items={[
                                {
                                    color: 'red',
                                    children: `Detected at ${dayjs(alert.detectedAt).format('YYYY-MM-DD HH:mm:ss')}`,
                                },
                                ...(alert.acknowledgedAt
                                    ? [{
                                        color: 'blue',
                                        children: `Acknowledged by ${alert.acknowledgedBy} at ${dayjs(alert.acknowledgedAt).format('YYYY-MM-DD HH:mm:ss')}`,
                                    }]
                                    : []),
                                ...(alert.resolvedAt
                                    ? [{
                                        color: 'green',
                                        children: `Resolved as "${alert.resolution}" by ${alert.resolvedBy} at ${dayjs(alert.resolvedAt).format('YYYY-MM-DD HH:mm:ss')}`,
                                    }]
                                    : []),
                            ]}
                        />
                        {alert.resolutionNotes && (
                            <>
                                <Divider />
                                <Text strong>Resolution Notes:</Text>
                                <p>{alert.resolutionNotes}</p>
                            </>
                        )}
                    </Card>
                )}

                {/* Resolve Modal */}
                <Modal
                    title="Resolve Alert"
                    open={resolveModalOpen}
                    onOk={handleResolve}
                    onCancel={() => setResolveModalOpen(false)}
                >
                    <Space direction="vertical" style={{ width: '100%' }}>
                        <div>
                            <Text strong>Resolution:</Text>
                            <Select
                                value={resolution}
                                onChange={setResolution}
                                style={{ width: '100%', marginTop: 8 }}
                                options={[
                                    { label: 'Confirmed Fraud', value: 'CONFIRMED_FRAUD' },
                                    { label: 'False Positive', value: 'FALSE_POSITIVE' },
                                    { label: 'Escalated', value: 'ESCALATED' },
                                    { label: 'Whitelisted', value: 'WHITELISTED' },
                                ]}
                            />
                        </div>
                        <div>
                            <Text strong>Notes:</Text>
                            <TextArea
                                rows={4}
                                value={notes}
                                onChange={(e) => setNotes(e.target.value)}
                                placeholder="Enter resolution notes..."
                                style={{ marginTop: 8 }}
                            />
                        </div>
                    </Space>
                </Modal>
            </Space>
        </Show>
    );
};

export default FraudAlertShow;
