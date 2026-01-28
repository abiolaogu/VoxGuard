//! Value Objects - Immutable domain primitives with validation
//!
//! These types encapsulate validation rules and are used throughout the domain.

use serde::{Deserialize, Serialize};
use std::fmt;
use std::net::IpAddr;
use std::str::FromStr;
use uuid::Uuid;
use validator::Validate;

use super::errors::DomainError;

/// Unique identifier for a call within the detection system
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct CallId(String);

impl CallId {
    /// Creates a new CallId from a string, validating format
    pub fn new(id: impl Into<String>) -> Result<Self, DomainError> {
        let id = id.into();
        if id.is_empty() {
            return Err(DomainError::InvalidCallId("Call ID cannot be empty".into()));
        }
        if id.len() > 256 {
            return Err(DomainError::InvalidCallId("Call ID too long".into()));
        }
        Ok(Self(id))
    }

    /// Generates a new unique CallId
    pub fn generate() -> Self {
        Self(Uuid::new_v4().to_string())
    }

    pub fn as_str(&self) -> &str {
        &self.0
    }
}

impl fmt::Display for CallId {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.0)
    }
}

/// Mobile Subscriber Integrated Services Digital Network Number (phone number)
/// Validates Nigerian +234 format and international formats
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct MSISDN(String);

impl MSISDN {
    /// Creates a new MSISDN with validation
    pub fn new(number: impl Into<String>) -> Result<Self, DomainError> {
        let number = Self::normalize(number.into());
        
        if number.is_empty() {
            return Err(DomainError::InvalidMSISDN("MSISDN cannot be empty".into()));
        }
        
        // Must start with + for international format
        if !number.starts_with('+') {
            return Err(DomainError::InvalidMSISDN(
                "MSISDN must be in international format (+...)".into(),
            ));
        }
        
        // Must be digits only after +
        if !number[1..].chars().all(|c| c.is_ascii_digit()) {
            return Err(DomainError::InvalidMSISDN(
                "MSISDN must contain only digits after country code".into(),
            ));
        }
        
        // Minimum length check (country code + subscriber number)
        if number.len() < 8 {
            return Err(DomainError::InvalidMSISDN("MSISDN too short".into()));
        }
        
        if number.len() > 16 {
            return Err(DomainError::InvalidMSISDN("MSISDN too long".into()));
        }
        
        Ok(Self(number))
    }

    /// Normalizes phone number to E.164 format
    fn normalize(mut number: String) -> String {
        // Remove common formatting characters
        number.retain(|c| !matches!(c, ' ' | '-' | '(' | ')' | '.'));
        
        // Convert Nigerian local format to international
        if number.starts_with("234") && !number.starts_with('+') {
            number = format!("+{}", number);
        } else if number.starts_with("0") && number.len() == 11 {
            // Nigerian local format 0XXXXXXXXXX -> +234XXXXXXXXXX
            number = format!("+234{}", &number[1..]);
        }
        
        number
    }

    /// Checks if this is a Nigerian number
    pub fn is_nigerian(&self) -> bool {
        self.0.starts_with("+234")
    }

    /// Returns the country code (without +)
    pub fn country_code(&self) -> &str {
        if self.0.starts_with("+234") {
            "234"
        } else if self.0.len() > 3 {
            &self.0[1..4] // Approximate for other countries
        } else {
            ""
        }
    }

    /// Returns the national number (without country code)
    pub fn national_number(&self) -> &str {
        if self.0.starts_with("+234") {
            &self.0[4..]
        } else {
            &self.0[1..]
        }
    }

    /// Get prefix for MNO identification (first 7 digits for Nigeria)
    pub fn prefix(&self, len: usize) -> &str {
        let national = self.national_number();
        if national.len() >= len {
            &national[..len]
        } else {
            national
        }
    }

    pub fn as_str(&self) -> &str {
        &self.0
    }
}

impl fmt::Display for MSISDN {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.0)
    }
}

/// IP Address value object with validation
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct IPAddress(IpAddr);

impl IPAddress {
    /// Creates a new IPAddress from string
    pub fn new(ip: impl AsRef<str>) -> Result<Self, DomainError> {
        let addr = IpAddr::from_str(ip.as_ref())
            .map_err(|_| DomainError::InvalidIPAddress(format!("Invalid IP: {}", ip.as_ref())))?;
        Ok(Self(addr))
    }

