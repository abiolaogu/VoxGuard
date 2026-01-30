import { gql } from '@apollo/client';

// Get all settings
export const GET_SETTINGS = gql`
  query GetSettings {
    acm_settings(order_by: { key: asc }) {
      id
      key
      value
      description
      category
      is_sensitive
      updated_at
      updated_by
    }
  }
`;

// Get settings by category
export const GET_SETTINGS_BY_CATEGORY = gql`
  query GetSettingsByCategory($category: String!) {
    acm_settings(
      where: { category: { _eq: $category } }
      order_by: { key: asc }
    ) {
      id
      key
      value
      description
      is_sensitive
      updated_at
    }
  }
`;

// Get single setting by key
export const GET_SETTING = gql`
  query GetSetting($key: String!) {
    acm_settings(where: { key: { _eq: $key } }) {
      id
      key
      value
      description
      category
      is_sensitive
      updated_at
      updated_by
    }
  }
`;

// Get detection thresholds
export const GET_DETECTION_THRESHOLDS = gql`
  query GetDetectionThresholds {
    acm_settings(
      where: { category: { _eq: "detection" } }
      order_by: { key: asc }
    ) {
      id
      key
      value
      description
    }
  }
`;

// Get notification settings
export const GET_NOTIFICATION_SETTINGS = gql`
  query GetNotificationSettings {
    acm_settings(
      where: { category: { _eq: "notifications" } }
      order_by: { key: asc }
    ) {
      id
      key
      value
      description
    }
  }
`;
