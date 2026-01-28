//! Ports - Repository and service interfaces (Hexagonal Architecture)
//!
//! These traits define the contracts between the domain and infrastructure layers.
//! Adapters implement these traits to provide database, cache, and external service access.

use async_trait::async_trait;
use chrono::{DateTime, Utc};

use crate::domain::{
    aggregates::{Call, FraudAlert, Gateway, ThreatLevel},
    errors::DomainResult,
    events::DomainEvent,
    value_objects::{CallId, MSISDN, IPAddress},
};

/// Repository for Call aggregate persistence
#[async_trait]
pub trait CallRepository: Send + Sync {
    /// Saves a new call record
    async fn save(&self, call: &Call) -> DomainResult<()>;

    /// Finds a call by ID
    async fn find_by_id(&self, id: &CallId) -> DomainResult<Option<Call>>;

    /// Gets calls to a B-number within a time window
    async fn find_calls_in_window(
        &self,
        b_number: &MSISDN,
        window_start: DateTime<Utc>,
        window_end: DateTime<Utc>,
    ) -> DomainResult<Vec<Call>>;

    /// Counts distinct A-numbers calling a B-number in the window
    async fn count_distinct_callers(
        &self,
        b_number: &MSISDN,
        window_start: DateTime<Utc>,
        window_end: DateTime<Utc>,
    ) -> DomainResult<usize>;

    /// Flags multiple calls as part of a fraud alert
    async fn flag_as_fraud(&self, call_ids: &[CallId], alert_id: &str) -> DomainResult<usize>;

    /// Removes old unflagged calls (cleanup)
    async fn cleanup_old_calls(&self, before: DateTime<Utc>) -> DomainResult<usize>;
}

/// Repository for FraudAlert aggregate persistence
#[async_trait]
pub trait AlertRepository: Send + Sync {
    /// Saves a new or updated alert
    async fn save(&self, alert: &FraudAlert) -> DomainResult<()>;

    /// Finds an alert by ID
    async fn find_by_id(&self, id: uuid::Uuid) -> DomainResult<Option<FraudAlert>>;

    /// Gets recent alerts (last N minutes)
    async fn find_recent(&self, minutes: i64) -> DomainResult<Vec<FraudAlert>>;

    /// Gets alerts by status
    async fn find_by_status(&self, status: crate::domain::aggregates::fraud_alert::AlertStatus) -> DomainResult<Vec<FraudAlert>>;

    /// Gets alerts for a specific B-number
    async fn find_by_b_number(&self, b_number: &MSISDN) -> DomainResult<Vec<FraudAlert>>;

    /// Gets unacknowledged alert count
    async fn count_pending(&self) -> DomainResult<usize>;
}

/// Repository for Gateway aggregate persistence
#[async_trait]
pub trait GatewayRepository: Send + Sync {
    /// Saves a new or updated gateway
    async fn save(&self, gateway: &Gateway) -> DomainResult<()>;

    /// Finds a gateway by ID
    async fn find_by_id(&self, id: uuid::Uuid) -> DomainResult<Option<Gateway>>;

    /// Finds a gateway by IP address
    async fn find_by_ip(&self, ip: &IPAddress) -> DomainResult<Option<Gateway>>;

    /// Gets all active gateways
    async fn find_active(&self) -> DomainResult<Vec<Gateway>>;

    /// Gets all blacklisted gateways
    async fn find_blacklisted(&self) -> DomainResult<Vec<Gateway>>;

    /// Deletes a gateway
    async fn delete(&self, id: uuid::Uuid) -> DomainResult<()>;
}

/// Cache port for fast lookups
#[async_trait]
pub trait DetectionCache: Send + Sync {
    /// Adds an A-number to the B-number's sliding window set
    async fn add_caller_to_window(
        &self,
        b_number: &MSISDN,
        a_number: &MSISDN,
        window_seconds: u32,
    ) -> DomainResult<()>;

    /// Gets the count of distinct callers in the window
    async fn get_distinct_caller_count(&self, b_number: &MSISDN) -> DomainResult<usize>;

    /// Gets all distinct callers in the window
    async fn get_distinct_callers(&self, b_number: &MSISDN) -> DomainResult<Vec<String>>;

    /// Checks if a B-number is in cooldown
    async fn is_in_cooldown(&self, b_number: &MSISDN) -> DomainResult<bool>;

    /// Sets cooldown for a B-number
    async fn set_cooldown(&self, b_number: &MSISDN, seconds: u32) -> DomainResult<()>;

    /// Checks if a gateway IP is blacklisted (fast lookup)
    async fn is_ip_blacklisted(&self, ip: &IPAddress) -> DomainResult<bool>;

    /// Adds IP to blacklist cache
    async fn add_to_blacklist(&self, ip: &IPAddress, ttl_seconds: Option<u32>) -> DomainResult<()>;
}

/// Time-series analytics port (QuestDB)
#[async_trait]
pub trait TimeSeriesStore: Send + Sync {
    /// Ingests a call event using ILP (high-throughput)
    async fn ingest_call(&self, call: &Call) -> DomainResult<()>;

    /// Ingests an alert event
    async fn ingest_alert(&self, alert: &FraudAlert) -> DomainResult<()>;

    /// Gets real-time metrics for a gateway
    async fn get_gateway_metrics(
        &self,
        gateway_ip: &IPAddress,
        window_seconds: u32,
    ) -> DomainResult<GatewayMetrics>;

    /// Gets threat level for a B-number
    async fn get_threat_level(
        &self,
        b_number: &MSISDN,
        window_seconds: u32,
        threshold: usize,
    ) -> DomainResult<ThreatLevel>;

