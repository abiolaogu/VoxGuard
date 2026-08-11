
import {
    List,
    useTable,
    DateField,
} from '@refinedev/antd';
import { Table, Space, Tag, Typography, Button } from 'antd';
import { DownloadOutlined } from '@ant-design/icons';

const { Text } = Typography;

interface ComplianceReport {
    id: string;
    report_type: 'DAILY_FRAUD' | 'MONTHLY_COMPLIANCE' | 'INCIDENT_SUMMARY';
    status: 'generated' | 'submitted' | 'failed';
    period_start: string;
    period_end: string;
    generated_at: string;
    download_url: string;
    ncc_submission_id?: string;
}

export const ComplianceList: React.FC = () => {
    const { tableProps } = useTable<ComplianceReport>({
        resource: 'compliance_reports', // Assumes a view or table
        sorters: {
            initial: [{ field: 'generated_at', order: 'desc' }],
        },
    });

    const columns = [
        {
            title: 'Report Type',
            dataIndex: 'report_type',
            key: 'report_type',
            render: (value: string) => {
                let color = 'blue';
                if (value === 'DAILY_FRAUD') color = 'orange';
                if (value === 'MONTHLY_COMPLIANCE') color = 'purple';
                return <Tag color={color}>{value.replace('_', ' ')}</Tag>;
            },
        },
        {
            title: 'Period',
            key: 'period',
            render: (_: unknown, record: ComplianceReport) => (
                <Space direction="vertical" size={0}>
                    <Text style={{ fontSize: 12 }}>From: {record.period_start}</Text>
                    <Text style={{ fontSize: 12 }}>To: {record.period_end}</Text>
                </Space>
            ),
        },
        {
            title: 'Status',
            dataIndex: 'status',
            key: 'status',
            render: (value: string) => {
                const color = value === 'submitted' ? 'success' : value === 'failed' ? 'error' : 'processing';
                return <Tag color={color}>{value.toUpperCase()}</Tag>;
            },
        },
        {
            title: 'NCC ID',
            dataIndex: 'ncc_submission_id',
            key: 'ncc_submission_id',
            render: (value: string) => value ? <Text code>{value}</Text> : '-',
        },
        {
            title: 'Generated At',
            dataIndex: 'generated_at',
            key: 'generated_at',
            render: (value: string) => <DateField value={value} format="YYYY-MM-DD HH:mm" />,
        },
        {
            title: 'Actions',
            key: 'actions',
            render: (_: unknown, record: ComplianceReport) => (
                <Space size="small">
                    <Button
                        type="primary"
                        size="small"
                        icon={<DownloadOutlined />}
                        href={record.download_url}
                        target="_blank"
                    >
                        Download
                    </Button>
                </Space>
            ),
        },
    ];

    return (
        <List title="NCC Compliance Reports" resource="compliance_reports">
            <Table {...tableProps} columns={columns} rowKey="id" />
        </List>
    );
};
