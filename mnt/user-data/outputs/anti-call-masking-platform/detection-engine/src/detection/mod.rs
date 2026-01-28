//! Core detection algorithms for anti-call masking and SIM-box detection.
//!
//! This module contains the main detection logic:
//! - CLI vs Source IP validation
//! - SIM-box behavioral analysis
//! - Header integrity checks
//! - Pattern-based fraud detection

use crate::{
    cache::CacheManager,
    config::AppConfig,
    db::YugabyteClient,
    models::{CallEvent, FraudAlert, GatewayProfile},
    nigerian_prefixes,
};
use chrono::{DateTime, Utc};
use once_cell::sync::Lazy;
use regex::Regex;
use std::collections::HashSet;
use std::net::IpAddr;
use std::sync::Arc;
use thiserror::Error;
use uuid::Uuid;

/// Nigerian mobile number pattern (+234 or 0 followed by 7xx, 8xx, 9xx)
static NIGERIAN_MOBILE_REGEX: Lazy<Regex> = Lazy::new(|| {
    Regex::new(r"^(\+234|0)[789][01]\d{8}$").expect("Invalid regex pattern")
});

/// E.164 format pattern
static E164_REGEX: Lazy<Regex> = Lazy::new(|| {
    Regex::new(r"^\+[1-9]\d{1,14}$").expect("Invalid regex pattern")
});

#[derive(Debug, Error)]
pub enum DetectionError {
    #[error("Cache error: {0}")]
    CacheError(String),
    
    #[error("Database error: {0}")]
    DatabaseError(String),
    
    #[error("Invalid input: {0}")]
    InvalidInput(String),
    
    #[error("Configuration error: {0}")]
    ConfigError(String),
}

/// Types of fraud that can be detected
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum FraudType {
    /// International trunk sending local Nigerian CLI
    CallMasking,
    /// SIM-box detected via behavioral analysis
    SimBox,
    /// Source IP is on NCC blacklist
    BlacklistedIp,
    /// P-Asserted-Identity mismatch with From header
    HeaderIntegrity,
    /// Excessive calls per minute from single source
    RateLimitExceeded,
    /// Very short average call duration (SIM-box indicator)
    LowAcd,
    /// High ratio of unique destinations (SIM-box indicator)
    HighUniqueDestinations,
    /// Anonymous or private caller ID from untrusted source
    AnonymousCaller,
    /// STIR/SHAKEN verification failed
    StirShakenFailed,
}

impl FraudType {
    /// Get the severity level (1-5, 5 being most severe)
    pub fn severity(&self) -> u8 {
        match self {
            FraudType::CallMasking => 5,
            FraudType::SimBox => 5,
            FraudType::BlacklistedIp => 5,
            FraudType::HeaderIntegrity => 4,
            FraudType::RateLimitExceeded => 3,
            FraudType::LowAcd => 3,
            FraudType::HighUniqueDestinations => 3,
            FraudType::AnonymousCaller => 2,
            FraudType::StirShakenFailed => 4,
        }
    }

    /// Get the NCC event type code for reporting
    pub fn ncc_event_code(&self) -> &'static str {
        match self {
            FraudType::CallMasking => "CLI_MASK",
            FraudType::SimBox => "SIM_BOX",
            FraudType::BlacklistedIp => "BLACKLIST",
            FraudType::HeaderIntegrity => "HDR_INTEG",
            FraudType::RateLimitExceeded => "RATE_LIM",
            FraudType::LowAcd => "LOW_ACD",
            FraudType::HighUniqueDestinations => "HIGH_DST",
            FraudType::AnonymousCaller => "ANON_CLI",
            FraudType::StirShakenFailed => "STIR_FAIL",
        }
    }
}

/// Result of a detection check
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct DetectionResult {
    /// Unique ID for this detection
    pub id: Uuid,
    /// The call that was analyzed
    pub call_id: String,
    /// Whether fraud was detected
    pub is_fraud: bool,
    /// Types of fraud detected (if any)
    pub fraud_types: Vec<FraudType>,
    /// Confidence score (0.0 - 1.0)
    pub confidence: f64,
    /// Recommended action
    pub action: DetectionAction,
    /// Detection latency in microseconds
    pub latency_us: u64,
    /// Timestamp of detection
    pub timestamp: DateTime<Utc>,
    /// MNP lookup result (if applicable)
    pub mnp_result: Option<MnpLookupResult>,
    /// Detailed reason for each fraud type
    pub reasons: Vec<String>,
}