    /// Returns true if this is a private/internal IP
    pub fn is_private(&self) -> bool {
        match self.0 {
            IpAddr::V4(ip) => ip.is_private() || ip.is_loopback(),
            IpAddr::V6(ip) => ip.is_loopback(),
        }
    }

    /// Returns true if this is an international gateway IP (non-Nigerian)
    /// This is a heuristic - in production would use GeoIP
    pub fn is_likely_international(&self) -> bool {
        // Placeholder - would integrate with GeoIP service
        !self.is_private()
    }

    pub fn inner(&self) -> &IpAddr {
        &self.0
    }
}

impl fmt::Display for IPAddress {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.0)
    }
}

/// Fraud confidence score (0.0 - 1.0)
#[derive(Debug, Clone, Copy, PartialEq, Serialize, Deserialize)]
pub struct FraudScore(f64);

impl FraudScore {
    /// Creates a new FraudScore, clamping to valid range
    pub fn new(score: f64) -> Self {
        Self(score.clamp(0.0, 1.0))
    }

    /// Creates a score from a percentage (0-100)
    pub fn from_percentage(pct: f64) -> Self {
        Self::new(pct / 100.0)
    }

    /// Returns the score as a percentage
    pub fn as_percentage(&self) -> f64 {
        self.0 * 100.0
    }

    /// Determines severity level from score
    pub fn severity(&self) -> Severity {
        match self.0 {
            s if s >= 0.9 => Severity::Critical,
            s if s >= 0.7 => Severity::High,
            s if s >= 0.5 => Severity::Medium,
            s if s >= 0.3 => Severity::Low,
            _ => Severity::Info,
        }
    }

    /// Checks if score exceeds threshold for automatic blocking
    pub fn exceeds_block_threshold(&self) -> bool {
        self.0 >= 0.85
    }

    pub fn value(&self) -> f64 {
        self.0
    }
}

impl Default for FraudScore {
    fn default() -> Self {
        Self(0.0)
    }
}

/// Alert/fraud severity level
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub enum Severity {
    Info = 1,
    Low = 2,
    Medium = 3,
    High = 4,
    Critical = 5,
}

impl Severity {
    pub fn as_int(&self) -> i32 {
        *self as i32
    }
}

/// Fraud detection event types
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "SCREAMING_SNAKE_CASE")]
pub enum FraudType {
    /// CLI masking - international call with local CLI
    CliMasking,
    /// SIM box - multiple calls from same source
    SimBox,
    /// Call refiling - international to local bypass
    Refiling,
    /// STIR/SHAKEN attestation failure
    StirShakenFail,
    /// Abnormal call pattern
    AnomalousPattern,
    /// Multiple distinct callers to same number
    MaskingAttack,
}

impl fmt::Display for FraudType {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::CliMasking => write!(f, "CLI_MASKING"),
            Self::SimBox => write!(f, "SIM_BOX"),
            Self::Refiling => write!(f, "REFILING"),
            Self::StirShakenFail => write!(f, "STIR_SHAKEN_FAIL"),
            Self::AnomalousPattern => write!(f, "ANOMALOUS_PATTERN"),
            Self::MaskingAttack => write!(f, "MASKING_ATTACK"),
        }
    }
}

/// Call status within the detection window
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum CallStatus {
    /// Call is ringing
    Ringing,
    /// Call is active/connected
    Active,
    /// Call completed normally
    Completed,
    /// Call failed/rejected
    Failed,
    /// Call blocked by detection
    Blocked,
}

/// Time window for detection analysis
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct DetectionWindow {
    seconds: u32,
}

impl DetectionWindow {
    pub fn new(seconds: u32) -> Result<Self, DomainError> {
        if seconds == 0 {
            return Err(DomainError::InvalidConfiguration(
                "Detection window must be positive".into(),
            ));
        }
        if seconds > 300 {
            return Err(DomainError::InvalidConfiguration(
                "Detection window cannot exceed 300 seconds".into(),
            ));
        }
        Ok(Self { seconds })
    }

    pub fn default_window() -> Self {
        Self { seconds: 5 }
    }

    pub fn seconds(&self) -> u32 {
        self.seconds
    }
}

impl Default for DetectionWindow {
    fn default() -> Self {
        Self::default_window()
    }
}

