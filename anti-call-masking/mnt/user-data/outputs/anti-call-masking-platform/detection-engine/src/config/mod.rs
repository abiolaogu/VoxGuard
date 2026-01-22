//! Configuration management for the ACM Detection Engine.

use config::{Config, ConfigError, Environment, File};
use serde::Deserialize;
use std::sync::Arc;

/// Application configuration
#[derive(Debug, Clone, Deserialize)]
pub struct AppConfig {
    /// Server listen address
    #[serde(default = "default_listen_addr")]
    pub listen_addr: String,

    /// DragonflyDB connection URL
    #[serde(default = "default_dragonfly_url")]
    pub dragonfly_url: String,

    /// Fallback DragonflyDB URL (for failover)
    #[serde(default)]
    pub dragonfly_fallback_url: Option<String>,

    /// YugabyteDB connection URL
    #[serde(default = "default_yugabyte_url")]
    pub yugabyte_url: String,

    /// ClickHouse connection URL
    #[serde(default = "default_clickhouse_url")]
    pub clickhouse_url: String,

    /// Region identifier (Lagos, Abuja, Asaba)
    #[serde(default = "default_region")]
    pub region: String,

    /// Node identifier within the region
    #[serde(default = "default_node_id")]
    pub node_id: String,

    /// NCC configuration
    #[serde(default)]
    pub ncc: NccConfig,

    /// Detection thresholds
    #[serde(default)]
    pub thresholds: ThresholdsConfig,

    /// Cache configuration
    #[serde(default)]
    pub cache: CacheConfig,

    /// Logging configuration
    #[serde(default)]
    pub logging: LoggingConfig,
}

fn default_listen_addr() -> String {
    "0.0.0.0:8080".to_string()
}

fn default_dragonfly_url() -> String {
    "redis://127.0.0.1:6379".to_string()
}

fn default_yugabyte_url() -> String {
    "postgres://opensips:opensips@127.0.0.1:5433/acm".to_string()
}

fn default_clickhouse_url() -> String {
    "http://127.0.0.1:8123".to_string()
}

fn default_region() -> String {
    "lagos".to_string()
}

fn default_node_id() -> String {
    "node-1".to_string()
}

/// NCC (Nigerian Communications Commission) reporting configuration
#[derive(Debug, Clone, Deserialize, Default)]
pub struct NccConfig {
    /// ATRS API base URL
    #[serde(default = "default_ncc_api_url")]
    pub api_url: String,

    /// OAuth2 token URL
    #[serde(default = "default_ncc_auth_url")]
    pub auth_url: String,

    /// Client ID for OAuth2
    #[serde(default)]
    pub client_id: String,

    /// Client secret for OAuth2
    #[serde(default)]
    pub client_secret: String,

    /// ICL license number
    #[serde(default)]
    pub icl_license: String,

    /// SFTP host for daily uploads
    #[serde(default = "default_ncc_sftp_host")]
    pub sftp_host: String,

    /// SFTP username
    #[serde(default)]
    pub sftp_user: String,

    /// Path to SFTP private key
    #[serde(default)]
    pub sftp_key_path: String,

    /// SFTP remote directory
    #[serde(default = "default_ncc_sftp_dir")]
    pub sftp_remote_dir: String,

    /// Enable real-time reporting
    #[serde(default = "default_true")]
    pub realtime_enabled: bool,

    /// Enable daily batch reporting
    #[serde(default = "default_true")]
    pub batch_enabled: bool,

    /// Blacklist sync interval in seconds
    #[serde(default = "default_blacklist_sync_interval")]
    pub blacklist_sync_interval: u64,
}

fn default_ncc_api_url() -> String {
    "https://atrs-api.ncc.gov.ng/v1".to_string()
}

fn default_ncc_auth_url() -> String {
    "https://atrs-api.ncc.gov.ng/oauth2/token".to_string()
}

fn default_ncc_sftp_host() -> String {
    "sftp.ncc.gov.ng".to_string()
}

fn default_ncc_sftp_dir() -> String {
    "/reports/interconnect".to_string()
}

fn default_true() -> bool {
    true
}

fn default_blacklist_sync_interval() -> u64 {
    300 // 5 minutes
}

/// Detection thresholds configuration
#[derive(Debug, Clone, Deserialize)]
pub struct ThresholdsConfig {
    /// CPM warning threshold
    #[serde(default = "default_cpm_warning")]
    pub cpm_warning: u32,

    /// CPM critical threshold
    #[serde(default = "default_cpm_critical")]
    pub cpm_critical: u32,

    /// ACD warning threshold (seconds)
    #[serde(default = "default_acd_warning")]
    pub acd_warning: f64,

    /// ACD critical threshold (seconds)
    #[serde(default = "default_acd_critical")]
    pub acd_critical: f64,

    /// Concurrent calls warning
    #[serde(default = "default_concurrent_warning")]
    pub concurrent_warning: u32,

    /// Concurrent calls critical
    #[serde(default = "default_concurrent_critical")]
    pub concurrent_critical: u32,

    /// Unique destinations warning
    #[serde(default = "default_unique_dst_warning")]
    pub unique_dst_warning: u32,

    /// Unique destinations critical
    #[serde(default = "default_unique_dst_critical")]
    pub unique_dst_critical: u32,

    /// Sliding window size in seconds
    #[serde(default = "default_window_size")]
    pub window_size_secs: u64,
}

impl Default for ThresholdsConfig {
    fn default() -> Self {
        Self {
            cpm_warning: default_cpm_warning(),
            cpm_critical: default_cpm_critical(),
            acd_warning: default_acd_warning(),
            acd_critical: default_acd_critical(),
            concurrent_warning: default_concurrent_warning(),
            concurrent_critical: default_concurrent_critical(),
            unique_dst_warning: default_unique_dst_warning(),
            unique_dst_critical: default_unique_dst_critical(),
            window_size_secs: default_window_size(),
        }
    }
}

