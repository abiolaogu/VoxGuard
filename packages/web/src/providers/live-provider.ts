import type { LiveProvider } from '@refinedev/core';
import { apolloClient } from '../config/graphql';
import { gql } from '@apollo/client';

// GraphQL subscription documents for different resources
const SUBSCRIPTIONS: Record<string, ReturnType<typeof gql>> = {
  acm_alerts: gql`
    subscription AlertsSubscription($where: acm_alerts_bool_exp) {
      acm_alerts(where: $where, order_by: { created_at: desc }, limit: 100) {
        id
        b_number
        a_number
        severity
        status
        threat_score
        created_at
        updated_at
        carrier_name
        detection_type
      }
    }
  `,
  acm_alerts_aggregate: gql`
    subscription AlertsAggregateSubscription($where: acm_alerts_bool_exp) {
      acm_alerts_aggregate(where: $where) {
        aggregate {
          count
        }
        nodes {
          severity
          status
        }
      }
    }
  `,
  acm_users: gql`
    subscription UsersSubscription {
      acm_users(order_by: { created_at: desc }) {
        id
        email
        name
        role
        last_login
        created_at
      }
    }
  `,
  acm_settings: gql`
    subscription SettingsSubscription {
      acm_settings {
        id
        key
        value
        updated_at
      }
    }
  `,
};

// Active subscription references
const activeSubscriptions = new Map<string, { unsubscribe: () => void }>();

// Refine Live Provider for real-time updates via GraphQL Subscriptions
export const liveProvider: LiveProvider = {
  subscribe: ({ channel, params, callback }) => {
    const subscriptionDoc = SUBSCRIPTIONS[channel];

    if (!subscriptionDoc) {
      console.warn(`[LiveProvider] No subscription defined for channel: ${channel}`);
      return;
    }

    // Build variables from params
    const variables: Record<string, unknown> = {};

    if (params?.filters) {
      const where: Record<string, unknown> = {};
      params.filters.forEach((filter) => {
        if (filter.operator === 'eq') {
          where[filter.field] = { _eq: filter.value };
        } else if (filter.operator === 'in') {
          where[filter.field] = { _in: filter.value };
        } else if (filter.operator === 'gte') {
          where[filter.field] = { _gte: filter.value };
        } else if (filter.operator === 'lte') {
          where[filter.field] = { _lte: filter.value };
        }
      });
      variables.where = where;
    }

    // Create subscription
    const subscription = apolloClient
      .subscribe({
        query: subscriptionDoc,
        variables,
      })
      .subscribe({
        next: (result) => {
          if (result.data) {
            // Notify Refine of the update
            callback({
              channel,
              type: 'updated',
              date: new Date(),
              payload: {
                data: result.data[channel],
              },
            });
          }
        },
        error: (error) => {
          console.error(`[LiveProvider] Subscription error for ${channel}:`, error);
        },
      });

    // Store subscription reference
    const subscriptionKey = `${channel}-${JSON.stringify(params)}`;
    activeSubscriptions.set(subscriptionKey, subscription);

    return subscription;
  },

  unsubscribe: (subscription) => {
    if (subscription && typeof subscription.unsubscribe === 'function') {
      subscription.unsubscribe();
    }
  },

  publish: async ({ channel, type, payload }) => {
    // For optimistic updates - Hasura handles actual persistence
    console.log(`[LiveProvider] Publishing to ${channel}:`, { type, payload });

    // Refetch queries for the channel to ensure consistency
    await apolloClient.refetchQueries({
      include: [channel],
    });
  },
};

// Helper to manually trigger subscription for real-time alerts
export const subscribeToAlerts = (
  onData: (alerts: unknown[]) => void,
  filters?: { severity?: string[]; status?: string[] }
) => {
  const where: Record<string, unknown> = {};

  if (filters?.severity?.length) {
    where.severity = { _in: filters.severity };
  }
  if (filters?.status?.length) {
    where.status = { _in: filters.status };
  }

  return apolloClient
    .subscribe({
      query: SUBSCRIPTIONS.acm_alerts,
      variables: Object.keys(where).length ? { where } : undefined,
    })
    .subscribe({
      next: (result) => {
        if (result.data?.acm_alerts) {
          onData(result.data.acm_alerts);
        }
      },
      error: (error) => {
        console.error('[subscribeToAlerts] Error:', error);
      },
    });
};

// Helper for alert count subscription (for notifications badge)
export const subscribeToAlertCount = (
  onCount: (count: number, bySeverity: Record<string, number>) => void,
  statusFilter?: string[]
) => {
  const where: Record<string, unknown> = {};

  if (statusFilter?.length) {
    where.status = { _in: statusFilter };
  }

  return apolloClient
    .subscribe({
      query: SUBSCRIPTIONS.acm_alerts_aggregate,
      variables: Object.keys(where).length ? { where } : undefined,
    })
    .subscribe({
      next: (result) => {
        if (result.data?.acm_alerts_aggregate) {
          const count = result.data.acm_alerts_aggregate.aggregate.count;
          const bySeverity: Record<string, number> = {};

          result.data.acm_alerts_aggregate.nodes.forEach((node: { severity: string }) => {
            bySeverity[node.severity] = (bySeverity[node.severity] || 0) + 1;
          });

          onCount(count, bySeverity);
        }
      },
      error: (error) => {
        console.error('[subscribeToAlertCount] Error:', error);
      },
    });
};

export default liveProvider;
