//! Data models for the Anti-Call Masking platform.
//!
//! This module contains all the core data structures used throughout the system.

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// A call event received from OpenSIPS or the voice switch
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CallEvent {
    /// Unique call identifier (SIP Call-ID)
    pub call_id: String,
    
    /// Calling party number (From header)
    pub caller_id: String,
    
    /// Called party number (R-URI)
    pub called_number: String,
    
    /// Source IP address of the call
    pub source_ip: String,
    
    /// Source port
    pub source_port: u16,
    
    /// Destination IP (next hop)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub destination_ip: Option<String>,
    
    /// SIP From header (raw)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub from_header: Option<String>,
    
    /// P-Asserted-Identity header
    #[serde(skip_serializing_if = "Option::is_none")]
    pub p_asserted_identity: Option<String>,
    
    /// Remote-Party-ID header
    #[serde(skip_serializing_if = "Option::is_none")]
    pub remote_party_id: Option<String>,
    
    /// SIP Privacy header value
    #[serde(skip_serializing_if = "Option::is_none")]
    pub privacy_header: Option<String>,
    
    /// STIR/SHAKEN Identity header
    #[serde(skip_serializing_if = "Option::is_none")]
    pub identity_header: Option<String>,
    
    /// Timestamp of the event
    pub timestamp: DateTime<Utc>,
    
    /// Call direction (inbound/outbound)
    #[serde(default)]
    pub direction: CallDirection,
    
    /// SIP method (INVITE, BYE, etc.)
    #[serde(default = "default_method")]
    pub method: String,
    
    /// Call duration in seconds (for CDR events)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub duration: Option<u32>,
    
    /// Disposition (answered, busy, no_answer, etc.)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub disposition: Option<String>,
    
    /// Additional metadata
    #[serde(default, skip_serializing_if = "std::collections::HashMap::is_empty")]
    pub metadata: std::collections::HashMap<String, String>,
}

fn default_method() -> String {
    "INVITE".to_string()
}

/// Call direction
#[derive(Debug, Clone, Copy, Default, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum CallDirection {
    #[default]
    Inbound,
    Outbound,
}

impl CallEvent {
    /// Create a new call event with minimal required fields
    pub fn new(
        call_id: impl Into<String>,
        caller_id: impl Into<String>,
        called_number: impl Into<String>,
        source_ip: impl Into<String>,
    ) -> Self {
        Self {
            call_id: call_id.into(),
            caller_id: caller_id.into(),
            called_number: called_number.into(),
            source_ip: source_ip.into(),
            source_port: 5060,
            destination_ip: None,
            from_header: None,
            p_asserted_identity: None,
            remote_party_id: None,
            privacy_header: None,
            identity_header: None,
            timestamp: Utc::now(),
            direction: CallDirection::Inbound,
            method: "INVITE".to_string(),
            duration: None,
            disposition: None,
            metadata: std::collections::HashMap::new(),
        }
    }
}

/// Mobile Number Portability record
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MnpRecord {
    /// The MSISDN in E.164 format
    pub msisdn: String,
    
    /// Whether the number has been ported
    pub is_ported: bool,
    
    /// Current hosting network (operator name)
    pub hosting_network: String,
    
    /// Hosting network ID (internal code)
    pub hosting_network_id: String,
    
    /// Routing number for interconnect
    pub routing_number: String,
    
    /// Original network (before porting, if applicable)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub original_network: Option<String>,
    
    /// Port date (if ported)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub port_date: Option<DateTime<Utc>>,
    
    /// Last updated timestamp
    pub last_updated: DateTime<Utc>,
}

/// Cached MNP data (simplified for cache storage)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CachedMnp {
    pub is_ported: bool,
    pub operator: String,
    pub routing_number: String,
}

/// Gateway profile for source IP classification
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GatewayProfile {
    /// Unique identifier
    pub id: Uuid,
    
    /// Gateway name
    pub name: String,
    
    /// IP address
    pub ip: String,
    
    /// Subnet mask (CIDR notation, e.g., 32 for single IP)
    pub mask: u8,
    
    /// Gateway group (10 = International, 1 = Trusted Local, 66 = Blacklisted)
    pub group_id: u8,
    
    /// Protocol (UDP, TCP, TLS)
    pub protocol: String,
    
    /// Port
    pub port: u16,
    
    /// Description/tag
    #[serde(skip_serializing_if = "Option::is_none")]
    pub tag: Option<String>,
    
    /// Is this gateway active?
    pub active: bool,
    
    /// Carrier/partner name
    #[serde(skip_serializing_if = "Option::is_none")]
    pub carrier: Option<String>,
    
    /// Expected CLI prefixes from this gateway
    #[serde(default)]
    pub allowed_prefixes: Vec<String>,
    
    /// Created timestamp
    pub created_at: DateTime<Utc>,
    
    /// Updated timestamp
    pub updated_at: DateTime<Utc>,
}

