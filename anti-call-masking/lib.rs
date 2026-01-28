//! # ACM Detection Engine
//!
//! High-performance Anti-Call Masking Detection Engine for Nigerian Interconnect Clearinghouses.
//!
//! ## Architecture
//!
//! The detection engine operates in three layers:
//! 1. **L1 Cache**: In-memory sliding window for hot data (sub-microsecond)
//! 2. **L2 Cache**: DragonflyDB for regional data sharing (sub-millisecond)
//! 3. **L3 Store**: YugabyteDB for persistence and MNP data (milliseconds)
//!
//! ## Detection Algorithms
//!
//! - **CLI vs Source IP**: Validates that international trunks don't send local +234 numbers
//! - **SIM-Box Detection**: Behavioral analysis (CPM, ACD, unique destinations)
//! - **Header Integrity**: P-Asserted-Identity and From header consistency

pub mod config;
pub mod detection;
pub mod models;
pub mod handlers;
pub mod cache;
pub mod db;
pub mod reporting;
pub mod metrics;
pub mod questdb;  // QuestDB time-series analytics (replaces kdb+)

use std::sync::Arc;
use tokio::sync::RwLock;

pub use config::AppConfig;
pub use detection::{DetectionEngine, DetectionResult, FraudType};
pub use models::{CallEvent, MnpRecord, GatewayProfile, FraudAlert};
pub use cache::CacheManager;
pub use db::{YugabyteClient, ClickHouseClient};
pub use reporting::NccReporter;
pub use metrics::Metrics;

/// Application state shared across all handlers
#[derive(Clone)]
pub struct AppState {
    pub config: Arc<AppConfig>,
    pub detection_engine: Arc<DetectionEngine>,
    pub cache: Arc<CacheManager>,
    pub yugabyte: Arc<YugabyteClient>,
    pub clickhouse: Arc<ClickHouseClient>,
    pub ncc_reporter: Arc<NccReporter>,
    pub metrics: Arc<Metrics>,
    /// In-memory sliding window for ultra-fast lookups
    pub sliding_window: Arc<RwLock<SlidingWindow>>,
}

/// In-memory sliding window for behavioral analysis
/// Uses lock-free data structures for maximum performance
pub struct SlidingWindow {
    /// Map of A-number -> recent call timestamps (for CPM calculation)
    pub call_timestamps: dashmap::DashMap<String, Vec<chrono::DateTime<chrono::Utc>>>,
    /// Map of A-number -> B-number set (for unique destination tracking)
    pub unique_destinations: dashmap::DashMap<String, std::collections::HashSet<String>>,
    /// Map of A-number -> total call duration in window (for ACD calculation)
    pub call_durations: dashmap::DashMap<String, (u32, u64)>, // (count, total_seconds)
    /// Window size in seconds
    pub window_size_secs: u64,
}

impl SlidingWindow {
    pub fn new(window_size_secs: u64) -> Self {
        Self {
            call_timestamps: dashmap::DashMap::with_capacity(100_000),
            unique_destinations: dashmap::DashMap::with_capacity(100_000),
            call_durations: dashmap::DashMap::with_capacity(100_000),
            window_size_secs,
        }
    }

    /// Record a new call event and return CPM for the A-number
    pub fn record_call(&self, a_number: &str, b_number: &str) -> u32 {
        let now = chrono::Utc::now();
        let cutoff = now - chrono::Duration::seconds(60); // 1-minute window for CPM

        // Update timestamps and calculate CPM
        let cpm = {
            let mut entry = self.call_timestamps.entry(a_number.to_string()).or_default();
            entry.retain(|ts| *ts > cutoff);
            entry.push(now);
            entry.len() as u32
        };

        // Track unique destinations
        {
            let mut entry = self.unique_destinations.entry(a_number.to_string()).or_default();
            entry.insert(b_number.to_string());
        }

        cpm
    }

    /// Record call duration for ACD calculation
    pub fn record_duration(&self, a_number: &str, duration_secs: u64) {
        let mut entry = self.call_durations.entry(a_number.to_string()).or_default();
        entry.0 += 1;
        entry.1 += duration_secs;
    }

