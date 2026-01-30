import { gql } from '@apollo/client';

// Update setting
export const UPDATE_SETTING = gql`
  mutation UpdateSetting($id: uuid!, $value: String!, $updated_by: uuid!) {
    update_acm_settings_by_pk(
      pk_columns: { id: $id }
      _set: {
        value: $value
        updated_by: $updated_by
        updated_at: "now()"
      }
    ) {
      id
      key
      value
      updated_at
    }
  }
`;

// Update setting by key
export const UPDATE_SETTING_BY_KEY = gql`
  mutation UpdateSettingByKey($key: String!, $value: String!, $updated_by: uuid!) {
    update_acm_settings(
      where: { key: { _eq: $key } }
      _set: {
        value: $value
        updated_by: $updated_by
        updated_at: "now()"
      }
    ) {
      affected_rows
      returning {
        id
        key
        value
        updated_at
      }
    }
  }
`;

// Bulk update settings
export const BULK_UPDATE_SETTINGS = gql`
  mutation BulkUpdateSettings($updates: [acm_settings_updates!]!) {
    update_acm_settings_many(updates: $updates) {
      affected_rows
      returning {
        id
        key
        value
        updated_at
      }
    }
  }
`;

// Create setting
export const CREATE_SETTING = gql`
  mutation CreateSetting($object: acm_settings_insert_input!) {
    insert_acm_settings_one(object: $object) {
      id
      key
      value
      description
      category
      created_at
    }
  }
`;

// Delete setting
export const DELETE_SETTING = gql`
  mutation DeleteSetting($id: uuid!) {
    delete_acm_settings_by_pk(id: $id) {
      id
      key
    }
  }
`;

// Reset settings to default
export const RESET_SETTINGS_TO_DEFAULT = gql`
  mutation ResetSettingsToDefault($category: String!) {
    reset_settings_to_default(args: { category: $category }) {
      success
      message
      affected_count
    }
  }
`;
