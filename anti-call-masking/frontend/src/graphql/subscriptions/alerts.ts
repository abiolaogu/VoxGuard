import { gql } from '@apollo/client';
import { ALERT_FIELDS } from '../queries/alerts';

// Subscribe to all alerts (with optional filters)
export const ALERTS_SUBSCRIPTION = gql`
  ${ALERT_FIELDS}
  subscription AlertsSubscription($where: acm_alerts_bool_exp, $limit: Int = 100) {
    acm_alerts(
      where: $where
      order_by: { created_at: desc }
      limit: $limit
    ) {
      ...AlertFields
    }
  }
`;

// Subscribe to new alerts only
export const NEW_ALERTS_SUBSCRIPTION = gql`
  ${ALERT_FIELDS}
  subscription NewAlertsSubscription($since: timestamptz!) {
    acm_alerts(
      where: { created_at: { _gt: $since } }
      order_by: { created_at: desc }
    ) {
      ...AlertFields
    }
  }
`;

// Subscribe to critical alerts
export const CRITICAL_ALERTS_SUBSCRIPTION = gql`
  ${ALERT_FIELDS}
  subscription CriticalAlertsSubscription {
    acm_alerts(
      where: {
        severity: { _eq: "CRITICAL" }
        status: { _neq: "RESOLVED" }
      }
      order_by: { created_at: desc }
      limit: 20
    ) {
      ...AlertFields
    }
  }
`;

// Subscribe to alerts count by severity
export const ALERTS_COUNT_SUBSCRIPTION = gql`
  subscription AlertsCountSubscription($where: acm_alerts_bool_exp) {
    acm_alerts_aggregate(where: $where) {
      aggregate {
        count
      }
    }
  }
`;

// Subscribe to unresolved alerts count
export const UNRESOLVED_ALERTS_COUNT_SUBSCRIPTION = gql`
  subscription UnresolvedAlertsCountSubscription {
    new_count: acm_alerts_aggregate(where: { status: { _eq: "NEW" } }) {
      aggregate { count }
    }
    investigating_count: acm_alerts_aggregate(where: { status: { _eq: "INVESTIGATING" } }) {
      aggregate { count }
    }
    confirmed_count: acm_alerts_aggregate(where: { status: { _eq: "CONFIRMED" } }) {
      aggregate { count }
    }
    critical_count: acm_alerts_aggregate(where: { severity: { _eq: "CRITICAL" }, status: { _neq: "RESOLVED" } }) {
      aggregate { count }
    }
  }
`;

// Subscribe to single alert updates
export const ALERT_UPDATES_SUBSCRIPTION = gql`
  ${ALERT_FIELDS}
  subscription AlertUpdatesSubscription($id: uuid!) {
    acm_alerts_by_pk(id: $id) {
      ...AlertFields
      audit_logs: acm_alert_audit_logs(order_by: { created_at: desc }) {
        id
        action
        user_name
        old_value
        new_value
        created_at
      }
    }
  }
`;

// Subscribe to alerts by carrier
export const ALERTS_BY_CARRIER_SUBSCRIPTION = gql`
  subscription AlertsByCarrierSubscription($carrier_id: uuid!) {
    acm_alerts(
      where: { carrier_id: { _eq: $carrier_id } }
      order_by: { created_at: desc }
      limit: 50
    ) {
      id
      b_number
      a_number
      severity
      status
      threat_score
      created_at
    }
  }
`;