    /// Get Average Call Duration for an A-number
    pub fn get_acd(&self, a_number: &str) -> Option<f64> {
        self.call_durations.get(a_number).map(|entry| {
            if entry.0 > 0 {
                entry.1 as f64 / entry.0 as f64
            } else {
                0.0
            }
        })
    }

    /// Get unique destination count for an A-number
    pub fn get_unique_destinations(&self, a_number: &str) -> usize {
        self.unique_destinations
            .get(a_number)
            .map(|entry| entry.len())
            .unwrap_or(0)
    }

    /// Periodic cleanup of old data
    pub fn cleanup(&self) {
        let cutoff = chrono::Utc::now() - chrono::Duration::seconds(self.window_size_secs as i64);
        
        self.call_timestamps.retain(|_, timestamps| {
            timestamps.retain(|ts| *ts > cutoff);
            !timestamps.is_empty()
        });
    }
}

/// Nigerian MNO Routing Numbers (2026)
pub mod routing_numbers {
    pub const MTN: &str = "D013";
    pub const AIRTEL: &str = "D018";
    pub const GLO: &str = "D015";
    pub const NINE_MOBILE: &str = "D019";
}

/// Nigerian mobile prefixes by operator
pub mod nigerian_prefixes {
    pub const MTN: &[&str] = &[
        "+234703", "+234706", "+234803", "+234806",
        "+234810", "+234813", "+234814", "+234816",
        "+234903", "+234906", "+234913", "+234916",
    ];
    
    pub const AIRTEL: &[&str] = &[
        "+234701", "+234708", "+234802", "+234808",
        "+234812", "+234901", "+234902", "+234904",
        "+234907", "+234912",
    ];
    
    pub const GLO: &[&str] = &[
        "+234705", "+234805", "+234807", "+234811",
        "+234815", "+234905", "+234915",
    ];
    
    pub const NINE_MOBILE: &[&str] = &[
        "+234809", "+234817", "+234818", "+234908", "+234909",
    ];
    
    /// Check if a number is a Nigerian mobile number
    pub fn is_nigerian_mobile(number: &str) -> bool {
        let normalized = if number.starts_with("0") {
            format!("+234{}", &number[1..])
        } else {
            number.to_string()
        };
        
        MTN.iter()
            .chain(AIRTEL.iter())
            .chain(GLO.iter())
            .chain(NINE_MOBILE.iter())
            .any(|prefix| normalized.starts_with(prefix))
    }
    
    /// Get the default operator for a prefix (before MNP lookup)
    pub fn get_default_operator(number: &str) -> Option<&'static str> {
        let normalized = if number.starts_with("0") {
            format!("+234{}", &number[1..])
        } else {
            number.to_string()
        };
        
        if MTN.iter().any(|p| normalized.starts_with(p)) {
            Some("MTN")
        } else if AIRTEL.iter().any(|p| normalized.starts_with(p)) {
            Some("Airtel")
        } else if GLO.iter().any(|p| normalized.starts_with(p)) {
            Some("Glo")
        } else if NINE_MOBILE.iter().any(|p| normalized.starts_with(p)) {
            Some("9mobile")
        } else {
            None
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_nigerian_prefix_detection() {
        assert!(nigerian_prefixes::is_nigerian_mobile("+2348031234567"));
        assert!(nigerian_prefixes::is_nigerian_mobile("08031234567"));
        assert!(!nigerian_prefixes::is_nigerian_mobile("+14151234567"));
    }

    #[test]
    fn test_operator_detection() {
        assert_eq!(
            nigerian_prefixes::get_default_operator("+2348031234567"),
            Some("MTN")
        );
        assert_eq!(
            nigerian_prefixes::get_default_operator("+2348121234567"),
            Some("Airtel")
        );
    }

    #[test]
    fn test_sliding_window_cpm() {
        let window = SlidingWindow::new(300);
        
        // Record 10 calls from same A-number
        for _ in 0..10 {
            window.record_call("+2348031234567", "+2348051234567");
        }
        
        let cpm = window.record_call("+2348031234567", "+2348051234568");
        assert_eq!(cpm, 11);
    }
}