/// MNP lookup result
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct MnpLookupResult {
    pub msisdn: String,
    pub is_ported: bool,
    pub current_operator: String,
    pub routing_number: String,
    pub cached: bool,
    pub lookup_latency_us: u64,
}

/// Recommended action based on detection
#[derive(Debug, Clone, Copy, PartialEq, Eq, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum DetectionAction {
    /// Allow the call to proceed
    Allow,
    /// Block the call immediately
    Block,
    /// Allow but flag for review
    Flag,
    /// Apply penalty billing (international rate)
    PenaltyBilling,
    /// Strip the CLI and replace with "Masked-Call"
    StripCli,
    /// Route to honeypot for analysis
    Honeypot,
}

/// Thresholds for SIM-box detection
#[derive(Debug, Clone)]
pub struct DetectionThresholds {
    /// Maximum calls per minute before flagging
    pub cpm_warning: u32,
    pub cpm_critical: u32,
    /// Minimum average call duration (seconds) before flagging
    pub acd_warning: f64,
    pub acd_critical: f64,
    /// Maximum concurrent calls from single source
    pub concurrent_warning: u32,
    pub concurrent_critical: u32,
    /// Maximum unique destinations in window before flagging
    pub unique_dst_warning: u32,
    pub unique_dst_critical: u32,
}

impl Default for DetectionThresholds {
    fn default() -> Self {
        Self {
            cpm_warning: 40,
            cpm_critical: 60,
            acd_warning: 10.0,
            acd_critical: 5.0,
            concurrent_warning: 20,
            concurrent_critical: 50,
            unique_dst_warning: 100,
            unique_dst_critical: 200,
        }
    }
}

/// Main detection engine
pub struct DetectionEngine {
    cache: Arc<CacheManager>,
    yugabyte: Arc<YugabyteClient>,
    config: AppConfig,
    thresholds: DetectionThresholds,
    /// Set of blacklisted IPs (loaded from cache)
    blacklisted_ips: Arc<tokio::sync::RwLock<HashSet<IpAddr>>>,
    /// Set of international gateway IPs (Group 10)
    international_gateways: Arc<tokio::sync::RwLock<HashSet<IpAddr>>>,
}

impl DetectionEngine {
    pub fn new(
        cache: Arc<CacheManager>,
        yugabyte: Arc<YugabyteClient>,
        config: AppConfig,
    ) -> Result<Self, DetectionError> {
        Ok(Self {
            cache,
            yugabyte,
            config,
            thresholds: DetectionThresholds::default(),
            blacklisted_ips: Arc::new(tokio::sync::RwLock::new(HashSet::new())),
            international_gateways: Arc::new(tokio::sync::RwLock::new(HashSet::new())),
        })
    }

    /// Main detection entry point
    pub async fn detect(&self, event: &CallEvent) -> Result<DetectionResult, DetectionError> {
        let start = std::time::Instant::now();
        let mut fraud_types = Vec::new();
        let mut reasons = Vec::new();
        let mut confidence = 0.0;

        // Step 1: Check if source IP is blacklisted
        if self.is_blacklisted(&event.source_ip).await? {
            fraud_types.push(FraudType::BlacklistedIp);
            reasons.push(format!("Source IP {} is on NCC blacklist", event.source_ip));
            confidence = 1.0;
        }

        // Step 2: CLI vs Source IP validation (anti-masking)
        if self.is_international_gateway(&event.source_ip).await?
            && self.is_nigerian_number(&event.caller_id)
        {
            fraud_types.push(FraudType::CallMasking);
            reasons.push(format!(
                "International gateway {} sending Nigerian CLI {}",
                event.source_ip, event.caller_id
            ));
            confidence = confidence.max(0.95);
        }

        // Step 3: Header integrity check
        if let Some(pai) = &event.p_asserted_identity {
            if !self.headers_consistent(&event.caller_id, pai) {
                fraud_types.push(FraudType::HeaderIntegrity);
                reasons.push(format!(
                    "P-Asserted-Identity '{}' doesn't match From '{}'",
                    pai, event.caller_id
                ));
                confidence = confidence.max(0.8);
            }
        }

        // Step 4: Anonymous caller check
        if self.is_anonymous_caller(&event.caller_id) {
            if self.is_international_gateway(&event.source_ip).await? {
                fraud_types.push(FraudType::AnonymousCaller);
                reasons.push("Anonymous caller from international gateway".to_string());
                confidence = confidence.max(0.7);
            }
        }

        // Step 5: SIM-box behavioral checks (using cache data)
        let behavioral_result = self.check_simbox_behavior(event).await?;
        if !behavioral_result.fraud_types.is_empty() {
            fraud_types.extend(behavioral_result.fraud_types);
            reasons.extend(behavioral_result.reasons);
            confidence = confidence.max(behavioral_result.confidence);
        }

        // Step 6: MNP lookup (for accurate routing, not fraud detection)
        let mnp_result = if self.is_nigerian_number(&event.called_number) {
            Some(self.lookup_mnp(&event.called_number).await?)
        } else {
            None
        };

        // Determine action based on fraud types
        let action = self.determine_action(&fraud_types, confidence);
        let is_fraud = !fraud_types.is_empty();

        let latency_us = start.elapsed().as_micros() as u64;

        Ok(DetectionResult {
            id: Uuid::new_v4(),
            call_id: event.call_id.clone(),
            is_fraud,
            fraud_types,
            confidence,
            action,
            latency_us,
            timestamp: Utc::now(),
            mnp_result,
            reasons,
        })
    }