impl GatewayProfile {
    /// Check if this gateway is an international trunk
    pub fn is_international(&self) -> bool {
        self.group_id == 10
    }

    /// Check if this gateway is blacklisted
    pub fn is_blacklisted(&self) -> bool {
        self.group_id == 66
    }

    /// Check if this gateway is trusted local
    pub fn is_trusted_local(&self) -> bool {
        self.group_id == 1
    }
}

/// Fraud alert generated by the detection engine
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FraudAlert {
    /// Unique alert ID
    pub id: Uuid,
    
    /// Related call ID
    pub call_id: String,
    
    /// Fraud type detected
    pub fraud_type: String,
    
    /// Source IP that triggered the alert
    pub source_ip: String,
    
    /// CLI that triggered the alert
    pub cli: String,
    
    /// Called number
    pub called_number: String,
    
    /// Confidence score (0.0 - 1.0)
    pub confidence: f64,
    
    /// Severity level (1-5)
    pub severity: u8,
    
    /// Action taken
    pub action: String,
    
    /// Detailed reason
    pub reason: String,
    
    /// Alert timestamp
    pub timestamp: DateTime<Utc>,
    
    /// Whether this alert has been acknowledged
    pub acknowledged: bool,
    
    /// Who acknowledged it (if applicable)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub acknowledged_by: Option<String>,
    
    /// When it was acknowledged
    #[serde(skip_serializing_if = "Option::is_none")]
    pub acknowledged_at: Option<DateTime<Utc>>,
    
    /// Whether reported to NCC
    pub ncc_reported: bool,
    
    /// NCC report timestamp
    #[serde(skip_serializing_if = "Option::is_none")]
    pub ncc_reported_at: Option<DateTime<Utc>>,
    
    /// Additional metadata
    #[serde(default)]
    pub metadata: std::collections::HashMap<String, serde_json::Value>,
}

impl FraudAlert {
    pub fn new(
        call_id: impl Into<String>,
        fraud_type: impl Into<String>,
        source_ip: impl Into<String>,
        cli: impl Into<String>,
        called_number: impl Into<String>,
        confidence: f64,
        severity: u8,
        action: impl Into<String>,
        reason: impl Into<String>,
    ) -> Self {
        Self {
            id: Uuid::new_v4(),
            call_id: call_id.into(),
            fraud_type: fraud_type.into(),
            source_ip: source_ip.into(),
            cli: cli.into(),
            called_number: called_number.into(),
            confidence,
            severity,
            action: action.into(),
            reason: reason.into(),
            timestamp: Utc::now(),
            acknowledged: false,
            acknowledged_by: None,
            acknowledged_at: None,
            ncc_reported: false,
            ncc_reported_at: None,
            metadata: std::collections::HashMap::new(),
        }
    }
}

/// Caller metrics for behavioral analysis
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct CallerMetrics {
    /// Calls per minute
    pub cpm: Option<u32>,
    
    /// Average call duration in seconds
    pub acd: Option<f64>,
    
    /// Number of unique destinations
    pub unique_destinations: Option<usize>,
    
    /// Number of concurrent calls
    pub concurrent_calls: Option<u32>,
    
    /// Total calls in window
    pub total_calls: Option<u32>,
    
    /// Last seen timestamp
    pub last_seen: Option<DateTime<Utc>>,
}

/// Blacklist entry
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BlacklistEntry {
    /// Entry ID
    pub id: Uuid,
    
    /// IP address or CIDR range
    pub ip: String,
    
    /// Subnet mask
    pub mask: u8,
    
    /// Reason for blacklisting
    pub reason: String,
    
    /// Source of the blacklist (NCC, internal, etc.)
    pub source: String,
    
    /// When the entry was added
    pub added_at: DateTime<Utc>,
    
    /// When it expires (if applicable)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub expires_at: Option<DateTime<Utc>>,
    
    /// Is the entry active?
    pub active: bool,
}

