//! NCC Compliance Reporting Module
//! 
//! Handles real-time ATRS API reporting and daily SFTP batch uploads
//! to the Nigerian Communications Commission.

use anyhow::{Context, Result};
use chrono::{DateTime, Utc};
use reqwest::Client;
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use tokio::sync::RwLock;

use crate::models::FraudAlert;

/// NCC ATRS (Automated Trouble Reporting System) API client
pub struct NccReporter {
    client: Client,
    config: NccConfig,
    token_cache: Arc<RwLock<Option<TokenCache>>>,
}

#[derive(Clone)]
pub struct NccConfig {
    pub atrs_base_url: String,
    pub client_id: String,
    pub client_secret: String,
    pub icl_license: String,
    pub sftp_host: String,
    pub sftp_port: u16,
    pub sftp_user: String,
    pub sftp_key_path: String,
    pub enabled: bool,
}

impl Default for NccConfig {
    fn default() -> Self {
        Self {
            atrs_base_url: "https://atrs-api.ncc.gov.ng/v1".to_string(),
            client_id: String::new(),
            client_secret: String::new(),
            icl_license: String::new(),
            sftp_host: "sftp.ncc.gov.ng".to_string(),
            sftp_port: 22,
            sftp_user: String::new(),
            sftp_key_path: "/etc/acm/ncc_sftp_key".to_string(),
            enabled: false,
        }
    }
}

struct TokenCache {
    access_token: String,
    expires_at: DateTime<Utc>,
}

#[derive(Serialize)]
struct OAuthRequest {
    grant_type: String,
    client_id: String,
    client_secret: String,
    scope: String,
}

#[derive(Deserialize)]
struct OAuthResponse {
    access_token: String,
    token_type: String,
    expires_in: i64,
}

/// NCC fraud report payload
#[derive(Serialize, Debug)]
pub struct NccFraudReport {
    pub icl_license: String,
    pub event_type: String,
    pub calling_number: String,
    pub called_number: String,
    pub ingress_ip: String,
    pub egress_carrier: Option<String>,
    pub timestamp_wat: String,
    pub fraud_confidence: f64,
    pub detection_method: String,
    pub recommended_action: String,
    pub additional_data: serde_json::Value,
}

#[derive(Deserialize, Debug)]
pub struct NccReportResponse {
    pub report_id: String,
    pub status: String,
    pub message: Option<String>,
}

/// NCC event type codes as per 2026 regulations
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum NccEventType {
    CliMask,           // CLI_MASK - International call masking as local
    SimBox,            // SIM_BOX - SIM box detected
    Refiling,          // REFILING - International refiling
    HeaderManip,       // HDR_MANIP - SIP header manipulation
    UnauthorizedRoute, // UNAUTH_ROUTE - Unauthorized routing
    MnpBypas,         // MNP_BYPASS - MNP lookup bypass
}

impl NccEventType {
    pub fn as_str(&self) -> &'static str {
        match self {
            NccEventType::CliMask => "CLI_MASK",
            NccEventType::SimBox => "SIM_BOX",
            NccEventType::Refiling => "REFILING",
            NccEventType::HeaderManip => "HDR_MANIP",
            NccEventType::UnauthorizedRoute => "UNAUTH_ROUTE",
            NccEventType::MnpBypas => "MNP_BYPASS",
        }
    }

    pub fn from_str(s: &str) -> Option<Self> {
        match s {
            "CLI_MASK" => Some(NccEventType::CliMask),
            "SIM_BOX" => Some(NccEventType::SimBox),
            "REFILING" => Some(NccEventType::Refiling),
            "HDR_MANIP" => Some(NccEventType::HeaderManip),
            "UNAUTH_ROUTE" => Some(NccEventType::UnauthorizedRoute),
            "MNP_BYPASS" => Some(NccEventType::MnpBypas),
            _ => None,
        }
    }
}

impl NccReporter {
    pub fn new(config: NccConfig) -> Self {
        let client = Client::builder()
            .timeout(std::time::Duration::from_secs(30))
            .pool_max_idle_per_host(10)
            .build()
            .expect("Failed to create HTTP client");

        Self {
            client,
            config,
            token_cache: Arc::new(RwLock::new(None)),
        }
    }

