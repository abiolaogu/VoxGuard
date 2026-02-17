//! Integration tests for fraud detection algorithms
//!
//! These tests verify the end-to-end behavior of the detection service
//! with realistic call data scenarios.

use acm_detection::domain::value_objects::*;
use acm_detection::domain::aggregates::{Call, FraudAlert};
use acm_detection::domain::aggregates::fraud_alert::AlertStatus;
use acm_detection::domain::errors::DomainResult;
use acm_detection::application::detection_service::{DetectionService, DetectionConfig};
use acm_detection::application::commands::RegisterCallCommand;
use acm_detection::ports::{CallRepository, DetectionCache, AlertRepository, TimeSeriesStore};
use std::sync::Arc;
use tokio::sync::RwLock;
use std::collections::{HashMap, HashSet};
use chrono::{DateTime, Utc, Duration};

// === Mock Implementations for Integration Testing ===

#[derive(Clone)]
struct InMemoryDetectionCache {
    // b_number -> (a_numbers, expiry_time)
    window_data: Arc<RwLock<HashMap<String, (HashSet<String>, DateTime<Utc>)>>>,
    // b_number -> cooldown_expiry
    cooldowns: Arc<RwLock<HashMap<String, DateTime<Utc>>>>,
    // Blacklisted IPs
    blacklist: Arc<RwLock<HashSet<String>>>,
}

impl InMemoryDetectionCache {
    fn new() -> Self {
        Self {
            window_data: Arc::new(RwLock::new(HashMap::new())),
            cooldowns: Arc::new(RwLock::new(HashMap::new())),
            blacklist: Arc::new(RwLock::new(HashSet::new())),
        }
    }

    async fn blacklist_ip(&self, ip: &str) {
        self.blacklist.write().await.insert(ip.to_string());
    }
}

#[async_trait::async_trait]
impl DetectionCache for InMemoryDetectionCache {
    async fn add_caller_to_window(
        &self,
        b_number: &MSISDN,
        a_number: &MSISDN,
        window_seconds: u32,
    ) -> DomainResult<()> {
        let mut data = self.window_data.write().await;
        let expiry = Utc::now() + Duration::seconds(window_seconds as i64);
        let key = b_number.to_string();

        data.entry(key)
            .or_insert_with(|| (HashSet::new(), expiry))
            .0
            .insert(a_number.to_string());

        Ok(())
    }

    async fn get_distinct_caller_count(&self, b_number: &MSISDN) -> DomainResult<usize> {
        let data = self.window_data.read().await;
        Ok(data
            .get(&b_number.to_string())
            .map(|(set, _)| set.len())
            .unwrap_or(0))
    }

    async fn get_distinct_callers(&self, b_number: &MSISDN) -> DomainResult<Vec<String>> {
        let data = self.window_data.read().await;
        Ok(data
            .get(&b_number.to_string())
            .map(|(set, _)| set.iter().cloned().collect())
            .unwrap_or_default())
    }

    async fn set_cooldown(&self, b_number: &MSISDN, seconds: u32) -> DomainResult<()> {
        let expiry = Utc::now() + Duration::seconds(seconds as i64);
        self.cooldowns
            .write()
            .await
            .insert(b_number.to_string(), expiry);
        Ok(())
    }

    async fn is_in_cooldown(&self, b_number: &MSISDN) -> DomainResult<bool> {
        let cooldowns = self.cooldowns.read().await;
        Ok(cooldowns
            .get(&b_number.to_string())
            .map(|expiry| *expiry > Utc::now())
            .unwrap_or(false))
    }

    async fn is_ip_blacklisted(&self, ip: &IPAddress) -> DomainResult<bool> {
        Ok(self.blacklist.read().await.contains(&ip.to_string()))
    }

    async fn add_to_blacklist(&self, ip: &IPAddress, _ttl_seconds: Option<u32>) -> DomainResult<()> {
        self.blacklist.write().await.insert(ip.to_string());
        Ok(())
    }
}

