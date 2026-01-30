//! Call Aggregate - Represents a call within the detection window
//!
//! A Call is the primary entity for fraud detection. It tracks the caller,
//! called party, source IP, and detection status.

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

use crate::domain::{
    errors::DomainError,
    events::{CallRegisteredEvent, EventCollector},
    value_objects::{CallId, CallStatus, FraudScore, IPAddress, MSISDN},
};

/// Call aggregate root - represents a single call in the detection system
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Call {
    /// Unique call identifier
    id: CallId,
    /// Calling party number (A-number)
    a_number: MSISDN,
    /// Called party number (B-number)
    b_number: MSISDN,
    /// Source gateway IP address
    source_ip: IPAddress,
    /// Call timestamp
    timestamp: DateTime<Utc>,
    /// Call status
    status: CallStatus,
    /// Switch/gateway identifier
    switch_id: Option<String>,
    /// Original raw call ID from SIP
    raw_call_id: Option<String>,
    /// Whether this call has been flagged as fraudulent
    is_flagged: bool,
    /// Associated alert ID if flagged
    alert_id: Option<String>,
    /// Fraud score assigned to this call
    fraud_score: FraudScore,
    /// Creation timestamp
    created_at: DateTime<Utc>,
    /// Last update timestamp
    updated_at: DateTime<Utc>,
}

impl Call {
    /// Creates a new Call aggregate
    pub fn new(
        a_number: MSISDN,
        b_number: MSISDN,
        source_ip: IPAddress,
    ) -> (Self, CallRegisteredEvent) {
        let id = CallId::generate();
        let now = Utc::now();

        let event = CallRegisteredEvent::new(&id, &a_number, &b_number, &source_ip);

        let call = Self {
            id,
            a_number,
            b_number,
            source_ip,
            timestamp: now,
            status: CallStatus::Ringing,
            switch_id: None,
            raw_call_id: None,
            is_flagged: false,
            alert_id: None,
            fraud_score: FraudScore::default(),
            created_at: now,
            updated_at: now,
        };

        (call, event)
    }

    /// Reconstitutes a Call from persistence (no events emitted)
    pub fn reconstitute(
        id: CallId,
        a_number: MSISDN,
        b_number: MSISDN,
        source_ip: IPAddress,
        timestamp: DateTime<Utc>,
        status: CallStatus,
        switch_id: Option<String>,
        raw_call_id: Option<String>,
        is_flagged: bool,
        alert_id: Option<String>,
        fraud_score: FraudScore,
        created_at: DateTime<Utc>,
        updated_at: DateTime<Utc>,
    ) -> Self {
        Self {
            id,
            a_number,
            b_number,
            source_ip,
            timestamp,
            status,
            switch_id,
            raw_call_id,
            is_flagged,
            alert_id,
            fraud_score,
            created_at,
            updated_at,
        }
    }

    /// Creates a Call with a specific ID (for testing or imports)
    pub fn with_id(
        id: CallId,
        a_number: MSISDN,
        b_number: MSISDN,
        source_ip: IPAddress,
    ) -> Self {
        let now = Utc::now();
        Self {
            id,
            a_number,
            b_number,
            source_ip,
            timestamp: now,
            status: CallStatus::Ringing,
            switch_id: None,
            raw_call_id: None,
            is_flagged: false,
            alert_id: None,
            fraud_score: FraudScore::default(),
            created_at: now,
            updated_at: now,
        }
    }

    // === Getters ===

    pub fn id(&self) -> &CallId {
        &self.id
    }

    pub fn a_number(&self) -> &MSISDN {
        &self.a_number
    }

    pub fn b_number(&self) -> &MSISDN {
        &self.b_number
    }

    pub fn source_ip(&self) -> &IPAddress {
        &self.source_ip
    }

    pub fn timestamp(&self) -> DateTime<Utc> {
        self.timestamp
    }

    pub fn status(&self) -> CallStatus {
        self.status
    }

    pub fn switch_id(&self) -> Option<&str> {
        self.switch_id.as_deref()
    }

    pub fn raw_call_id(&self) -> Option<&str> {
        self.raw_call_id.as_deref()
    }

    pub fn is_flagged(&self) -> bool {
        self.is_flagged
    }