    /// Check if IP is on the blacklist
    async fn is_blacklisted(&self, ip: &str) -> Result<bool, DetectionError> {
        // First check local cache
        if let Ok(addr) = ip.parse::<IpAddr>() {
            let blacklist = self.blacklisted_ips.read().await;
            if blacklist.contains(&addr) {
                return Ok(true);
            }
        }

        // Then check DragonflyDB
        self.cache
            .is_blacklisted(ip)
            .await
            .map_err(|e| DetectionError::CacheError(e.to_string()))
    }

    /// Check if IP belongs to international gateway group
    async fn is_international_gateway(&self, ip: &str) -> Result<bool, DetectionError> {
        // First check local cache
        if let Ok(addr) = ip.parse::<IpAddr>() {
            let gateways = self.international_gateways.read().await;
            if gateways.contains(&addr) {
                return Ok(true);
            }
        }

        // Then check DragonflyDB
        self.cache
            .is_gateway_group(ip, 10) // Group 10 = International
            .await
            .map_err(|e| DetectionError::CacheError(e.to_string()))
    }

    /// Check if number is a Nigerian mobile number
    fn is_nigerian_number(&self, number: &str) -> bool {
        NIGERIAN_MOBILE_REGEX.is_match(number) || nigerian_prefixes::is_nigerian_mobile(number)
    }

    /// Check if caller ID is anonymous/private
    fn is_anonymous_caller(&self, caller_id: &str) -> bool {
        let lower = caller_id.to_lowercase();
        lower.contains("anonymous")
            || lower.contains("private")
            || lower.contains("restricted")
            || lower.contains("unknown")
            || lower == "unavailable"
    }

    /// Check if headers are consistent
    fn headers_consistent(&self, from: &str, pai: &str) -> bool {
        // Extract the number portion from SIP URIs
        let from_num = self.extract_number(from);
        let pai_num = self.extract_number(pai);

        // For Nigerian numbers, they should match
        if self.is_nigerian_number(&from_num) && self.is_nigerian_number(&pai_num) {
            return self.normalize_number(&from_num) == self.normalize_number(&pai_num);
        }

        true // Non-Nigerian numbers: allow mismatch
    }

    /// Extract number from SIP URI or display name
    fn extract_number(&self, input: &str) -> String {
        // Handle sip:+234xxx@domain format
        if let Some(start) = input.find("sip:") {
            if let Some(end) = input[start..].find('@') {
                return input[start + 4..start + end].to_string();
            }
        }

        // Handle tel:+234xxx format
        if let Some(start) = input.find("tel:") {
            return input[start + 4..].trim_end_matches('>').to_string();
        }

        // Return as-is
        input.to_string()
    }

    /// Normalize Nigerian number to E.164 format
    fn normalize_number(&self, number: &str) -> String {
        let clean: String = number.chars().filter(|c| c.is_ascii_digit() || *c == '+').collect();
        
        if clean.starts_with("+234") {
            clean
        } else if clean.starts_with("234") {
            format!("+{}", clean)
        } else if clean.starts_with("0") {
            format!("+234{}", &clean[1..])
        } else {
            clean
        }
    }

