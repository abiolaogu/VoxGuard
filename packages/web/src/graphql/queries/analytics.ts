import { gql } from '@apollo/client';

// Get dashboard statistics
export const GET_DASHBOARD_STATS = gql`
  query GetDashboardStats {
    total_alerts: acm_alerts_aggregate {
      aggregate {
        count
      }
    }
    new_alerts: acm_alerts_aggregate(where: { status: { _eq: "NEW" } }) {
      aggregate {
        count
      }
    }
    critical_alerts: acm_alerts_aggregate(where: { severity: { _eq: "CRITICAL" } }) {
      aggregate {
        count
      }
    }
    resolved_today: acm_alerts_aggregate(
      where: {
        status: { _eq: "RESOLVED" }
        updated_at: { _gte: "today" }
      }
    ) {
      aggregate {
        count
      }
    }
    alerts_by_severity: acm_alerts(distinct_on: severity) {
      severity
    }
  }
`;

// Get traffic metrics (via Hasura action to QuestDB)
export const GET_TRAFFIC_METRICS = gql`
  query GetTrafficMetrics($start_time: timestamptz!, $end_time: timestamptz!, $interval: String!) {
    traffic_metrics(
      args: {
        start_time: $start_time
        end_time: $end_time
        interval: $interval
      }
    ) {
      timestamp
      total_calls
      masked_calls
      detection_rate
      avg_threat_score
    }
  }
`;

// Get carrier statistics
export const GET_CARRIER_STATS = gql`
  query GetCarrierStats($start_date: timestamptz, $end_date: timestamptz) {
    carrier_stats: acm_alerts(
      where: {
        created_at: { _gte: $start_date, _lte: $end_date }
      }
    ) {
      carrier_id
      carrier_name
    }
    carrier_alert_counts: acm_alerts_aggregate(
      where: {
        created_at: { _gte: $start_date, _lte: $end_date }
      }
    ) {
      nodes {
        carrier_id
        carrier_name
        severity
      }
      aggregate {
        count
      }
    }
  }
`;

// Get top targeted numbers
export const GET_TOP_TARGETED_NUMBERS = gql`
  query GetTopTargetedNumbers($limit: Int = 10, $start_date: timestamptz) {
    top_targeted: acm_alerts(
      where: { created_at: { _gte: $start_date } }
      order_by: { b_number: asc }
      distinct_on: b_number
      limit: $limit
    ) {
      b_number
    }
  }
`;

// Get hourly alert distribution
export const GET_HOURLY_DISTRIBUTION = gql`
  query GetHourlyDistribution($date: date!) {
    hourly_distribution(args: { target_date: $date }) {
      hour
      alert_count
      critical_count
      high_count
      medium_count
      low_count
    }
  }
`;

// Get alerts trend over time
export const GET_ALERTS_TREND = gql`
  query GetAlertsTrend($start_date: timestamptz!, $end_date: timestamptz!) {
    alerts_trend(
      args: {
        start_date: $start_date
        end_date: $end_date
      }
    ) {
      date
      total
      critical
      high
      medium
      low
    }
  }
`;

// Get system health metrics
export const GET_SYSTEM_HEALTH = gql`
  query GetSystemHealth {
    system_health {
      component
      status
      latency_ms
      last_check
      details
    }
  }
`;
