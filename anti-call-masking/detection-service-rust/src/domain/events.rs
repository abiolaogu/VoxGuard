//! Domain Events - Events emitted by aggregates
//!
//! These events represent facts about what happened in the domain.
//! They are used for event sourcing and cross-aggregate communication.

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use super::value_objects::{CallId, FraudScore, FraudType, IPAddress, MSISDN, Severity};

/// Base trait for all domain events
pub trait DomainEvent: Send + Sync {
    /// Returns the event type name
    fn event_type(&self) -> &'static str;
    
    /// Returns when the event occurred
    fn occurred_at(&self) -> DateTime<Utc>;
    
    /// Returns the aggregate ID this event relates to
    fn aggregate_id(&self) -> String;
}

/// Event emitted when a new call is registered for detection
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CallRegisteredEvent {
    pub event_id: Uuid,
    pub call_id: String,
    pub a_number: String,
    pub b_number: String,
    pub source_ip: String,
    pub occurred_at: DateTime<Utc>,
}

impl CallRegisteredEvent {
    pub fn new(call_id: &CallId, a_number: &MSISDN, b_number: &MSISDN, source_ip: &IPAddress) -> Self {
        Self {
            event_id: Uuid::new_v4(),
            call_id: call_id.to_string(),
            a_number: a_number.to_string(),
            b_number: b_number.to_string(),
            source_ip: source_ip.to_string(),
            occurred_at: Utc::now(),
        }
    }
}

impl DomainEvent for CallRegisteredEvent {
    fn event_type(&self) -> &'static str {
        "CallRegistered"
    }

    fn occurred_at(&self) -> DateTime<Utc> {
        self.occurred_at
    }

    fn aggregate_id(&self) -> String {
        self.call_id.clone()
    }
}

/// Event emitted when fraud is detected
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FraudDetectedEvent {
    pub event_id: Uuid,
    pub alert_id: Uuid,
    pub b_number: String,
    pub fraud_type: FraudType,
    pub score: f64,
    pub severity: Severity,
    pub distinct_callers: usize,
    pub source_ips: Vec<String>,
    pub call_ids: Vec<String>,
    pub occurred_at: DateTime<Utc>,
}

impl FraudDetectedEvent {
    pub fn new(
        alert_id: Uuid,
        b_number: &MSISDN,
        fraud_type: FraudType,
        score: FraudScore,
        distinct_callers: usize,
        source_ips: Vec<String>,
        call_ids: Vec<String>,
    ) -> Self {
        Self {
            event_id: Uuid::new_v4(),
            alert_id,
            b_number: b_number.to_string(),
            fraud_type,
            score: score.value(),
            severity: score.severity(),
            distinct_callers,
            source_ips,
            call_ids,
            occurred_at: Utc::now(),
        }
    }
}

impl DomainEvent for FraudDetectedEvent {
    fn event_type(&self) -> &'static str {
        "FraudDetected"
    }

    fn occurred_at(&self) -> DateTime<Utc> {
        self.occurred_at
    }

    fn aggregate_id(&self) -> String {
        self.alert_id.to_string()
    }
}

/// Event emitted when an alert is acknowledged
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AlertAcknowledgedEvent {
    pub event_id: Uuid,
    pub alert_id: Uuid,
    pub acknowledged_by: String,
    pub occurred_at: DateTime<Utc>,
}

impl AlertAcknowledgedEvent {
    pub fn new(alert_id: Uuid, acknowledged_by: impl Into<String>) -> Self {
        Self {
            event_id: Uuid::new_v4(),
            alert_id,
            acknowledged_by: acknowledged_by.into(),
            occurred_at: Utc::now(),
        }
    }
}

impl DomainEvent for AlertAcknowledgedEvent {
    fn event_type(&self) -> &'static str {
        "AlertAcknowledged"
    }

    fn occurred_at(&self) -> DateTime<Utc> {
        self.occurred_at
    }

    fn aggregate_id(&self) -> String {
        self.alert_id.to_string()
    }
}

/// Event emitted when an alert is resolved
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AlertResolvedEvent {
    pub event_id: Uuid,
    pub alert_id: Uuid,
    pub resolved_by: String,
    pub resolution: AlertResolution,
    pub notes: Option<String>,
    pub occurred_at: DateTime<Utc>,
}