/// Fraud detection thresholds (per prefix/profile)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FraudDetectionProfile {
    /// Profile ID
    pub id: Uuid,
    
    /// Profile name
    pub name: String,
    
    /// Number prefix this profile applies to
    pub prefix: String,
    
    /// CPM warning threshold
    pub cpm_warning: u32,
    
    /// CPM critical threshold
    pub cpm_critical: u32,
    
    /// ACD warning threshold (seconds)
    pub acd_warning: f64,
    
    /// ACD critical threshold (seconds)
    pub acd_critical: f64,
    
    /// Total calls warning threshold
    pub total_calls_warning: u32,
    
    /// Total calls critical threshold
    pub total_calls_critical: u32,
    
    /// Concurrent calls warning
    pub concurrent_warning: u32,
    
    /// Concurrent calls critical
    pub concurrent_critical: u32,
    
    /// Start hour (for time-based rules)
    pub start_hour: u8,
    
    /// End hour
    pub end_hour: u8,
    
    /// Days of week (bitmask: 1=Mon, 2=Tue, 4=Wed, etc.)
    pub days_of_week: u8,
    
    /// Is profile active?
    pub active: bool,
}

/// Settlement dispute record
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SettlementDispute {
    /// Dispute ID
    pub id: Uuid,
    
    /// Related call ID
    pub call_id: String,
    
    /// Dispute timestamp
    pub dispute_time: DateTime<Utc>,
    
    /// Dispute reason
    pub reason: String,
    
    /// Carrier ID involved
    #[serde(skip_serializing_if = "Option::is_none")]
    pub carrier_id: Option<i32>,
    
    /// Recovery amount (if applicable)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub recovery_amount: Option<f64>,
    
    /// Dispute status
    pub status: DisputeStatus,
}

/// Dispute status
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum DisputeStatus {
    Pending,
    UnderReview,
    Resolved,
    Rejected,
}

/// CDR (Call Detail Record) for accounting
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CallDetailRecord {
    /// CDR ID
    pub id: Uuid,
    
    /// SIP Call-ID
    pub call_id: String,
    
    /// Caller ID
    pub caller_id: String,
    
    /// Called number
    pub called_number: String,
    
    /// Source IP
    pub source_ip: String,
    
    /// Source gateway name
    #[serde(skip_serializing_if = "Option::is_none")]
    pub source_gateway: Option<String>,
    
    /// Destination IP
    #[serde(skip_serializing_if = "Option::is_none")]
    pub destination_ip: Option<String>,
    
    /// Call start time
    pub start_time: DateTime<Utc>,
    
    /// Answer time
    #[serde(skip_serializing_if = "Option::is_none")]
    pub answer_time: Option<DateTime<Utc>>,
    
    /// End time
    #[serde(skip_serializing_if = "Option::is_none")]
    pub end_time: Option<DateTime<Utc>>,
    
    /// Duration in seconds
    pub duration: u32,
    
    /// Billable duration
    pub billable_duration: u32,
    
    /// Disposition
    pub disposition: String,
    
    /// SIP response code
    pub sip_code: u16,
    
    /// Fraud type (if detected)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub fraud_type: Option<String>,
    
    /// Whether reported to NCC
    pub ncc_reported: bool,
    
    /// MNP routing number applied
    #[serde(skip_serializing_if = "Option::is_none")]
    pub mnp_routing_number: Option<String>,
}

/// Batch detection request
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BatchDetectionRequest {
    pub events: Vec<CallEvent>,
}

/// Batch detection response
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BatchDetectionResponse {
    pub results: Vec<crate::detection::DetectionResult>,
    pub total: usize,
    pub fraud_count: usize,
    pub processing_time_ms: u64,
}

/// API error response
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ApiError {
    pub error: String,
    pub message: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub details: Option<serde_json::Value>,
}

impl ApiError {
    pub fn new(error: impl Into<String>, message: impl Into<String>) -> Self {
        Self {
            error: error.into(),
            message: message.into(),
            details: None,
        }
    }

    pub fn with_details(mut self, details: serde_json::Value) -> Self {
        self.details = Some(details);
        self
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_call_event_creation() {
        let event = CallEvent::new(
            "call-123",
            "+2348031234567",
            "+2348051234567",
            "192.168.1.1",
        );

        assert_eq!(event.call_id, "call-123");
        assert_eq!(event.caller_id, "+2348031234567");
        assert_eq!(event.method, "INVITE");
    }

    #[test]
    fn test_gateway_classification() {
        let mut gateway = GatewayProfile {
            id: Uuid::new_v4(),
            name: "Int Gateway".to_string(),
            ip: "1.2.3.4".to_string(),
            mask: 32,
            group_id: 10,
            protocol: "UDP".to_string(),
            port: 5060,
            tag: None,
            active: true,
            carrier: None,
            allowed_prefixes: vec![],
            created_at: Utc::now(),
            updated_at: Utc::now(),
        };

        assert!(gateway.is_international());
        assert!(!gateway.is_blacklisted());
        
        gateway.group_id = 66;
        assert!(gateway.is_blacklisted());
    }
}
