//! Detection Service - Core fraud detection logic
//!
//! This service implements the primary use case of real-time call masking detection.

use std::sync::Arc;
use chrono::{Duration, Utc};
use tracing::{info, warn, instrument};

use crate::domain::{
    aggregates::{Call, FraudAlert},
    errors::{DomainError, DomainResult},
    value_objects::{
        CallId, DetectionThreshold, DetectionWindow, FraudScore, FraudType, IPAddress, MSISDN,
    },
};
use crate::ports::{CallRepository, DetectionCache, AlertRepository, TimeSeriesStore};
use crate::application::commands::{RegisterCallCommand, CallRegistrationResult, AlertResult};

/// Configuration for the detection service
#[derive(Debug, Clone)]
pub struct DetectionConfig {
    pub window: DetectionWindow,
    pub threshold: DetectionThreshold,
    pub cooldown_seconds: u32,
    pub auto_block_enabled: bool,
}

impl Default for DetectionConfig {
    fn default() -> Self {
        Self {
            window: DetectionWindow::default(),
            threshold: DetectionThreshold::default(),
            cooldown_seconds: 60,
            auto_block_enabled: true,
        }
    }
}

/// Main detection service
pub struct DetectionService<C, R, A, T>
where
    C: DetectionCache,
    R: CallRepository,
    A: AlertRepository,
    T: TimeSeriesStore,
{
    cache: Arc<C>,
    call_repo: Arc<R>,
    alert_repo: Arc<A>,
    ts_store: Arc<T>,
    config: DetectionConfig,
}

