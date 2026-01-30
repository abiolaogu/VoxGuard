import { gql } from '@apollo/client';

// Fragment for alert fields
export const ALERT_FIELDS = gql`
  fragment AlertFields on acm_alerts {
    id
    b_number
    a_number
    severity
    status
    threat_score
    detection_type
    carrier_id
    carrier_name
    route_type
    cli_status
    created_at
    updated_at
    notes
    assigned_to
  }
`;

// Get all alerts with pagination and filtering
export const GET_ALERTS = gql`
  ${ALERT_FIELDS}
  query GetAlerts(
    $limit: Int
    $offset: Int
    $order_by: [acm_alerts_order_by!]
    $where: acm_alerts_bool_exp
  ) {
    acm_alerts(
      limit: $limit
      offset: $offset
      order_by: $order_by
      where: $where
    ) {
      ...AlertFields
    }
    acm_alerts_aggregate(where: $where) {
      aggregate {
        count
      }
    }
  }
`;

// Get single alert by ID
export const GET_ALERT = gql`
  ${ALERT_FIELDS}
  query GetAlert($id: uuid!) {
    acm_alerts_by_pk(id: $id) {
      ...AlertFields
      audit_logs: acm_alert_audit_logs(order_by: { created_at: desc }) {
        id
        action
        user_id
        user_name
        old_value
        new_value
        created_at
      }
    }
  }
`;

// Get alerts count by severity
export const GET_ALERTS_BY_SEVERITY = gql`
  query GetAlertsBySeverity($where: acm_alerts_bool_exp) {
    critical: acm_alerts_aggregate(where: { _and: [{ severity: { _eq: "CRITICAL" } }, $where] }) {
      aggregate { count }
    }
    high: acm_alerts_aggregate(where: { _and: [{ severity: { _eq: "HIGH" } }, $where] }) {
      aggregate { count }
    }
    medium: acm_alerts_aggregate(where: { _and: [{ severity: { _eq: "MEDIUM" } }, $where] }) {
      aggregate { count }
    }
    low: acm_alerts_aggregate(where: { _and: [{ severity: { _eq: "LOW" } }, $where] }) {
      aggregate { count }
    }
  }
`;

// Get alerts count by status
export const GET_ALERTS_BY_STATUS = gql`
  query GetAlertsByStatus($where: acm_alerts_bool_exp) {
    new_alerts: acm_alerts_aggregate(where: { _and: [{ status: { _eq: "NEW" } }, $where] }) {
      aggregate { count }
    }
    investigating: acm_alerts_aggregate(where: { _and: [{ status: { _eq: "INVESTIGATING" } }, $where] }) {
      aggregate { count }
    }
    confirmed: acm_alerts_aggregate(where: { _and: [{ status: { _eq: "CONFIRMED" } }, $where] }) {
      aggregate { count }
    }
    resolved: acm_alerts_aggregate(where: { _and: [{ status: { _eq: "RESOLVED" } }, $where] }) {
      aggregate { count }
    }
    false_positive: acm_alerts_aggregate(where: { _and: [{ status: { _eq: "FALSE_POSITIVE" } }, $where] }) {
      aggregate { count }
    }
  }
`;

// Get recent alerts for dashboard
export const GET_RECENT_ALERTS = gql`
  ${ALERT_FIELDS}
  query GetRecentAlerts($limit: Int = 10) {
    acm_alerts(
      limit: $limit
      order_by: { created_at: desc }
      where: { status: { _neq: "RESOLVED" } }
    ) {
      ...AlertFields
    }
  }
`;

// Search alerts
export const SEARCH_ALERTS = gql`
  ${ALERT_FIELDS}
  query SearchAlerts($search: String!, $limit: Int = 50) {
    acm_alerts(
      limit: $limit
      order_by: { created_at: desc }
      where: {
        _or: [
          { b_number: { _ilike: $search } }
          { a_number: { _ilike: $search } }
          { carrier_name: { _ilike: $search } }
        ]
      }
    ) {
      ...AlertFields
    }
  }
`;

// Get alerts timeline (for charts)
export const GET_ALERTS_TIMELINE = gql`
  query GetAlertsTimeline($start_date: timestamptz!, $end_date: timestamptz!) {
    acm_alerts(
      where: {
        created_at: { _gte: $start_date, _lte: $end_date }
      }
      order_by: { created_at: asc }
    ) {
      id
      severity
      created_at
    }
  }
`;
