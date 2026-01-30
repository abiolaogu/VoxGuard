//! Gateway Aggregate - Represents a network gateway/carrier
//!
//! Gateways are sources of SIP traffic. They have configurable thresholds
//! and can be blacklisted for fraud.

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::domain::{
    errors::DomainError,
    events::GatewayBlockedEvent,
    value_objects::IPAddress,
};

/// Gateway type classification
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum GatewayType {
    /// Local Nigerian carrier
    Local,
    /// International gateway
    International,
    /// Transit/interconnect
    Transit,
}

/// Gateway aggregate root
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Gateway {
    /// Unique identifier
    id: Uuid,
    /// Human-readable name
    name: String,
    /// Gateway IP address
    ip_address: IPAddress,
    /// Carrier name
    carrier_name: String,
    /// Gateway classification
    gateway_type: GatewayType,
    /// Fraud detection threshold
    fraud_threshold: f64,
    /// Calls per minute limit
    cpm_limit: u32,
    /// Average call duration threshold (seconds)
    acd_threshold: f64,
    /// Whether gateway is active
    is_active: bool,
    /// Whether gateway is blacklisted
    is_blacklisted: bool,
    /// Blacklist expiration (if temporary)
    blacklist_expires_at: Option<DateTime<Utc>>,
    /// Blacklist reason
    blacklist_reason: Option<String>,
    /// Creation timestamp
    created_at: DateTime<Utc>,
    /// Last update timestamp
    updated_at: DateTime<Utc>,
}

impl Gateway {
    /// Creates a new Gateway
    pub fn new(
        name: impl Into<String>,
        ip_address: IPAddress,
        carrier_name: impl Into<String>,
        gateway_type: GatewayType,
    ) -> Self {
        let now = Utc::now();
        Self {
            id: Uuid::new_v4(),
            name: name.into(),
            ip_address,
            carrier_name: carrier_name.into(),
            gateway_type,
            fraud_threshold: 0.8,  // Default 80%
            cpm_limit: 60,         // Default 60 CPM
            acd_threshold: 10.0,   // Default 10 seconds
            is_active: true,
            is_blacklisted: false,
            blacklist_expires_at: None,
            blacklist_reason: None,
            created_at: now,
            updated_at: now,
        }
    }

    // === Getters ===

    pub fn id(&self) -> Uuid {
        self.id
    }

    pub fn name(&self) -> &str {
        &self.name
    }

    pub fn ip_address(&self) -> &IPAddress {
        &self.ip_address
    }

    pub fn carrier_name(&self) -> &str {
        &self.carrier_name
    }

    pub fn gateway_type(&self) -> GatewayType {
        self.gateway_type
    }

    pub fn fraud_threshold(&self) -> f64 {
        self.fraud_threshold
    }

    pub fn cpm_limit(&self) -> u32 {
        self.cpm_limit
    }

    pub fn acd_threshold(&self) -> f64 {
        self.acd_threshold
    }

    pub fn is_active(&self) -> bool {
        self.is_active
    }

    pub fn is_blacklisted(&self) -> bool {
        // Check if blacklist has expired
        if self.is_blacklisted {
            if let Some(expires) = self.blacklist_expires_at {
                if expires < Utc::now() {
                    return false;
                }
            }
        }
        self.is_blacklisted
    }

    pub fn is_international(&self) -> bool {
        self.gateway_type == GatewayType::International
    }

    // === Behavior ===

    /// Updates detection thresholds
    pub fn update_thresholds(
        &mut self,
        fraud_threshold: Option<f64>,
        cpm_limit: Option<u32>,
        acd_threshold: Option<f64>,
    ) {
        if let Some(ft) = fraud_threshold {
            self.fraud_threshold = ft.clamp(0.0, 1.0);
        }
        if let Some(cpm) = cpm_limit {
            self.cpm_limit = cpm.min(1000);
        }
        if let Some(acd) = acd_threshold {
            self.acd_threshold = acd.max(1.0);
        }
        self.updated_at = Utc::now();
    }

