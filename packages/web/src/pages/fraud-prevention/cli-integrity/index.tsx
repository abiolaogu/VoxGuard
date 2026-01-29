import React from 'react';
import { useList, useShow } from '@refinedev/core';
import { List, useTable, Show, TextField, TagField, DateField } from '@refinedev/antd';
import { Table, Tag, Card, Space, Typography, Descriptions, Timeline, Badge, Row, Col, Statistic } from 'antd';
import {
    SafetyOutlined,
    WarningOutlined,
    CheckCircleOutlined,
    CloseCircleOutlined,
} from '@ant-design/icons';

const { Text, Title } = Typography;

// Spoofing type configurations
const SPOOFING_TYPE_CONFIG = {
    CLI_MANIPULATION: { color: 'red', label: 'CLI Manipulation' },
    NUMBER_SUBSTITUTION: { color: 'volcano', label: 'Number Substitution' },
    NEIGHBOR_SPOOFING: { color: 'orange', label: 'Neighbor Spoofing' },
    TOLL_FREE_SPOOFING: { color: 'gold', label: 'Toll-Free Spoofing' },
    GOVERNMENT_IMPERSONATION: { color: 'magenta', label: 'Govt Impersonation' },
    BANK_IMPERSONATION: { color: 'purple', label: 'Bank Impersonation' },
    NONE: { color: 'green', label: 'No Spoofing' },
};

// CLI Verifications List
export const CLIVerificationList: React.FC = () => {
    const { tableProps } = useTable({
        resource: 'cli_verifications',
        sorters: { initial: [{ field: 'created_at', order: 'desc' }] },
    });

    return (
        <List
            title={<><SafetyOutlined /> CLI Verifications</>}
            headerProps={{
                extra: (
                    <Space>
                        <Badge status="processing" text="Real-time" />
                    </Space>
                ),
            }}
        >
            <Table
                {...tableProps}
                rowKey="id"
                columns={[
                    {
                        title: 'Presented CLI',
                        dataIndex: 'presented_cli',
                        render: (cli: string) => <Text code>{cli}</Text>,
                    },
                    {
                        title: 'Actual CLI',
                        dataIndex: 'actual_cli',
                        render: (cli: string | null) =>
                            cli ? <Text code>{cli}</Text> : <Text type="secondary">—</Text>,
                    },
                    {
                        title: 'Spoofing Detected',
                        dataIndex: 'spoofing_detected',
                        render: (detected: boolean) =>
                            detected ? (
                                <Tag icon={<WarningOutlined />} color="error">Yes</Tag>
                            ) : (
                                <Tag icon={<CheckCircleOutlined />} color="success">No</Tag>
                            ),
                        filters: [
                            { text: 'Spoofing Detected', value: true },
                            { text: 'Legitimate', value: false },
                        ],
                    },
                    {
                        title: 'Spoofing Type',
                        dataIndex: 'spoofing_type',
                        render: (type: string) => {
                            const config = SPOOFING_TYPE_CONFIG[type as keyof typeof SPOOFING_TYPE_CONFIG];
                            return config ? (
                                <Tag color={config.color}>{config.label}</Tag>
                            ) : (
                                <Text type="secondary">—</Text>
                            );
                        },
                    },
                    {
                        title: 'Confidence',
                        dataIndex: 'confidence_score',
                        render: (score: number | null) =>
                            score !== null ? `${Math.round(score * 100)}%` : '—',
                        sorter: true,
                    },
                    {
                        title: 'Method',
                        dataIndex: 'verification_method',
                        render: (method: string | null) =>
                            method ? <Tag>{method}</Tag> : '—',
                    },
                    {
                        title: 'Time',
                        dataIndex: 'created_at',
                        render: (date: string) => new Date(date).toLocaleString(),
                        sorter: true,
                    },
                ]}
            />
        </List>
    );
};