struct InMemoryCallRepository {
    calls: Arc<RwLock<Vec<Call>>>,
}

impl InMemoryCallRepository {
    fn new() -> Self {
        Self {
            calls: Arc::new(RwLock::new(Vec::new())),
        }
    }

    async fn get_all_calls(&self) -> Vec<Call> {
        self.calls.read().await.clone()
    }
}

#[async_trait::async_trait]
impl CallRepository for InMemoryCallRepository {
    async fn save(&self, call: &Call) -> DomainResult<()> {
        self.calls.write().await.push(call.clone());
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
        let distinct: HashSet<String> = calls
            .iter()
            .map(|call| call.a_number().to_string())
            .collect();
        Ok(distinct.len())
    }

    async fn flag_as_fraud(&self, call_ids: &[CallId], alert_id: &str) -> DomainResult<usize> {
        let mut calls = self.calls.write().await;
        let mut flagged = 0usize;
        for call in calls.iter_mut() {
            if call_ids.iter().any(|id| id == call.id()) {
                if call.flag_as_fraud(alert_id.to_string(), FraudScore::new(0.9)).is_ok() {
                    flagged += 1;
                }
            }
        }
        Ok(flagged)
    }

    async fn cleanup_old_calls(&self, before: DateTime<Utc>) -> DomainResult<usize> {
        let mut calls = self.calls.write().await;
        let original_len = calls.len();
        calls.retain(|call| call.is_flagged() || call.timestamp() >= before);
        Ok(original_len.saturating_sub(calls.len()))
    }
}

struct InMemoryAlertRepository {
    alerts: Arc<RwLock<Vec<FraudAlert>>>,
}

impl InMemoryAlertRepository {
    fn new() -> Self {
        Self {
            alerts: Arc::new(RwLock::new(Vec::new())),
        }
    }

    async fn get_all_alerts(&self) -> Vec<FraudAlert> {
        self.alerts.read().await.clone()
    }
}

#[async_trait::async_trait]
impl AlertRepository for InMemoryAlertRepository {
    async fn save(&self, alert: &FraudAlert) -> DomainResult<()> {
        self.alerts.write().await.push(alert.clone());
        Ok(())
    }

    async fn find_by_id(&self, id: uuid::Uuid) -> DomainResult<Option<FraudAlert>> {
        let alerts = self.alerts.read().await;
        Ok(alerts.iter().find(|a| a.id() == id).cloned())
    }

    async fn find_recent(&self, _minutes: i64) -> DomainResult<Vec<FraudAlert>> {
        Ok(self.alerts.read().await.clone())
    }

    async fn find_by_status(&self, status: AlertStatus) -> DomainResult<Vec<FraudAlert>> {
        let alerts = self.alerts.read().await;
        Ok(alerts.iter().filter(|a| a.status() == status).cloned().collect())
    }

    async fn find_by_b_number(&self, b_number: &MSISDN) -> DomainResult<Vec<FraudAlert>> {
        let alerts = self.alerts.read().await;
        Ok(alerts
            .iter()
            .filter(|a| a.b_number() == b_number)
            .cloned()
            .collect())
    }

    async fn count_pending(&self) -> DomainResult<usize> {
        let alerts = self.alerts.read().await;
        Ok(alerts.iter().filter(|a| a.is_pending()).count())
    }
}

struct InMemoryTimeSeriesStore;

#[async_trait::async_trait]
impl TimeSeriesStore for InMemoryTimeSeriesStore {
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
    ) -> DomainResult<acm_detection::ports::GatewayMetrics> {
        Ok(Default::default())
    }

    async fn get_threat_level(
        &self,
        b_number: &MSISDN,
        _window_seconds: u32,
        _threshold: usize,
    ) -> DomainResult<acm_detection::domain::aggregates::ThreatLevel> {
        use acm_detection::domain::aggregates::ThreatLevel;
        Ok(ThreatLevel::assess(
            b_number.clone(),
            0, 0, 0,
            Utc::now(),
            Utc::now(),
            5,
        ))
    }

    async fn get_elevated_threats(&self, _threshold: usize) -> DomainResult<Vec<acm_detection::domain::aggregates::ThreatLevel>> {
        Ok(vec![])
    }
}