    pub fn alert_id(&self) -> Option<&str> {
        self.alert_id.as_deref()
    }

    pub fn fraud_score(&self) -> FraudScore {
        self.fraud_score
    }

    pub fn created_at(&self) -> DateTime<Utc> {
        self.created_at
    }

    pub fn updated_at(&self) -> DateTime<Utc> {
        self.updated_at
    }

    // === Behavior ===

    /// Updates the call status
    pub fn update_status(&mut self, status: CallStatus) -> Result<(), DomainError> {
        // Validate state transitions
        match (self.status, status) {
            (CallStatus::Completed | CallStatus::Failed | CallStatus::Blocked, _) => {
                return Err(DomainError::InvalidStateTransition {
                    from: format!("{:?}", self.status),
                    to: format!("{:?}", status),
                });
            }
            _ => {}
        }

        self.status = status;
        self.updated_at = Utc::now();
        Ok(())
    }

    /// Flags this call as part of a fraud alert
    pub fn flag_as_fraud(&mut self, alert_id: String, score: FraudScore) -> Result<(), DomainError> {
        if self.is_flagged {
            return Err(DomainError::InvariantViolation(
                "Call is already flagged".into(),
            ));
        }

        self.is_flagged = true;
        self.alert_id = Some(alert_id);
        self.fraud_score = score;
        self.updated_at = Utc::now();
        Ok(())
    }

    /// Sets switch metadata
    pub fn set_switch_info(&mut self, switch_id: String, raw_call_id: Option<String>) {
        self.switch_id = Some(switch_id);
        self.raw_call_id = raw_call_id;
        self.updated_at = Utc::now();
    }

    /// Checks if call is from an international source with Nigerian CLI
    pub fn is_potential_cli_masking(&self) -> bool {
        self.a_number.is_nigerian() && self.source_ip.is_likely_international()
    }

    /// Checks if call is active (for sliding window detection)
    pub fn is_active(&self) -> bool {
        matches!(self.status, CallStatus::Ringing | CallStatus::Active)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::events::DomainEvent;

    fn create_test_call() -> Call {
        let a_number = MSISDN::new("+2348012345678").unwrap();
        let b_number = MSISDN::new("+2348098765432").unwrap();
        let source_ip = IPAddress::new("192.168.1.1").unwrap();

        Call::with_id(
            CallId::generate(),
            a_number,
            b_number,
            source_ip,
        )
    }

    #[test]
    fn test_call_creation() {
        let a_number = MSISDN::new("+2348012345678").unwrap();
        let b_number = MSISDN::new("+2348098765432").unwrap();
        let source_ip = IPAddress::new("192.168.1.1").unwrap();

        let (call, event) = Call::new(a_number, b_number, source_ip);

        assert!(!call.is_flagged());
        assert!(call.is_active());
        assert_eq!(call.status(), CallStatus::Ringing);
        assert_eq!(event.event_type(), "CallRegistered");
    }

    #[test]
    fn test_status_transitions() {
        let mut call = create_test_call();

        // Valid transition
        assert!(call.update_status(CallStatus::Active).is_ok());
        assert_eq!(call.status(), CallStatus::Active);

        // Valid transition
        assert!(call.update_status(CallStatus::Completed).is_ok());
        assert_eq!(call.status(), CallStatus::Completed);

        // Invalid transition from terminal state
        assert!(call.update_status(CallStatus::Active).is_err());
    }

    #[test]
    fn test_flag_as_fraud() {
        let mut call = create_test_call();

        let score = FraudScore::new(0.95);
        assert!(call.flag_as_fraud("alert-123".into(), score).is_ok());
        assert!(call.is_flagged());
        assert_eq!(call.alert_id(), Some("alert-123"));

        // Cannot flag twice
        assert!(call.flag_as_fraud("alert-456".into(), score).is_err());
    }

    #[test]
    fn test_potential_cli_masking() {
        // Nigerian number from private IP - not CLI masking
        let a_number = MSISDN::new("+2348012345678").unwrap();
        let b_number = MSISDN::new("+2348098765432").unwrap();
        let private_ip = IPAddress::new("192.168.1.1").unwrap();

        let call = Call::with_id(CallId::generate(), a_number, b_number, private_ip);
        assert!(!call.is_potential_cli_masking());
    }
}
