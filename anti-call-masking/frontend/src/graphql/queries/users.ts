import { gql } from '@apollo/client';

// Fragment for user fields
export const USER_FIELDS = gql`
  fragment UserFields on acm_users {
    id
    email
    name
    role
    avatar
    is_active
    last_login
    created_at
    updated_at
  }
`;

// Get all users with pagination
export const GET_USERS = gql`
  ${USER_FIELDS}
  query GetUsers(
    $limit: Int
    $offset: Int
    $order_by: [acm_users_order_by!]
    $where: acm_users_bool_exp
  ) {
    acm_users(
      limit: $limit
      offset: $offset
      order_by: $order_by
      where: $where
    ) {
      ...UserFields
    }
    acm_users_aggregate(where: $where) {
      aggregate {
        count
      }
    }
  }
`;

// Get single user by ID
export const GET_USER = gql`
  ${USER_FIELDS}
  query GetUser($id: uuid!) {
    acm_users_by_pk(id: $id) {
      ...UserFields
      assigned_alerts: acm_alerts_aggregate(where: { assigned_to: { _eq: $id } }) {
        aggregate {
          count
        }
      }
    }
  }
`;

// Get users for assignment dropdown
export const GET_USERS_FOR_ASSIGNMENT = gql`
  query GetUsersForAssignment {
    acm_users(
      where: {
        is_active: { _eq: true }
        role: { _in: ["admin", "analyst"] }
      }
      order_by: { name: asc }
    ) {
      id
      name
      email
      role
    }
  }
`;

// Get user activity
export const GET_USER_ACTIVITY = gql`
  query GetUserActivity($user_id: uuid!, $limit: Int = 20) {
    acm_alert_audit_logs(
      where: { user_id: { _eq: $user_id } }
      order_by: { created_at: desc }
      limit: $limit
    ) {
      id
      action
      alert_id
      old_value
      new_value
      created_at
      alert {
        b_number
        severity
      }
    }
  }
`;
