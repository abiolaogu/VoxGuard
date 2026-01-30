import { gql } from '@apollo/client';
import { ALERT_FIELDS } from '../queries/alerts';

// Update alert status
export const UPDATE_ALERT_STATUS = gql`
  ${ALERT_FIELDS}
  mutation UpdateAlertStatus($id: uuid!, $status: String!, $notes: String) {
    update_acm_alerts_by_pk(
      pk_columns: { id: $id }
      _set: {
        status: $status
        notes: $notes
        updated_at: "now()"
      }
    ) {
      ...AlertFields
    }
  }
`;

// Update alert (general)
export const UPDATE_ALERT = gql`
  ${ALERT_FIELDS}
  mutation UpdateAlert($id: uuid!, $changes: acm_alerts_set_input!) {
    update_acm_alerts_by_pk(
      pk_columns: { id: $id }
      _set: $changes
    ) {
      ...AlertFields
    }
  }
`;

// Assign alert to user
export const ASSIGN_ALERT = gql`
  ${ALERT_FIELDS}
  mutation AssignAlert($id: uuid!, $assigned_to: uuid!) {
    update_acm_alerts_by_pk(
      pk_columns: { id: $id }
      _set: {
        assigned_to: $assigned_to
        status: "INVESTIGATING"
        updated_at: "now()"
      }
    ) {
      ...AlertFields
    }
  }
`;

// Bulk update alert status
export const BULK_UPDATE_ALERT_STATUS = gql`
  mutation BulkUpdateAlertStatus($ids: [uuid!]!, $status: String!) {
    update_acm_alerts(
      where: { id: { _in: $ids } }
      _set: {
        status: $status
        updated_at: "now()"
      }
    ) {
      affected_rows
      returning {
        id
        status
        updated_at
      }
    }
  }
`;

// Bulk assign alerts
export const BULK_ASSIGN_ALERTS = gql`
  mutation BulkAssignAlerts($ids: [uuid!]!, $assigned_to: uuid!) {
    update_acm_alerts(
      where: { id: { _in: $ids } }
      _set: {
        assigned_to: $assigned_to
        status: "INVESTIGATING"
        updated_at: "now()"
      }
    ) {
      affected_rows
      returning {
        id
        assigned_to
        status
        updated_at
      }
    }
  }
`;

// Add alert note
export const ADD_ALERT_NOTE = gql`
  mutation AddAlertNote($alert_id: uuid!, $note: String!, $user_id: uuid!, $user_name: String!) {
    insert_acm_alert_audit_logs_one(
      object: {
        alert_id: $alert_id
        action: "NOTE_ADDED"
        user_id: $user_id
        user_name: $user_name
        new_value: $note
      }
    ) {
      id
      action
      new_value
      created_at
    }
  }
`;

// Log alert action
export const LOG_ALERT_ACTION = gql`
  mutation LogAlertAction(
    $alert_id: uuid!
    $action: String!
    $user_id: uuid!
    $user_name: String!
    $old_value: String
    $new_value: String
  ) {
    insert_acm_alert_audit_logs_one(
      object: {
        alert_id: $alert_id
        action: $action
        user_id: $user_id
        user_name: $user_name
        old_value: $old_value
        new_value: $new_value
      }
    ) {
      id
      action
      created_at
    }
  }
`;