fn default_cpm_warning() -> u32 { 40 }
fn default_cpm_critical() -> u32 { 60 }
fn default_acd_warning() -> f64 { 10.0 }
fn default_acd_critical() -> f64 { 5.0 }
fn default_concurrent_warning() -> u32 { 20 }
fn default_concurrent_critical() -> u32 { 50 }
fn default_unique_dst_warning() -> u32 { 100 }
fn default_unique_dst_critical() -> u32 { 200 }
fn default_window_size() -> u64 { 300 }

/// Cache configuration
#[derive(Debug, Clone, Deserialize)]
pub struct CacheConfig {
    /// MNP cache TTL in seconds
    #[serde(default = "default_mnp_ttl")]
    pub mnp_ttl_secs: u64,

    /// Blacklist cache TTL in seconds
    #[serde(default = "default_blacklist_ttl")]
    pub blacklist_ttl_secs: u64,

    /// Gateway profile cache TTL in seconds
    #[serde(default = "default_gateway_ttl")]
    pub gateway_ttl_secs: u64,

    /// Caller metrics cache TTL in seconds
    #[serde(default = "default_metrics_ttl")]
    pub metrics_ttl_secs: u64,

    /// Maximum connections in pool
    #[serde(default = "default_pool_size")]
    pub pool_size: u32,

    /// Connection timeout in milliseconds
    #[serde(default = "default_connect_timeout")]
    pub connect_timeout_ms: u64,

    /// Query timeout in milliseconds
    #[serde(default = "default_query_timeout")]
    pub query_timeout_ms: u64,
}

impl Default for CacheConfig {
    fn default() -> Self {
        Self {
            mnp_ttl_secs: default_mnp_ttl(),
            blacklist_ttl_secs: default_blacklist_ttl(),
            gateway_ttl_secs: default_gateway_ttl(),
            metrics_ttl_secs: default_metrics_ttl(),
            pool_size: default_pool_size(),
            connect_timeout_ms: default_connect_timeout(),
            query_timeout_ms: default_query_timeout(),
        }
    }
}

fn default_mnp_ttl() -> u64 { 3600 }  // 1 hour
fn default_blacklist_ttl() -> u64 { 86400 }  // 24 hours
fn default_gateway_ttl() -> u64 { 300 }  // 5 minutes
fn default_metrics_ttl() -> u64 { 300 }  // 5 minutes
fn default_pool_size() -> u32 { 20 }
fn default_connect_timeout() -> u64 { 100 }  // 100ms
fn default_query_timeout() -> u64 { 100 }  // 100ms

/// Logging configuration
#[derive(Debug, Clone, Deserialize)]
pub struct LoggingConfig {
    /// Log level (trace, debug, info, warn, error)
    #[serde(default = "default_log_level")]
    pub level: String,

    /// JSON format output
    #[serde(default = "default_true")]
    pub json_format: bool,

    /// Include timestamps
    #[serde(default = "default_true")]
    pub timestamps: bool,
}

impl Default for LoggingConfig {
    fn default() -> Self {
        Self {
            level: default_log_level(),
            json_format: true,
            timestamps: true,
        }
    }
}

fn default_log_level() -> String {
    "info".to_string()
}

impl AppConfig {
    /// Load configuration from files and environment
    pub fn load() -> Result<Self, ConfigError> {
        let run_mode = std::env::var("RUN_MODE").unwrap_or_else(|_| "development".into());

        let config = Config::builder()
            // Start with defaults
            .set_default("listen_addr", default_listen_addr())?
            .set_default("region", default_region())?
            // Load base config file
            .add_source(File::with_name("config/default").required(false))
            // Load environment-specific config
            .add_source(File::with_name(&format!("config/{}", run_mode)).required(false))
            // Load local overrides
            .add_source(File::with_name("config/local").required(false))
            // Override with environment variables (ACM_ prefix)
            .add_source(
                Environment::with_prefix("ACM")
                    .separator("__")
                    .try_parsing(true),
            )
            .build()?;

        config.try_deserialize()
    }

    /// Create a new configuration with the specified values
    pub fn new(
        listen_addr: impl Into<String>,
        dragonfly_url: impl Into<String>,
        yugabyte_url: impl Into<String>,
        clickhouse_url: impl Into<String>,
    ) -> Self {
        Self {
            listen_addr: listen_addr.into(),
            dragonfly_url: dragonfly_url.into(),
            dragonfly_fallback_url: None,
            yugabyte_url: yugabyte_url.into(),
            clickhouse_url: clickhouse_url.into(),
            region: default_region(),
            node_id: default_node_id(),
            ncc: NccConfig::default(),
            thresholds: ThresholdsConfig::default(),
            cache: CacheConfig::default(),
            logging: LoggingConfig::default(),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_default_config() {
        let config = AppConfig::new(
            "0.0.0.0:8080",
            "redis://localhost:6379",
            "postgres://localhost/acm",
            "http://localhost:8123",
        );

        assert_eq!(config.listen_addr, "0.0.0.0:8080");
        assert_eq!(config.thresholds.cpm_critical, 60);
        assert_eq!(config.cache.mnp_ttl_secs, 3600);
    }

    #[test]
    fn test_ncc_defaults() {
        let ncc = NccConfig::default();
        
        assert!(ncc.realtime_enabled);
        assert!(ncc.batch_enabled);
        assert_eq!(ncc.blacklist_sync_interval, 300);
    }
}