    /// Get OAuth2 access token (with caching)
    async fn get_access_token(&self) -> Result<String> {
        // Check cache first
        {
            let cache = self.token_cache.read().await;
            if let Some(ref tc) = *cache {
                if tc.expires_at > Utc::now() + chrono::Duration::seconds(60) {
                    return Ok(tc.access_token.clone());
                }
            }
        }

        // Fetch new token
        let response = self
            .client
            .post(format!("{}/oauth/token", self.config.atrs_base_url))
            .form(&OAuthRequest {
                grant_type: "client_credentials".to_string(),
                client_id: self.config.client_id.clone(),
                client_secret: self.config.client_secret.clone(),
                scope: "fraud:report".to_string(),
            })
            .send()
            .await
            .context("Failed to request OAuth token")?;

        if !response.status().is_success() {
            let status = response.status();
            let body = response.text().await.unwrap_or_default();
            anyhow::bail!("OAuth token request failed: {} - {}", status, body);
        }

        let oauth: OAuthResponse = response
            .json()
            .await
            .context("Failed to parse OAuth response")?;

        // Cache the token
        {
            let mut cache = self.token_cache.write().await;
            *cache = Some(TokenCache {
                access_token: oauth.access_token.clone(),
                expires_at: Utc::now() + chrono::Duration::seconds(oauth.expires_in),
            });
        }

        Ok(oauth.access_token)
    }

    /// Report fraud event to NCC ATRS API
    pub async fn report_fraud(&self, alert: &FraudAlert) -> Result<NccReportResponse> {
        if !self.config.enabled {
            tracing::debug!("NCC reporting disabled, skipping");
            return Ok(NccReportResponse {
                report_id: "disabled".to_string(),
                status: "skipped".to_string(),
                message: Some("NCC reporting is disabled".to_string()),
            });
        }

        let token = self.get_access_token().await?;

        let report = NccFraudReport {
            icl_license: self.config.icl_license.clone(),
            event_type: alert.fraud_type.clone(),
            calling_number: alert.caller_id.clone(),
            called_number: alert.called_number.clone(),
            ingress_ip: alert.source_ip.clone(),
            egress_carrier: None,
            timestamp_wat: alert.timestamp.format("%Y-%m-%dT%H:%M:%SZ").to_string(),
            fraud_confidence: alert.confidence,
            detection_method: "ACM_ENGINE_V2".to_string(),
            recommended_action: alert.action.clone(),
            additional_data: serde_json::json!({
                "severity": alert.severity,
                "details": alert.details,
                "call_id": alert.call_id
            }),
        };

        tracing::info!(
            event_type = %report.event_type,
            calling = %report.calling_number,
            called = %report.called_number,
            "Reporting fraud to NCC ATRS"
        );

        let response = self
            .client
            .post(format!("{}/fraud/report", self.config.atrs_base_url))
            .bearer_auth(&token)
            .json(&report)
            .send()
            .await
            .context("Failed to send fraud report to NCC")?;

        if !response.status().is_success() {
            let status = response.status();
            let body = response.text().await.unwrap_or_default();
            
            // Log but don't fail - NCC API issues shouldn't block detection
            tracing::error!(
                status = %status,
                body = %body,
                "NCC ATRS API returned error"
            );
            
            return Ok(NccReportResponse {
                report_id: "error".to_string(),
                status: "failed".to_string(),
                message: Some(format!("{}: {}", status, body)),
            });
        }

        let ncc_response: NccReportResponse = response
            .json()
            .await
            .context("Failed to parse NCC response")?;

        tracing::info!(
            report_id = %ncc_response.report_id,
            status = %ncc_response.status,
            "Fraud report submitted to NCC"
        );

        Ok(ncc_response)
    }

    /// Fetch NCC blacklist updates
    pub async fn fetch_blacklist(&self) -> Result<Vec<BlacklistEntry>> {
        if !self.config.enabled {
            return Ok(vec![]);
        }

        let token = self.get_access_token().await?;

        let response = self
            .client
            .get(format!("{}/blacklist/carriers", self.config.atrs_base_url))
            .bearer_auth(&token)
            .send()
            .await
            .context("Failed to fetch NCC blacklist")?;

        if !response.status().is_success() {
            let status = response.status();
            let body = response.text().await.unwrap_or_default();
            anyhow::bail!("Failed to fetch blacklist: {} - {}", status, body);
        }

        let entries: Vec<BlacklistEntry> = response
            .json()
            .await
            .context("Failed to parse blacklist response")?;

        tracing::info!(
            count = entries.len(),
            "Fetched NCC blacklist entries"
        );

        Ok(entries)
    }

    /// Check if NCC reporting is enabled
    pub fn is_enabled(&self) -> bool {
        self.config.enabled
    }
}

#[derive(Deserialize, Debug, Clone)]
pub struct BlacklistEntry {
    pub ip_address: String,
    pub carrier_name: Option<String>,
    pub reason: String,
    pub added_at: DateTime<Utc>,
    pub expires_at: Option<DateTime<Utc>>,
}