// CLI Verification Detail
export const CLIVerificationShow: React.FC = () => {
    const { queryResult } = useShow({ resource: 'cli_verifications' });
    const { data, isLoading } = queryResult;
    const record = data?.data;

    return (
        <Show isLoading={isLoading} title="CLI Verification Details">
            <Row gutter={[16, 16]}>
                <Col span={24}>
                    <Card>
                        <Descriptions bordered column={2}>
                            <Descriptions.Item label="Presented CLI">
                                <Text code style={{ fontSize: 16 }}>{record?.presented_cli}</Text>
                            </Descriptions.Item>
                            <Descriptions.Item label="Actual CLI">
                                {record?.actual_cli ? (
                                    <Text code style={{ fontSize: 16 }}>{record.actual_cli}</Text>
                                ) : (
                                    <Text type="secondary">Not available</Text>
                                )}
                            </Descriptions.Item>
                            <Descriptions.Item label="Spoofing Detected">
                                {record?.spoofing_detected ? (
                                    <Tag icon={<CloseCircleOutlined />} color="error">Yes - Spoofing Detected</Tag>
                                ) : (
                                    <Tag icon={<CheckCircleOutlined />} color="success">No - Legitimate</Tag>
                                )}
                            </Descriptions.Item>
                            <Descriptions.Item label="Spoofing Type">
                                {record?.spoofing_type && (
                                    <Tag color={SPOOFING_TYPE_CONFIG[record.spoofing_type]?.color}>
                                        {SPOOFING_TYPE_CONFIG[record.spoofing_type]?.label ?? record.spoofing_type}
                                    </Tag>
                                )}
                            </Descriptions.Item>
                            <Descriptions.Item label="Confidence Score">
                                <Statistic
                                    value={record?.confidence_score ? record.confidence_score * 100 : 0}
                                    suffix="%"
                                    valueStyle={{
                                        color: record?.confidence_score > 0.8 ? '#cf1322' : '#faad14',
                                    }}
                                />
                            </Descriptions.Item>
                            <Descriptions.Item label="Verification Method">
                                <Tag>{record?.verification_method}</Tag>
                            </Descriptions.Item>
                            <Descriptions.Item label="Call Direction">
                                <Tag>{record?.call_direction}</Tag>
                            </Descriptions.Item>
                            <Descriptions.Item label="Timestamp">
                                {record?.created_at && new Date(record.created_at).toLocaleString()}
                            </Descriptions.Item>
                        </Descriptions>
                    </Card>
                </Col>

                {/* SS7 Analysis */}
                {record?.ss7_analysis && (
                    <Col span={12}>
                        <Card title="SS7 Analysis">
                            <Descriptions column={1} size="small">
                                <Descriptions.Item label="Originating Point Code">
                                    <Text code>{record.ss7_analysis.originatingPointCode}</Text>
                                </Descriptions.Item>
                                <Descriptions.Item label="Calling Party Address">
                                    <Text code>{record.ss7_analysis.callingPartyAddress}</Text>
                                </Descriptions.Item>
                                {record.ss7_analysis.locationNumber && (
                                    <Descriptions.Item label="Location Number">
                                        <Text code>{record.ss7_analysis.locationNumber}</Text>
                                    </Descriptions.Item>
                                )}
                                {record.ss7_analysis.inconsistencies?.length > 0 && (
                                    <Descriptions.Item label="Inconsistencies">
                                        <Space direction="vertical">
                                            {record.ss7_analysis.inconsistencies.map((inc: string, i: number) => (
                                                <Tag color="error" key={i}>{inc}</Tag>
                                            ))}
                                        </Space>
                                    </Descriptions.Item>
                                )}
                            </Descriptions>
                        </Card>
                    </Col>
                )}

                {/* STIR/SHAKEN Result */}
                {record?.stir_shaken_result && (
                    <Col span={12}>
                        <Card title="STIR/SHAKEN Verification">
                            <Descriptions column={1} size="small">
                                <Descriptions.Item label="Attestation Level">
                                    <Tag color={
                                        record.stir_shaken_result.attestationLevel === 'A' ? 'green' :
                                            record.stir_shaken_result.attestationLevel === 'B' ? 'gold' : 'red'
                                    }>
                                        Level {record.stir_shaken_result.attestationLevel}
                                    </Tag>
                                </Descriptions.Item>
                                <Descriptions.Item label="Verification Status">
                                    {record.stir_shaken_result.verificationStatus === 'VERIFIED' ? (
                                        <Tag icon={<CheckCircleOutlined />} color="success">Verified</Tag>
                                    ) : (
                                        <Tag icon={<CloseCircleOutlined />} color="error">
                                            {record.stir_shaken_result.verificationStatus}
                                        </Tag>
                                    )}
                                </Descriptions.Item>
                                <Descriptions.Item label="Certificate Chain">
                                    {record.stir_shaken_result.certificateChainValid ? (
                                        <Tag color="success">Valid</Tag>
                                    ) : (
                                        <Tag color="error">Invalid</Tag>
                                    )}
                                </Descriptions.Item>
                            </Descriptions>
                        </Card>
                    </Col>
                )}
            </Row>
        </Show>
    );
};