// === Helper Functions ===

fn create_test_service() -> (
    DetectionService<InMemoryDetectionCache, InMemoryCallRepository, InMemoryAlertRepository, InMemoryTimeSeriesStore>,
    Arc<InMemoryDetectionCache>,
    Arc<InMemoryCallRepository>,
    Arc<InMemoryAlertRepository>,
) {
    let cache = Arc::new(InMemoryDetectionCache::new());
    let call_repo = Arc::new(InMemoryCallRepository::new());
    let alert_repo = Arc::new(InMemoryAlertRepository::new());
    let ts_store = Arc::new(InMemoryTimeSeriesStore);

    let config = DetectionConfig {
        window: DetectionWindow::new(5).unwrap(),
        threshold: DetectionThreshold::new(5).unwrap(),
        cooldown_seconds: 60,
        auto_block_enabled: true,
    };

    let service = DetectionService::new(
        cache.clone(),
        call_repo.clone(),
        alert_repo.clone(),
        ts_store,
        config,
    );

    (service, cache, call_repo, alert_repo)
}

// === Integration Tests ===

#[tokio::test]
async fn test_cli_masking_detection() {
    // Scenario: International gateway with Nigerian CLI
    // Multiple calls from different "Nigerian" numbers but same international IP
    // This indicates CLI masking (spoofing)

    let (service, _, call_repo, alert_repo) = create_test_service();

    let b_number = "+2348098765432";
    let international_ip = "8.8.8.8"; // Public IP simulating international gateway

    // Register 5 calls from different A-numbers (simulating CLI masking)
    for i in 1..=5 {
        let cmd = RegisterCallCommand {
            call_id: None,
            a_number: format!("+23480{:08}", 10000000 + i),
            b_number: b_number.to_string(),
            source_ip: international_ip.to_string(),
            switch_id: Some("gw-intl-1".to_string()),
        };

        let result = service.register_call(cmd).await.unwrap();

        if i < 5 {
            assert_eq!(result.status, "processed");
            assert!(result.alert.is_none());
        } else {
            // 5th call should trigger alert
            assert_eq!(result.status, "alert");
            assert!(result.alert.is_some());

            let alert = result.alert.unwrap();
            assert_eq!(alert.fraud_type, "MASKING_ATTACK");
            assert_eq!(alert.distinct_callers, 5);
        }
    }

    // Verify alert was created
    let alerts = alert_repo.get_all_alerts().await;
    assert_eq!(alerts.len(), 1);
    assert_eq!(alerts[0].distinct_callers(), 5);
    assert_eq!(alerts[0].fraud_type(), FraudType::MaskingAttack);

    // Verify calls were flagged
    let calls = call_repo.get_all_calls().await;
    assert_eq!(calls.len(), 5);
    let flagged_count = calls.iter().filter(|c| c.is_flagged()).count();
    assert_eq!(flagged_count, 5, "All 5 calls should be flagged as fraud");
}