/// Daily CDR batch reporter for SFTP upload
pub struct DailyBatchReporter {
    config: NccConfig,
}

impl DailyBatchReporter {
    pub fn new(config: NccConfig) -> Self {
        Self { config }
    }

    /// Generate daily CDR report CSV
    pub async fn generate_daily_report(
        &self,
        cdrs: Vec<DailyCdrRecord>,
        report_date: chrono::NaiveDate,
    ) -> Result<Vec<u8>> {
        let mut wtr = csv::Writer::from_writer(vec![]);

        // Write header
        wtr.write_record(&[
            "icl_license",
            "call_id",
            "timestamp_wat",
            "calling_number",
            "called_number",
            "duration_seconds",
            "ingress_ip",
            "egress_ip",
            "fraud_detected",
            "fraud_type",
            "action_taken",
        ])?;

        for cdr in cdrs {
            wtr.write_record(&[
                &self.config.icl_license,
                &cdr.call_id,
                &cdr.timestamp.format("%Y-%m-%dT%H:%M:%SZ").to_string(),
                &cdr.calling_number,
                &cdr.called_number,
                &cdr.duration_seconds.to_string(),
                &cdr.ingress_ip,
                &cdr.egress_ip.unwrap_or_default(),
                &cdr.fraud_detected.to_string(),
                &cdr.fraud_type.unwrap_or_default(),
                &cdr.action_taken,
            ])?;
        }

        let csv_data = wtr.into_inner()?;

        // Compress with gzip
        use flate2::write::GzEncoder;
        use flate2::Compression;
        use std::io::Write;

        let mut encoder = GzEncoder::new(Vec::new(), Compression::default());
        encoder.write_all(&csv_data)?;
        let compressed = encoder.finish()?;

        tracing::info!(
            date = %report_date,
            uncompressed_size = csv_data.len(),
            compressed_size = compressed.len(),
            "Generated daily CDR report"
        );

        Ok(compressed)
    }

    /// Get the expected filename for daily report
    pub fn get_report_filename(&self, report_date: chrono::NaiveDate) -> String {
        format!(
            "CDR_{}_{}.csv.gz",
            self.config.icl_license.replace("/", "_"),
            report_date.format("%Y%m%d")
        )
    }
}

#[derive(Debug, Clone)]
pub struct DailyCdrRecord {
    pub call_id: String,
    pub timestamp: DateTime<Utc>,
    pub calling_number: String,
    pub called_number: String,
    pub duration_seconds: u32,
    pub ingress_ip: String,
    pub egress_ip: Option<String>,
    pub fraud_detected: bool,
    pub fraud_type: Option<String>,
    pub action_taken: String,
}

/// Metrics for NCC compliance monitoring
#[derive(Default)]
pub struct NccMetrics {
    pub reports_sent: std::sync::atomic::AtomicU64,
    pub reports_failed: std::sync::atomic::AtomicU64,
    pub daily_uploads: std::sync::atomic::AtomicU64,
    pub last_report_timestamp: std::sync::atomic::AtomicI64,
}

impl NccMetrics {
    pub fn record_report(&self, success: bool) {
        use std::sync::atomic::Ordering;
        
        if success {
            self.reports_sent.fetch_add(1, Ordering::Relaxed);
        } else {
            self.reports_failed.fetch_add(1, Ordering::Relaxed);
        }
        
        self.last_report_timestamp.store(
            Utc::now().timestamp(),
            Ordering::Relaxed,
        );
    }

    pub fn record_daily_upload(&self) {
        use std::sync::atomic::Ordering;
        self.daily_uploads.fetch_add(1, Ordering::Relaxed);
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_ncc_event_types() {
        assert_eq!(NccEventType::CliMask.as_str(), "CLI_MASK");
        assert_eq!(NccEventType::SimBox.as_str(), "SIM_BOX");
        assert_eq!(NccEventType::from_str("CLI_MASK"), Some(NccEventType::CliMask));
        assert_eq!(NccEventType::from_str("INVALID"), None);
    }

    #[test]
    fn test_report_filename() {
        let config = NccConfig {
            icl_license: "ICL/REG/2026/001".to_string(),
            ..Default::default()
        };
        let reporter = DailyBatchReporter::new(config);
        let filename = reporter.get_report_filename(
            chrono::NaiveDate::from_ymd_opt(2026, 1, 15).unwrap()
        );
        assert_eq!(filename, "CDR_ICL_REG_2026_001_20260115.csv.gz");
    }
}