    /// Check for SIM-box behavioral patterns
    async fn check_simbox_behavior(
        &self,
        event: &CallEvent,
    ) -> Result<BehavioralCheckResult, DetectionError> {
        let mut fraud_types = Vec::new();
        let mut reasons = Vec::new();
        let mut confidence = 0.0;

        // Get metrics from cache
        let metrics = self
            .cache
            .get_caller_metrics(&event.caller_id)
            .await
            .map_err(|e| DetectionError::CacheError(e.to_string()))?;

        // Check CPM (Calls Per Minute)
        if let Some(cpm) = metrics.cpm {
            if cpm >= self.thresholds.cpm_critical {
                fraud_types.push(FraudType::SimBox);
                reasons.push(format!("CPM {} exceeds critical threshold {}", cpm, self.thresholds.cpm_critical));
                confidence = confidence.max(0.9);
            } else if cpm >= self.thresholds.cpm_warning {
                fraud_types.push(FraudType::RateLimitExceeded);
                reasons.push(format!("CPM {} exceeds warning threshold {}", cpm, self.thresholds.cpm_warning));
                confidence = confidence.max(0.6);
            }
        }

        // Check ACD (Average Call Duration)
        if let Some(acd) = metrics.acd {
            if acd <= self.thresholds.acd_critical {
                fraud_types.push(FraudType::LowAcd);
                reasons.push(format!("ACD {:.1}s below critical threshold {:.1}s", acd, self.thresholds.acd_critical));
                confidence = confidence.max(0.85);
            } else if acd <= self.thresholds.acd_warning {
                fraud_types.push(FraudType::LowAcd);
                reasons.push(format!("ACD {:.1}s below warning threshold {:.1}s", acd, self.thresholds.acd_warning));
                confidence = confidence.max(0.5);
            }
        }

        // Check unique destinations
        if let Some(unique_dst) = metrics.unique_destinations {
            if unique_dst >= self.thresholds.unique_dst_critical as usize {
                fraud_types.push(FraudType::HighUniqueDestinations);
                reasons.push(format!(
                    "Unique destinations {} exceeds critical threshold {}",
                    unique_dst, self.thresholds.unique_dst_critical
                ));
                confidence = confidence.max(0.8);
            }
        }

        Ok(BehavioralCheckResult {
            fraud_types,
            reasons,
            confidence,
        })
    }

    /// Perform MNP lookup with hybrid caching
    async fn lookup_mnp(&self, msisdn: &str) -> Result<MnpLookupResult, DetectionError> {
        let start = std::time::Instant::now();
        let normalized = self.normalize_number(msisdn);

        // L1: Check DragonflyDB cache first
        if let Some(cached) = self
            .cache
            .get_mnp(&normalized)
            .await
            .map_err(|e| DetectionError::CacheError(e.to_string()))?
        {
            return Ok(MnpLookupResult {
                msisdn: normalized,
                is_ported: cached.is_ported,
                current_operator: cached.operator,
                routing_number: cached.routing_number,
                cached: true,
                lookup_latency_us: start.elapsed().as_micros() as u64,
            });
        }

        // L2: Query YugabyteDB
        let record = self
            .yugabyte
            .get_mnp_record(&normalized)
            .await
            .map_err(|e| DetectionError::DatabaseError(e.to_string()))?;

        if let Some(rec) = record {
            // Store in cache for next lookup
            self.cache
                .set_mnp(&normalized, &rec)
                .await
                .map_err(|e| DetectionError::CacheError(e.to_string()))?;

            return Ok(MnpLookupResult {
                msisdn: normalized,
                is_ported: rec.is_ported,
                current_operator: rec.hosting_network.clone(),
                routing_number: rec.routing_number.clone(),
                cached: false,
                lookup_latency_us: start.elapsed().as_micros() as u64,
            });
        }

        // Not found in database - use default operator based on prefix
        let operator = nigerian_prefixes::get_default_operator(&normalized)
            .unwrap_or("Unknown")
            .to_string();
        
        let routing_number = match operator.as_str() {
            "MTN" => "D013",
            "Airtel" => "D018",
            "Glo" => "D015",
            "9mobile" => "D019",
            _ => "",
        };

        Ok(MnpLookupResult {
            msisdn: normalized,
            is_ported: false,
            current_operator: operator,
            routing_number: routing_number.to_string(),
            cached: false,
            lookup_latency_us: start.elapsed().as_micros() as u64,
        })
    }