#[tokio::test]
async fn test_sim_box_detection() {
    // Scenario: SIM box fraud - multiple calls from same source IP
    // with different Nigerian numbers (real SIM cards in a SIM box)

    let (service, _, call_repo, alert_repo) = create_test_service();

    let b_number = "+2348098765432";
    let sim_box_ip = "41.203.123.45"; // Nigerian IP range (simulated)

    // Register 5 calls from different SIM cards but same IP
    for i in 1..=5 {
        let cmd = RegisterCallCommand {
            call_id: None,
            a_number: format!("+23470{:08}", 20000000 + i * 1000), // Different MNO (Airtel)
            b_number: b_number.to_string(),
            source_ip: sim_box_ip.to_string(),
            switch_id: Some("gw-local-1".to_string()),
        };

        let result = service.register_call(cmd).await.unwrap();

        if i < 5 {
            assert_eq!(result.status, "processed");
        } else {
            // 5th call triggers alert
            assert_eq!(result.status, "alert");
            assert!(result.alert.is_some());
        }
    }

    // Verify detection
    let alerts = alert_repo.get_all_alerts().await;
    assert_eq!(alerts.len(), 1);

    // All calls should have same source IP
    let calls = call_repo.get_all_calls().await;
    let unique_ips: HashSet<_> = calls.iter().map(|c| c.source_ip().to_string()).collect();
    assert_eq!(unique_ips.len(), 1, "SIM box should use single IP");
}

#[tokio::test]
async fn test_sliding_window_algorithm() {
    // Scenario: Verify sliding window correctly counts distinct callers
    // and expires old entries

    let (service, cache, _, alert_repo) = create_test_service();

    let b_number = "+2348098765432";

    // Register 3 calls
    for i in 1..=3 {
        let cmd = RegisterCallCommand {
            call_id: None,
            a_number: format!("+23480{:08}", 30000000 + i),
            b_number: b_number.to_string(),
            source_ip: "192.168.1.1".to_string(),
            switch_id: None,
        };

        service.register_call(cmd).await.unwrap();
    }

    // Verify count in sliding window
    let count = cache
        .get_distinct_caller_count(&MSISDN::new(b_number).unwrap())
        .await
        .unwrap();
    assert_eq!(count, 3);

    // Simulate time passing (in real system, cache would expire entries)
    // For this test, we'll continue adding calls to reach threshold

    // Add 2 more calls to trigger alert (total 5)
    for i in 4..=5 {
        let cmd = RegisterCallCommand {
            call_id: None,
            a_number: format!("+23480{:08}", 30000000 + i),
            b_number: b_number.to_string(),
            source_ip: "192.168.1.1".to_string(),
            switch_id: None,
        };

        let result = service.register_call(cmd).await.unwrap();
        if i == 5 {
            assert_eq!(result.status, "alert");
        }
    }

    // Verify alert was triggered
    let alerts = alert_repo.get_all_alerts().await;
    assert_eq!(alerts.len(), 1);

    // Test cooldown - next call should be in cooldown
    let cmd = RegisterCallCommand {
        call_id: None,
        a_number: "+2348099999999".to_string(),
        b_number: b_number.to_string(),
        source_ip: "192.168.1.1".to_string(),
        switch_id: None,
    };

    let result = service.register_call(cmd).await.unwrap();
    assert_eq!(result.status, "cooldown");
}

#[tokio::test]
async fn test_blacklist_blocking() {
    // Scenario: Blacklisted IP should be immediately blocked

    let (service, cache, call_repo, alert_repo) = create_test_service();

    let blacklisted_ip = "10.0.0.1";

    // Blacklist the IP
    cache.blacklist_ip(blacklisted_ip).await;

    // Attempt to register call from blacklisted IP
    let cmd = RegisterCallCommand {
        call_id: None,
        a_number: "+2348011111111".to_string(),
        b_number: "+2348098765432".to_string(),
        source_ip: blacklisted_ip.to_string(),
        switch_id: None,
    };

    let result = service.register_call(cmd).await.unwrap();

    // Should be blocked
    assert_eq!(result.status, "blocked");
    assert!(result.call_id.is_empty());

    // Verify no call was persisted
    let calls = call_repo.get_all_calls().await;
    assert_eq!(calls.len(), 0);

    // Verify no alert was created
    let alerts = alert_repo.get_all_alerts().await;
    assert_eq!(alerts.len(), 0);
}