/// Resolution type for alerts
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum AlertResolution {
    /// Confirmed fraud - take action
    ConfirmedFraud,
    /// False positive - no action needed
    FalsePositive,
    /// Escalated to NCC
    EscalatedNCC,
    /// Whitelisted - customer request
    Whitelisted,
}

impl AlertResolvedEvent {
    pub fn new(
        alert_id: Uuid,
        resolved_by: impl Into<String>,
        resolution: AlertResolution,
        notes: Option<String>,
    ) -> Self {
        Self {
            event_id: Uuid::new_v4(),
            alert_id,
            resolved_by: resolved_by.into(),
            resolution,
            notes,
            occurred_at: Utc::now(),
        }
    }
}

impl DomainEvent for AlertResolvedEvent {
    fn event_type(&self) -> &'static str {
        "AlertResolved"
    }

    fn occurred_at(&self) -> DateTime<Utc> {
        self.occurred_at
    }

    fn aggregate_id(&self) -> String {
        self.alert_id.to_string()
    }
}

/// Event emitted when a gateway is blocked
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GatewayBlockedEvent {
    pub event_id: Uuid,
    pub gateway_ip: String,
    pub reason: String,
    pub blocked_until: Option<DateTime<Utc>>,
    pub occurred_at: DateTime<Utc>,
}

impl GatewayBlockedEvent {
    pub fn new(
        gateway_ip: &IPAddress,
        reason: impl Into<String>,
        blocked_until: Option<DateTime<Utc>>,
    ) -> Self {
        Self {
            event_id: Uuid::new_v4(),
            gateway_ip: gateway_ip.to_string(),
            reason: reason.into(),
            blocked_until,
            occurred_at: Utc::now(),
        }
    }
}

impl DomainEvent for GatewayBlockedEvent {
    fn event_type(&self) -> &'static str {
        "GatewayBlocked"
    }

    fn occurred_at(&self) -> DateTime<Utc> {
        self.occurred_at
    }

    fn aggregate_id(&self) -> String {
        self.gateway_ip.clone()
    }
}

/// Container for collecting events from aggregate operations
#[derive(Default)]
pub struct EventCollector {
    events: Vec<Box<dyn DomainEvent>>,
}

impl EventCollector {
    pub fn new() -> Self {
        Self { events: Vec::new() }
    }

    pub fn push<E: DomainEvent + 'static>(&mut self, event: E) {
        self.events.push(Box::new(event));
    }

    pub fn drain(&mut self) -> Vec<Box<dyn DomainEvent>> {
        std::mem::take(&mut self.events)
    }

    pub fn is_empty(&self) -> bool {
        self.events.is_empty()
    }

    pub fn len(&self) -> usize {
        self.events.len()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_call_registered_event() {
        let call_id = crate::domain::value_objects::CallId::generate();
        let a_number = MSISDN::new("+2348012345678").unwrap();
        let b_number = MSISDN::new("+2348098765432").unwrap();
        let source_ip = IPAddress::new("192.168.1.1").unwrap();

        let event = CallRegisteredEvent::new(&call_id, &a_number, &b_number, &source_ip);

        assert_eq!(event.event_type(), "CallRegistered");
        assert_eq!(event.a_number, "+2348012345678");
        assert_eq!(event.b_number, "+2348098765432");
    }

    #[test]
    fn test_fraud_detected_event_severity() {
        let b_number = MSISDN::new("+2348012345678").unwrap();
        let score = FraudScore::new(0.95);

        let event = FraudDetectedEvent::new(
            Uuid::new_v4(),
            &b_number,
            FraudType::MaskingAttack,
            score,
            7,
            vec!["192.168.1.1".to_string()],
            vec!["call-1".to_string()],
        );

        assert_eq!(event.severity, Severity::Critical);
    }

    #[test]
    fn test_event_collector() {
        let mut collector = EventCollector::new();
        assert!(collector.is_empty());

        let event = AlertAcknowledgedEvent::new(Uuid::new_v4(), "admin");
        collector.push(event);

        assert_eq!(collector.len(), 1);

        let events = collector.drain();
        assert_eq!(events.len(), 1);
        assert!(collector.is_empty());
    }
}