impl<C, R, A, T> DetectionService<C, R, A, T>
where
    C: DetectionCache,
    R: CallRepository,
    A: AlertRepository,
    T: TimeSeriesStore,
{
    /// Creates a new DetectionService
    pub fn new(
        cache: Arc<C>,
        call_repo: Arc<R>,
        alert_repo: Arc<A>,
        ts_store: Arc<T>,
        config: DetectionConfig,
    ) -> Self {
        Self {
            cache,
            call_repo,
            alert_repo,
            ts_store,
            config,
        }
    }

    /// Registers a new call and performs fraud detection
    #[instrument(skip(self), fields(b_number = %cmd.b_number))]
    pub async fn register_call(&self, cmd: RegisterCallCommand) -> DomainResult<CallRegistrationResult> {
        // Parse and validate input
        let a_number = MSISDN::new(&cmd.a_number)?;
        let b_number = MSISDN::new(&cmd.b_number)?;
        let source_ip = IPAddress::new(&cmd.source_ip)?;

        // Check if source IP is blacklisted
        if self.cache.is_ip_blacklisted(&source_ip).await? {
            return Ok(CallRegistrationResult {
                status: "blocked".into(),
                call_id: "".into(),
                distinct_callers: 0,
                alert: None,
            });
        }

        // Create call aggregate
        let (mut call, _event) = Call::new(a_number.clone(), b_number.clone(), source_ip);

        // Set optional switch info
        if let Some(switch_id) = cmd.switch_id {
            call.set_switch_info(switch_id, cmd.call_id);
        }

        // Add to sliding window cache
        self.cache
            .add_caller_to_window(&b_number, &a_number, self.config.window.seconds())
            .await?;

        // Get distinct caller count from cache
        let distinct_callers = self.cache.get_distinct_caller_count(&b_number).await?;

        // Persist call to repository
        self.call_repo.save(&call).await?;

        // Ingest to time-series store for analytics
        if let Err(e) = self.ts_store.ingest_call(&call).await {
            warn!("Failed to ingest call to time-series store: {}", e);
        }

        // Check threshold
        if distinct_callers >= self.config.threshold.distinct_callers() {
            // Check cooldown to prevent alert spam
            if self.cache.is_in_cooldown(&b_number).await? {
                return Ok(CallRegistrationResult {
                    status: "cooldown".into(),
                    call_id: call.id().to_string(),
                    distinct_callers,
                    alert: None,
                });
            }

            // Create fraud alert (clone source_ip to avoid move)
            let alert_source_ip = source_ip.clone();
            let alert_result = self
                .create_alert(&b_number, distinct_callers, &alert_source_ip)
                .await?;

            // Set cooldown
            self.cache
                .set_cooldown(&b_number, self.config.cooldown_seconds)
                .await?;

            info!(
                b_number = %b_number,
                distinct_callers = distinct_callers,
                "Fraud detected - masking attack"
            );

            return Ok(CallRegistrationResult {
                status: "alert".into(),
                call_id: call.id().to_string(),
                distinct_callers,
                alert: Some(alert_result),
            });
        }

        Ok(CallRegistrationResult {
            status: "processed".into(),
            call_id: call.id().to_string(),
            distinct_callers,
            alert: None,
        })
    }

    /// Creates a fraud alert when threshold is exceeded
    async fn create_alert(
        &self,
        b_number: &MSISDN,
        distinct_callers: usize,
        source_ip: &IPAddress,
    ) -> DomainResult<AlertResult> {
        let now = Utc::now();
        let window_start = now - Duration::seconds(self.config.window.seconds() as i64);

        // Get all distinct callers from cache
        let a_numbers = self.cache.get_distinct_callers(b_number).await?;

        // Calculate fraud score based on caller count vs threshold
        let score_value = (distinct_callers as f64 / self.config.threshold.distinct_callers() as f64)
            .min(1.0);
        let score = FraudScore::new(score_value);

        // Get calls in window for call IDs
        let calls = self.call_repo
            .find_calls_in_window(b_number, window_start, now)
            .await?;
        let call_ids: Vec<String> = calls.iter().map(|c| c.id().to_string()).collect();

        // Create alert aggregate
        let (alert, _event) = FraudAlert::create(
            b_number.clone(),
            FraudType::MaskingAttack,
            score,
            a_numbers,
            call_ids.clone(),
            vec![source_ip.to_string()],
            window_start,
            now,
        );

        // Persist alert
        self.alert_repo.save(&alert).await?;

        // Ingest to time-series for analytics
        if let Err(e) = self.ts_store.ingest_alert(&alert).await {
            warn!("Failed to ingest alert to time-series store: {}", e);
        }

        // Flag calls as fraud
        let call_ids_parsed: Vec<CallId> = call_ids
            .iter()
            .filter_map(|id| CallId::new(id).ok())
            .collect();
        self.call_repo
            .flag_as_fraud(&call_ids_parsed, &alert.id().to_string())
            .await?;

        Ok(AlertResult {
            alert_id: alert.id().to_string(),
            b_number: b_number.to_string(),
            fraud_type: alert.fraud_type().to_string(),
            severity: format!("{:?}", alert.severity()),
            score: score.value(),
            distinct_callers,
            description: "Masking Attack Detected - Multiple distinct callers to single B-number".into(),
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::ports::mocks::{MockCallRepository, MockDetectionCache};
    use std::sync::Arc;
    use tokio::sync::RwLock;

    // Mock TimeSeriesStore for testing
    struct MockTimeSeriesStore;

    #[async_trait::async_trait]
    impl TimeSeriesStore for MockTimeSeriesStore {
        async fn ingest_call(&self, _call: &Call) -> DomainResult<()> {
            Ok(())
        }
        async fn ingest_alert(&self, _alert: &FraudAlert) -> DomainResult<()> {
            Ok(())
        }
        async fn get_gateway_metrics(
            &self,
            _gateway_ip: &IPAddress,
            _window_seconds: u32,
        ) -> DomainResult<crate::ports::GatewayMetrics> {
            Ok(Default::default())
        }
        async fn get_threat_level(
            &self,
            b_number: &MSISDN,
            _window_seconds: u32,
            _threshold: usize,
        ) -> DomainResult<crate::domain::aggregates::ThreatLevel> {
            use crate::domain::aggregates::ThreatLevel;
            Ok(ThreatLevel::assess(
                b_number.clone(),
                0, 0, 0,
                Utc::now(),
                Utc::now(),
                5,
            ))
        }
        async fn get_elevated_threats(&self, _threshold: usize) -> DomainResult<Vec<crate::domain::aggregates::ThreatLevel>> {
            Ok(vec![])
        }
    }

    // Mock AlertRepository for testing
    struct MockAlertRepository {
        alerts: Arc<RwLock<Vec<FraudAlert>>>,
    }

    impl MockAlertRepository {
        fn new() -> Self {
            Self { alerts: Arc::new(RwLock::new(vec![])) }
        }
    }

    #[async_trait::async_trait]
    impl AlertRepository for MockAlertRepository {
        async fn save(&self, alert: &FraudAlert) -> DomainResult<()> {
            let mut alerts = self.alerts.write().await;
            alerts.push(alert.clone());
            Ok(())
        }
        async fn find_by_id(&self, _id: uuid::Uuid) -> DomainResult<Option<FraudAlert>> {
            Ok(None)
        }
        async fn find_recent(&self, _minutes: i64) -> DomainResult<Vec<FraudAlert>> {
            Ok(vec![])
        }
        async fn find_by_status(&self, _status: crate::domain::aggregates::fraud_alert::AlertStatus) -> DomainResult<Vec<FraudAlert>> {
            Ok(vec![])
        }
        async fn find_by_b_number(&self, _b_number: &MSISDN) -> DomainResult<Vec<FraudAlert>> {
            Ok(vec![])
        }
        async fn count_pending(&self) -> DomainResult<usize> {
            Ok(0)
        }
    }

    #[tokio::test]
    async fn test_register_call_normal() {
        let cache = Arc::new(MockDetectionCache::new());
        let call_repo = Arc::new(MockCallRepository::new());
        let alert_repo = Arc::new(MockAlertRepository::new());
        let ts_store = Arc::new(MockTimeSeriesStore);

        let service = DetectionService::new(
            cache,
            call_repo,
            alert_repo,
            ts_store,
            DetectionConfig::default(),
        );

        let cmd = RegisterCallCommand {
            call_id: None,
            a_number: "+2348011111111".into(),
            b_number: "+2348098765432".into(),
            source_ip: "192.168.1.1".into(),
            switch_id: None,
        };

        let result = service.register_call(cmd).await.unwrap();

        assert_eq!(result.status, "processed");
        assert_eq!(result.distinct_callers, 1);
        assert!(result.alert.is_none());
    }

    #[tokio::test]
    async fn test_register_call_triggers_alert() {
        let cache = Arc::new(MockDetectionCache::new());
        let call_repo = Arc::new(MockCallRepository::new());
        let alert_repo = Arc::new(MockAlertRepository::new());
        let ts_store = Arc::new(MockTimeSeriesStore);

        let config = DetectionConfig {
            threshold: DetectionThreshold::new(3).unwrap(),
            ..Default::default()
        };

        let service = DetectionService::new(
            cache.clone(),
            call_repo,
            alert_repo,
            ts_store,
            config,
        );

        // Register 3 calls from different A-numbers
        for i in 1..=3 {
            let cmd = RegisterCallCommand {
                call_id: None,
                a_number: format!("+23480{:08}", i),
                b_number: "+2348098765432".into(),
                source_ip: "192.168.1.1".into(),
                switch_id: None,
            };
            let result = service.register_call(cmd).await.unwrap();

            if i < 3 {
                assert_eq!(result.status, "processed");
            } else {
                assert_eq!(result.status, "alert");
                assert!(result.alert.is_some());
                let alert = result.alert.unwrap();
                assert_eq!(alert.fraud_type, "MASKING_ATTACK");
            }
        }
    }
}