#[tokio::test]
async fn test_threshold_sensitivity() {
    // Scenario: Test different threshold values

    let cache = Arc::new(InMemoryDetectionCache::new());
    let call_repo = Arc::new(InMemoryCallRepository::new());
    let alert_repo = Arc::new(InMemoryAlertRepository::new());
    let ts_store = Arc::new(InMemoryTimeSeriesStore);

    // Low threshold (3 callers)
    let config = DetectionConfig {
        threshold: DetectionThreshold::new(3).unwrap(),
        ..Default::default()
    };

    let service = DetectionService::new(
        cache.clone(),
        call_repo.clone(),
        alert_repo.clone(),
        ts_store,
        config,
    );

    let b_number = "+2348098765432";

    // Register 3 calls - should trigger alert
    for i in 1..=3 {
        let cmd = RegisterCallCommand {
            call_id: None,
            a_number: format!("+23480{:08}", 40000000 + i),
            b_number: b_number.to_string(),
            source_ip: "192.168.1.1".to_string(),
            switch_id: None,
        };

        let result = service.register_call(cmd).await.unwrap();
        if i == 3 {
            assert_eq!(result.status, "alert");
            assert!(result.alert.is_some());
        }
    }

    let alerts = alert_repo.get_all_alerts().await;
    assert_eq!(alerts.len(), 1);
}

#[tokio::test]
async fn test_realistic_attack_scenario() {
    // Scenario: Realistic masking attack with burst of calls

    let (service, _, call_repo, alert_repo) = create_test_service();

    let b_number = "+2348098765432"; // Victim
    let attacker_ip = "8.8.8.8";

    // Burst of 10 calls in rapid succession (simulating automated attack)
    for i in 1..=10 {
        let cmd = RegisterCallCommand {
            call_id: Some(format!("sip-call-{}", i)),
            a_number: format!("+23480{:08}", 50000000 + i * 100),
            b_number: b_number.to_string(),
            source_ip: attacker_ip.to_string(),
            switch_id: Some("gw-international".to_string()),
        };

        service.register_call(cmd).await.unwrap();
    }

    // Verify detection
    let alerts = alert_repo.get_all_alerts().await;
    assert_eq!(alerts.len(), 1, "Should detect attack on 5th call");

    let alert = &alerts[0];
    // Current detection behavior creates the alert at threshold (5 callers)
    // and does not expand the same alert during cooldown.
    assert_eq!(alert.distinct_callers(), 5);
    assert_eq!(alert.fraud_type(), FraudType::MaskingAttack);
    assert_eq!(alert.severity(), Severity::Critical);

    // Verify threshold-window calls flagged when alert is created
    let calls = call_repo.get_all_calls().await;
    assert_eq!(calls.len(), 10);
    let flagged_count = calls.iter().filter(|c| c.is_flagged()).count();
    assert_eq!(flagged_count, 5);

    // Verify call metadata
    let first_call = &calls[0];
    assert_eq!(first_call.switch_id(), Some("gw-international"));
    assert!(first_call.raw_call_id().is_some());
}

#[tokio::test]
async fn test_false_positive_prevention() {
    // Scenario: Legitimate calls should not trigger false alerts
    // E.g., customer service center with multiple agents calling same number

    let (service, _, _, alert_repo) = create_test_service();

    let b_number = "+2348098765432"; // Call center
    let call_center_ip = "192.168.10.100"; // Internal IP

    // Register 4 calls from different agents (below threshold)
    for i in 1..=4 {
        let cmd = RegisterCallCommand {
            call_id: None,
            a_number: format!("+23480{:08}", 60000000 + i),
            b_number: b_number.to_string(),
            source_ip: call_center_ip.to_string(),
            switch_id: Some("pbx-internal".to_string()),
        };

        let result = service.register_call(cmd).await.unwrap();
        assert_eq!(result.status, "processed");
        assert!(result.alert.is_none());
    }

    // No alert should be created (below threshold of 5)
    let alerts = alert_repo.get_all_alerts().await;
    assert_eq!(alerts.len(), 0);
}