    /// Activates the gateway
    pub fn activate(&mut self) {
        self.is_active = true;
        self.updated_at = Utc::now();
    }

    /// Deactivates the gateway
    pub fn deactivate(&mut self) {
        self.is_active = false;
        self.updated_at = Utc::now();
    }

    /// Blacklists the gateway
    pub fn blacklist(
        &mut self,
        reason: impl Into<String>,
        expires_at: Option<DateTime<Utc>>,
    ) -> GatewayBlockedEvent {
        self.is_blacklisted = true;
        self.blacklist_reason = Some(reason.into());
        self.blacklist_expires_at = expires_at;
        self.is_active = false;
        self.updated_at = Utc::now();

        GatewayBlockedEvent::new(
            &self.ip_address,
            self.blacklist_reason.as_deref().unwrap_or("Unknown"),
            expires_at,
        )
    }

    /// Removes gateway from blacklist
    pub fn unblacklist(&mut self) -> Result<(), DomainError> {
        if !self.is_blacklisted {
            return Err(DomainError::InvariantViolation(
                "Gateway is not blacklisted".into(),
            ));
        }

        self.is_blacklisted = false;
        self.blacklist_reason = None;
        self.blacklist_expires_at = None;
        self.updated_at = Utc::now();
        Ok(())
    }

    /// Checks if a CPM value exceeds the limit
    pub fn exceeds_cpm_limit(&self, cpm: u32) -> bool {
        cpm > self.cpm_limit
    }

    /// Checks if ACD is suspiciously low
    pub fn is_acd_suspicious(&self, acd: f64) -> bool {
        acd < self.acd_threshold
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::events::DomainEvent;

    fn create_test_gateway() -> Gateway {
        let ip = IPAddress::new("10.0.0.1").unwrap();
        Gateway::new("Lagos Gateway 1", ip, "MTN Nigeria", GatewayType::Local)
    }

    #[test]
    fn test_gateway_creation() {
        let gw = create_test_gateway();

        assert!(gw.is_active());
        assert!(!gw.is_blacklisted());
        assert_eq!(gw.gateway_type(), GatewayType::Local);
        assert!(!gw.is_international());
    }

    #[test]
    fn test_threshold_updates() {
        let mut gw = create_test_gateway();

        gw.update_thresholds(Some(0.9), Some(100), Some(5.0));

        assert_eq!(gw.fraud_threshold(), 0.9);
        assert_eq!(gw.cpm_limit(), 100);
        assert_eq!(gw.acd_threshold(), 5.0);
    }

    #[test]
    fn test_threshold_clamping() {
        let mut gw = create_test_gateway();

        // Values are clamped to valid ranges
        gw.update_thresholds(Some(1.5), Some(5000), Some(0.1));

        assert_eq!(gw.fraud_threshold(), 1.0);
        assert_eq!(gw.cpm_limit(), 1000);
        assert_eq!(gw.acd_threshold(), 1.0);
    }

    #[test]
    fn test_blacklist() {
        let mut gw = create_test_gateway();

        let event = gw.blacklist("Fraud detected", None);

        assert!(gw.is_blacklisted());
        assert!(!gw.is_active());
        assert_eq!(event.event_type(), "GatewayBlocked");
    }

    #[test]
    fn test_temporary_blacklist_expiry() {
        let mut gw = create_test_gateway();

        // Blacklist with past expiration
        let expired = Utc::now() - chrono::Duration::hours(1);
        gw.blacklist("Test", Some(expired));

        // Should report as not blacklisted since it expired
        assert!(!gw.is_blacklisted());
    }

    #[test]
    fn test_cpm_limit_check() {
        let gw = create_test_gateway();

        assert!(!gw.exceeds_cpm_limit(50));
        assert!(gw.exceeds_cpm_limit(100));
    }

    #[test]
    fn test_acd_suspicious_check() {
        let gw = create_test_gateway();

        // Default threshold is 10 seconds
        assert!(gw.is_acd_suspicious(5.0));  // Short calls are suspicious
        assert!(!gw.is_acd_suspicious(30.0)); // Normal call duration
    }
}
