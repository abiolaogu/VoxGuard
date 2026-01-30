import { gql } from '@apollo/client';
import { USER_FIELDS } from '../queries/users';

// Create user
export const CREATE_USER = gql`
  ${USER_FIELDS}
  mutation CreateUser($object: acm_users_insert_input!) {
    insert_acm_users_one(object: $object) {
      ...UserFields
    }
  }
`;

// Update user
export const UPDATE_USER = gql`
  ${USER_FIELDS}
  mutation UpdateUser($id: uuid!, $changes: acm_users_set_input!) {
    update_acm_users_by_pk(
      pk_columns: { id: $id }
      _set: $changes
    ) {
      ...UserFields
    }
  }
`;

// Update user role
export const UPDATE_USER_ROLE = gql`
  ${USER_FIELDS}
  mutation UpdateUserRole($id: uuid!, $role: String!) {
    update_acm_users_by_pk(
      pk_columns: { id: $id }
      _set: {
        role: $role
        updated_at: "now()"
      }
    ) {
      ...UserFields
    }
  }
`;

// Activate/Deactivate user
export const UPDATE_USER_STATUS = gql`
  ${USER_FIELDS}
  mutation UpdateUserStatus($id: uuid!, $is_active: Boolean!) {
    update_acm_users_by_pk(
      pk_columns: { id: $id }
      _set: {
        is_active: $is_active
        updated_at: "now()"
      }
    ) {
      ...UserFields
    }
  }
`;

// Delete user (soft delete by deactivating)
export const DELETE_USER = gql`
  mutation DeleteUser($id: uuid!) {
    update_acm_users_by_pk(
      pk_columns: { id: $id }
      _set: {
        is_active: false
        updated_at: "now()"
      }
    ) {
      id
      is_active
    }
  }
`;

// Update last login
export const UPDATE_LAST_LOGIN = gql`
  mutation UpdateLastLogin($id: uuid!) {
    update_acm_users_by_pk(
      pk_columns: { id: $id }
      _set: { last_login: "now()" }
    ) {
      id
      last_login
    }
  }
`;

// Update user password (via Hasura action)
export const UPDATE_USER_PASSWORD = gql`
  mutation UpdateUserPassword($id: uuid!, $current_password: String!, $new_password: String!) {
    update_user_password(
      args: {
        user_id: $id
        current_password: $current_password
        new_password: $new_password
      }
    ) {
      success
      message
    }
  }
`;
