//! ThreatLevel - Real-time threat assessment for a B-number
//!
//! This is a read model (CQRS query side) computed from call data.

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

use crate::domain::value_objects::{MSISDN, Severity};

/// Real-time threat assessment for a target number
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ThreatLevel {
    /// Target B-number
    b_number: MSISDN,
    /// Current threat level
    level: Severity,
    /// Number of distinct callers in window
    distinct_callers: usize,
    /// Number of distinct source IPs
    distinct_ips: usize,
    /// Total call count in window
    call_count: usize,
    /// Last activity timestamp
    last_seen: DateTime<Utc>,
    /// Window start time
    window_start: DateTime<Utc>,
    /// Analysis timestamp
    analyzed_at: DateTime<Utc>,
}

impl ThreatLevel {
    /// Creates a new ThreatLevel assessment
    pub fn assess(
        b_number: MSISDN,
        distinct_callers: usize,
        distinct_ips: usize,
        call_count: usize,
        last_seen: DateTime<Utc>,
        window_start: DateTime<Utc>,
        threshold: usize,
    ) -> Self {
        let level = Self::compute_level(distinct_callers, threshold);

        Self {
            b_number,
            level,
            distinct_callers,
            distinct_ips,
            call_count,
            last_seen,
            window_start,
            analyzed_at: Utc::now(),
        }
    }

    /// Computes threat level from distinct caller count
    fn compute_level(distinct_callers: usize, threshold: usize) -> Severity {
        if threshold == 0 {
            return Severity::Info;
        }

        let ratio = distinct_callers as f64 / threshold as f64;

        match ratio {
            r if r >= 1.0 => Severity::Critical,
            r if r >= 0.8 => Severity::High,
            r if r >= 0.6 => Severity::Medium,
            r if r >= 0.4 => Severity::Low,
            _ => Severity::Info,
        }
    }

    // === Getters ===

    pub fn b_number(&self) -> &MSISDN {
        &self.b_number
    }

    pub fn level(&self) -> Severity {
        self.level
    }

    pub fn distinct_callers(&self) -> usize {
        self.distinct_callers
    }

    pub fn distinct_ips(&self) -> usize {
        self.distinct_ips
    }

    pub fn call_count(&self) -> usize {
        self.call_count
    }

    pub fn last_seen(&self) -> DateTime<Utc> {
        self.last_seen
    }

    /// Checks if threat level is elevated (Medium or higher)
    pub fn is_elevated(&self) -> bool {
        matches!(self.level, Severity::Medium | Severity::High | Severity::Critical)
    }

    /// Checks if threat level requires immediate action
    pub fn requires_action(&self) -> bool {
        matches!(self.level, Severity::High | Severity::Critical)
    }

    /// Checks if threshold is exceeded (Critical level)
    pub fn threshold_exceeded(&self) -> bool {
        self.level == Severity::Critical
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::Duration;

    #[test]
    fn test_threat_level_critical() {
        let b_number = MSISDN::new("+2348098765432").unwrap();
        let now = Utc::now();

        let threat = ThreatLevel::assess(
            b_number,
            7,  // distinct callers
            2,  // distinct IPs
            10, // total calls
            now,
            now - Duration::seconds(5),
            5,  // threshold
        );

        assert_eq!(threat.level(), Severity::Critical);
        assert!(threat.threshold_exceeded());
        assert!(threat.requires_action());
    }

    #[test]
    fn test_threat_level_high() {
        let b_number = MSISDN::new("+2348098765432").unwrap();
        let now = Utc::now();

        let threat = ThreatLevel::assess(
            b_number,
            4,  // 80% of threshold
            1,
            5,
            now,
            now - Duration::seconds(5),
            5,
        );

        assert_eq!(threat.level(), Severity::High);
        assert!(!threat.threshold_exceeded());
        assert!(threat.requires_action());
    }

    #[test]
    fn test_threat_level_low() {
        let b_number = MSISDN::new("+2348098765432").unwrap();
        let now = Utc::now();

        let threat = ThreatLevel::assess(
            b_number,
            2,  // 40% of threshold
            1,
            2,
            now,
            now - Duration::seconds(5),
            5,
        );

        assert_eq!(threat.level(), Severity::Low);
        assert!(!threat.is_elevated());
    }

    #[test]
    fn test_threat_level_info() {
        let b_number = MSISDN::new("+2348098765432").unwrap();
        let now = Utc::now();

        let threat = ThreatLevel::assess(
            b_number,
            1,  // Single caller - normal
            1,
            1,
            now,
            now - Duration::seconds(5),
            5,
        );

        assert_eq!(threat.level(), Severity::Info);
    }
}