    /// Gets elevated threats (for dashboard)
    async fn get_elevated_threats(&self, threshold: usize) -> DomainResult<Vec<ThreatLevel>>;
}

/// Real-time gateway metrics
#[derive(Debug, Clone, Default)]
pub struct GatewayMetrics {
    pub total_calls: u64,
    pub fraud_calls: u64,
    pub calls_per_minute: f64,
    pub avg_call_duration: f64,
    pub distinct_destinations: u64,
}

/// Event publisher port
#[async_trait]
pub trait EventPublisher: Send + Sync {
    /// Publishes a domain event
    async fn publish(&self, event: Box<dyn DomainEvent>) -> DomainResult<()>;

    /// Publishes multiple events
    async fn publish_all(&self, events: Vec<Box<dyn DomainEvent>>) -> DomainResult<()>;
}

/// NCC compliance reporting port
#[async_trait]
pub trait NCCReportingPort: Send + Sync {
    /// Reports a fraud alert to NCC ATRS API
    async fn report_alert(&self, alert: &FraudAlert) -> DomainResult<String>;

    /// Checks if NCC API is available
    async fn health_check(&self) -> DomainResult<bool>;
}

#[cfg(test)]
pub mod mocks {
    //! Mock implementations for testing
    use super::*;
    use std::sync::Arc;
    use tokio::sync::RwLock;

    /// In-memory mock implementation of CallRepository for testing
    #[derive(Default)]
    pub struct MockCallRepository {
        calls: Arc<RwLock<Vec<Call>>>,
    }

    impl MockCallRepository {
        pub fn new() -> Self {
            Self::default()
        }
    }

    #[async_trait]
    impl CallRepository for MockCallRepository {
        async fn save(&self, call: &Call) -> DomainResult<()> {
            let mut calls = self.calls.write().await;
            calls.push(call.clone());
            Ok(())
        }

        async fn find_by_id(&self, id: &CallId) -> DomainResult<Option<Call>> {
            let calls = self.calls.read().await;
            Ok(calls.iter().find(|c| c.id() == id).cloned())
        }

        async fn find_calls_in_window(
            &self,
            b_number: &MSISDN,
            window_start: DateTime<Utc>,
            window_end: DateTime<Utc>,
        ) -> DomainResult<Vec<Call>> {
            let calls = self.calls.read().await;
            Ok(calls
                .iter()
                .filter(|c| {
                    c.b_number() == b_number
                        && c.timestamp() >= window_start
                        && c.timestamp() <= window_end
                        && !c.is_flagged()
                })
                .cloned()
                .collect())
        }

        async fn count_distinct_callers(
            &self,
            b_number: &MSISDN,
            window_start: DateTime<Utc>,
            window_end: DateTime<Utc>,
        ) -> DomainResult<usize> {
            let calls = self.find_calls_in_window(b_number, window_start, window_end).await?;
            let unique: std::collections::HashSet<_> = calls.iter().map(|c| c.a_number().as_str()).collect();
            Ok(unique.len())
        }

        async fn flag_as_fraud(&self, _call_ids: &[CallId], _alert_id: &str) -> DomainResult<usize> {
            Ok(0) // Mock implementation
        }

        async fn cleanup_old_calls(&self, _before: DateTime<Utc>) -> DomainResult<usize> {
            Ok(0)
        }
    }

    /// In-memory mock implementation of DetectionCache
    #[derive(Default)]
    pub struct MockDetectionCache {
        windows: Arc<RwLock<std::collections::HashMap<String, std::collections::HashSet<String>>>>,
        cooldowns: Arc<RwLock<std::collections::HashSet<String>>>,
    }

    impl MockDetectionCache {
        pub fn new() -> Self {
            Self::default()
        }
    }

    #[async_trait]
    impl DetectionCache for MockDetectionCache {
        async fn add_caller_to_window(
            &self,
            b_number: &MSISDN,
            a_number: &MSISDN,
            _window_seconds: u32,
        ) -> DomainResult<()> {
            let mut windows = self.windows.write().await;
            windows
                .entry(b_number.to_string())
                .or_default()
                .insert(a_number.to_string());
            Ok(())
        }

        async fn get_distinct_caller_count(&self, b_number: &MSISDN) -> DomainResult<usize> {
            let windows = self.windows.read().await;
            Ok(windows.get(&b_number.to_string()).map(|s| s.len()).unwrap_or(0))
        }

        async fn get_distinct_callers(&self, b_number: &MSISDN) -> DomainResult<Vec<String>> {
            let windows = self.windows.read().await;
            Ok(windows
                .get(&b_number.to_string())
                .map(|s| s.iter().cloned().collect())
                .unwrap_or_default())
        }

        async fn is_in_cooldown(&self, b_number: &MSISDN) -> DomainResult<bool> {
            let cooldowns = self.cooldowns.read().await;
            Ok(cooldowns.contains(&b_number.to_string()))
        }

        async fn set_cooldown(&self, b_number: &MSISDN, _seconds: u32) -> DomainResult<()> {
            let mut cooldowns = self.cooldowns.write().await;
            cooldowns.insert(b_number.to_string());
            Ok(())
        }

        async fn is_ip_blacklisted(&self, _ip: &IPAddress) -> DomainResult<bool> {
            Ok(false)
        }

        async fn add_to_blacklist(&self, _ip: &IPAddress, _ttl_seconds: Option<u32>) -> DomainResult<()> {
            Ok(())
        }
    }
}