    /// Determine the action based on fraud types and confidence
    fn determine_action(&self, fraud_types: &[FraudType], confidence: f64) -> DetectionAction {
        if fraud_types.is_empty() {
            return DetectionAction::Allow;
        }

        // Immediate block for critical fraud types
        if fraud_types.contains(&FraudType::BlacklistedIp) {
            return DetectionAction::Block;
        }

        if fraud_types.contains(&FraudType::CallMasking) && confidence >= 0.9 {
            return DetectionAction::PenaltyBilling;
        }

        if fraud_types.contains(&FraudType::SimBox) && confidence >= 0.85 {
            return DetectionAction::Block;
        }

        if fraud_types.contains(&FraudType::HeaderIntegrity) {
            return DetectionAction::StripCli;
        }

        // Lower confidence - flag for review
        if confidence >= 0.5 {
            return DetectionAction::Flag;
        }

        DetectionAction::Allow
    }

    /// Reload blacklist from database
    pub async fn reload_blacklist(&self) -> Result<(), DetectionError> {
        let ips = self
            .yugabyte
            .get_blacklisted_ips()
            .await
            .map_err(|e| DetectionError::DatabaseError(e.to_string()))?;

        let mut blacklist = self.blacklisted_ips.write().await;
        blacklist.clear();
        for ip_str in ips {
            if let Ok(ip) = ip_str.parse::<IpAddr>() {
                blacklist.insert(ip);
            }
        }

        tracing::info!("Reloaded {} blacklisted IPs", blacklist.len());
        Ok(())
    }

    /// Reload international gateway list from database
    pub async fn reload_gateways(&self) -> Result<(), DetectionError> {
        let ips = self
            .yugabyte
            .get_gateway_ips(10) // Group 10 = International
            .await
            .map_err(|e| DetectionError::DatabaseError(e.to_string()))?;

        let mut gateways = self.international_gateways.write().await;
        gateways.clear();
        for ip_str in ips {
            if let Ok(ip) = ip_str.parse::<IpAddr>() {
                gateways.insert(ip);
            }
        }

        tracing::info!("Reloaded {} international gateway IPs", gateways.len());
        Ok(())
    }
}

/// Result of behavioral analysis
struct BehavioralCheckResult {
    fraud_types: Vec<FraudType>,
    reasons: Vec<String>,
    confidence: f64,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_nigerian_number_detection() {
        let engine = create_test_engine();
        
        assert!(engine.is_nigerian_number("+2348031234567"));
        assert!(engine.is_nigerian_number("08031234567"));
        assert!(engine.is_nigerian_number("+2349011234567"));
        assert!(!engine.is_nigerian_number("+14151234567"));
        assert!(!engine.is_nigerian_number("+442071234567"));
    }

    #[test]
    fn test_number_normalization() {
        let engine = create_test_engine();
        
        assert_eq!(engine.normalize_number("08031234567"), "+2348031234567");
        assert_eq!(engine.normalize_number("2348031234567"), "+2348031234567");
        assert_eq!(engine.normalize_number("+2348031234567"), "+2348031234567");
    }

    #[test]
    fn test_anonymous_detection() {
        let engine = create_test_engine();
        
        assert!(engine.is_anonymous_caller("Anonymous"));
        assert!(engine.is_anonymous_caller("ANONYMOUS"));
        assert!(engine.is_anonymous_caller("Private"));
        assert!(engine.is_anonymous_caller("Restricted"));
        assert!(!engine.is_anonymous_caller("+2348031234567"));
    }

    #[test]
    fn test_fraud_type_severity() {
        assert_eq!(FraudType::CallMasking.severity(), 5);
        assert_eq!(FraudType::SimBox.severity(), 5);
        assert_eq!(FraudType::BlacklistedIp.severity(), 5);
        assert_eq!(FraudType::AnonymousCaller.severity(), 2);
    }

    // Helper to create a test engine without database connections
    fn create_test_engine() -> DetectionEngine {
        // This would need mocking for full tests
        unimplemented!("Use integration tests for full engine testing")
    }
}