/// Threshold for triggering fraud alerts
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct DetectionThreshold {
    distinct_callers: usize,
}

impl DetectionThreshold {
    pub fn new(distinct_callers: usize) -> Result<Self, DomainError> {
        if distinct_callers == 0 {
            return Err(DomainError::InvalidConfiguration(
                "Threshold must be positive".into(),
            ));
        }
        if distinct_callers > 100 {
            return Err(DomainError::InvalidConfiguration(
                "Threshold too high (max 100)".into(),
            ));
        }
        Ok(Self { distinct_callers })
    }

    pub fn default_threshold() -> Self {
        Self { distinct_callers: 5 }
    }

    pub fn distinct_callers(&self) -> usize {
        self.distinct_callers
    }
}

impl Default for DetectionThreshold {
    fn default() -> Self {
        Self::default_threshold()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    mod call_id_tests {
        use super::*;

        #[test]
        fn test_valid_call_id() {
            let id = CallId::new("call-123").unwrap();
            assert_eq!(id.as_str(), "call-123");
        }

        #[test]
        fn test_empty_call_id_fails() {
            assert!(CallId::new("").is_err());
        }

        #[test]
        fn test_generate_unique() {
            let id1 = CallId::generate();
            let id2 = CallId::generate();
            assert_ne!(id1, id2);
        }
    }

    mod msisdn_tests {
        use super::*;

        #[test]
        fn test_valid_nigerian_number() {
            let msisdn = MSISDN::new("+2348012345678").unwrap();
            assert!(msisdn.is_nigerian());
            assert_eq!(msisdn.country_code(), "234");
        }

        #[test]
        fn test_normalizes_local_format() {
            let msisdn = MSISDN::new("08012345678").unwrap();
            assert_eq!(msisdn.as_str(), "+2348012345678");
        }

        #[test]
        fn test_normalizes_without_plus() {
            let msisdn = MSISDN::new("2348012345678").unwrap();
            assert_eq!(msisdn.as_str(), "+2348012345678");
        }

        #[test]
        fn test_invalid_format_fails() {
            assert!(MSISDN::new("invalid").is_err());
            assert!(MSISDN::new("").is_err());
        }

        #[test]
        fn test_prefix_extraction() {
            let msisdn = MSISDN::new("+2348012345678").unwrap();
            assert_eq!(msisdn.prefix(4), "8012");
        }
    }

    mod ip_address_tests {
        use super::*;

        #[test]
        fn test_valid_ipv4() {
            let ip = IPAddress::new("192.168.1.1").unwrap();
            assert!(ip.is_private());
        }

        #[test]
        fn test_valid_ipv6() {
            let ip = IPAddress::new("::1").unwrap();
            assert!(ip.is_private());
        }

        #[test]
        fn test_invalid_ip_fails() {
            assert!(IPAddress::new("not-an-ip").is_err());
        }
    }

    mod fraud_score_tests {
        use super::*;

        #[test]
        fn test_score_clamping() {
            let score = FraudScore::new(1.5);
            assert_eq!(score.value(), 1.0);

            let score = FraudScore::new(-0.5);
            assert_eq!(score.value(), 0.0);
        }

        #[test]
        fn test_severity_levels() {
            assert_eq!(FraudScore::new(0.95).severity(), Severity::Critical);
            assert_eq!(FraudScore::new(0.75).severity(), Severity::High);
            assert_eq!(FraudScore::new(0.55).severity(), Severity::Medium);
            assert_eq!(FraudScore::new(0.35).severity(), Severity::Low);
            assert_eq!(FraudScore::new(0.15).severity(), Severity::Info);
        }

        #[test]
        fn test_block_threshold() {
            assert!(FraudScore::new(0.9).exceeds_block_threshold());
            assert!(!FraudScore::new(0.5).exceeds_block_threshold());
        }
    }

    mod detection_window_tests {
        use super::*;

        #[test]
        fn test_valid_window() {
            let window = DetectionWindow::new(10).unwrap();
            assert_eq!(window.seconds(), 10);
        }

        #[test]
        fn test_zero_window_fails() {
            assert!(DetectionWindow::new(0).is_err());
        }

        #[test]
        fn test_excessive_window_fails() {
            assert!(DetectionWindow::new(500).is_err());
        }
    }
}
