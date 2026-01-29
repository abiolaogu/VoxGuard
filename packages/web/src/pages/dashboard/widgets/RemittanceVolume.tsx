import { Statistic, Space, Typography, Progress, Spin } from 'antd';
import { ArrowUpOutlined } from '@ant-design/icons';
import { useCustom } from '@refinedev/core';

const { Text } = Typography;

const REMITTANCE_STATS_QUERY = `
  query RemittanceStats {
    transactions_24h: remittance_transactions_aggregate(
      where: { initiated_at: { _gte: "now() - interval '24 hours'" } }
    ) {
      aggregate {
        count
        sum { total_paid }
      }
    }
    completed_24h: remittance_transactions_aggregate(
      where: { 
        status: { _eq: "COMPLETED" }
        completed_at: { _gte: "now() - interval '24 hours'" }
      }
    ) {
      aggregate {
        count
        sum { amount_received }
      }
    }
  }
`;

export const RemittanceVolume: React.FC = () => {
    const { data, isLoading } = useCustom({
        url: '',
        method: 'get',
        meta: {
            gqlQuery: REMITTANCE_STATS_QUERY,
        },
    });

    if (isLoading) {
        return (
            <div style={{ height: 150, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Spin />
            </div>
        );
    }

    const stats = data?.data as any;
    const totalTransactions = stats?.transactions_24h?.aggregate?.count ?? 0;
    const totalValue = stats?.transactions_24h?.aggregate?.sum?.total_paid ?? 0;
    const completedCount = stats?.completed_24h?.aggregate?.count ?? 0;
    const completedValue = stats?.completed_24h?.aggregate?.sum?.amount_received ?? 0;

    const completionRate = totalTransactions > 0
        ? Math.round((completedCount / totalTransactions) * 100)
        : 0;

    return (
        <Space direction="vertical" size="middle" style={{ width: '100%' }}>
            <Statistic
                title="Total Volume"
                value={totalValue}
                precision={2}
                prefix="$"
                suffix={
                    <Text type="secondary" style={{ fontSize: 12 }}>
                        USD
                    </Text>
                }
                valueStyle={{ color: '#1890ff', fontSize: 24 }}
            />

            <Statistic
                title="Transactions"
                value={totalTransactions}
                suffix={
                    <Text type="success" style={{ fontSize: 12 }}>
                        <ArrowUpOutlined /> {completedCount} completed
                    </Text>
                }
            />

            <div>
                <Text type="secondary" style={{ fontSize: 12 }}>Completion Rate</Text>
                <Progress
                    percent={completionRate}
                    strokeColor={{
                        '0%': '#108ee9',
                        '100%': '#87d068',
                    }}
                    format={(percent) => `${percent}%`}
                />
            </div>

            <Statistic
                title="Delivered to Nigeria"
                value={completedValue}
                precision={0}
                prefix="₦"
                valueStyle={{ fontSize: 16 }}
            />
        </Space>
    );
};

export default RemittanceVolume;
