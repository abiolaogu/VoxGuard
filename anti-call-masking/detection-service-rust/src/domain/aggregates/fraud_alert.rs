//! FraudAlert Aggregate - Represents a detected fraud event
//!
//! A FraudAlert is created when the detection engine identifies suspicious activity.
//! It tracks the lifecycle from detection through resolution.

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::domain::{
    errors::DomainError,
    events::{AlertAcknowledgedEvent, AlertResolution, AlertResolvedEvent, FraudDetectedEvent},
    value_objects::{FraudScore, FraudType, IPAddress, MSISDN, Severity},
};

/// Alert status in the workflow
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum AlertStatus {
    /// Newly created, awaiting acknowledgment
    Pending,
    /// Reviewed by analyst
    Acknowledged,
    /// Investigation in progress
    Investigating,
    /// Alert resolved
    Resolved,
    /// Reported to NCC
    ReportedNCC,
}

/// FraudAlert aggregate root
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FraudAlert {
    /// Unique alert identifier
    id: Uuid,
    /// Target B-number under attack
    b_number: MSISDN,
    /// List of calling A-numbers involved
    a_numbers: Vec<String>,
    /// List of call IDs involved
    call_ids: Vec<String>,
    /// Source IP addresses involved
    source_ips: Vec<String>,
    /// Type of fraud detected
    fraud_type: FraudType,
    /// Fraud confidence score
    score: FraudScore,
    /// Severity level
    severity: Severity,
    /// Number of distinct callers
    distinct_callers: usize,
    /// Alert status
    status: AlertStatus,
    /// Detection window start
    window_start: DateTime<Utc>,
    /// Detection window end
    window_end: DateTime<Utc>,
    /// User who acknowledged the alert
    acknowledged_by: Option<String>,
    /// Acknowledgment timestamp
    acknowledged_at: Option<DateTime<Utc>>,
    /// User who resolved the alert
    resolved_by: Option<String>,
    /// Resolution timestamp
    resolved_at: Option<DateTime<Utc>>,
    /// Resolution type
    resolution: Option<AlertResolution>,
    /// Resolution notes
    resolution_notes: Option<String>,
    /// Whether reported to NCC
    ncc_reported: bool,
    /// NCC report ID
    ncc_report_id: Option<String>,
    /// Creation timestamp
    created_at: DateTime<Utc>,
    /// Last update timestamp
    updated_at: DateTime<Utc>,
}

impl FraudAlert {
    /// Creates a new FraudAlert when fraud is detected
    pub fn create(
        b_number: MSISDN,
        fraud_type: FraudType,
        score: FraudScore,
        a_numbers: Vec<String>,
        call_ids: Vec<String>,
        source_ips: Vec<String>,
        window_start: DateTime<Utc>,
        window_end: DateTime<Utc>,
    ) -> (Self, FraudDetectedEvent) {
        let id = Uuid::new_v4();
        let now = Utc::now();
        let distinct_callers = a_numbers.len();
        let severity = score.severity();

        let event = FraudDetectedEvent::new(
            id,
            &b_number,
            fraud_type,
            score,
            distinct_callers,
            source_ips.clone(),
            call_ids.clone(),
        );

        let alert = Self {
            id,
            b_number,
            a_numbers,
            call_ids,
            source_ips,
            fraud_type,
            score,
            severity,
            distinct_callers,
            status: AlertStatus::Pending,
            window_start,
            window_end,
            acknowledged_by: None,
            acknowledged_at: None,
            resolved_by: None,
            resolved_at: None,
            resolution: None,
            resolution_notes: None,
            ncc_reported: false,
            ncc_report_id: None,
            created_at: now,
            updated_at: now,
        };

        (alert, event)
    }

    /// Reconstitutes from persistence
    #[allow(clippy::too_many_arguments)]
    pub fn reconstitute(
        id: Uuid,
        b_number: MSISDN,
        a_numbers: Vec<String>,
        call_ids: Vec<String>,
        source_ips: Vec<String>,
        fraud_type: FraudType,
        score: FraudScore,
        status: AlertStatus,
        window_start: DateTime<Utc>,
        window_end: DateTime<Utc>,
        acknowledged_by: Option<String>,
        acknowledged_at: Option<DateTime<Utc>>,
        resolved_by: Option<String>,
        resolved_at: Option<DateTime<Utc>>,
        resolution: Option<AlertResolution>,
        resolution_notes: Option<String>,
        ncc_reported: bool,
        ncc_report_id: Option<String>,
        created_at: DateTime<Utc>,
        updated_at: DateTime<Utc>,
    ) -> Self {
        let severity = score.severity();
        let distinct_callers = a_numbers.len();

        Self {
            id,
            b_number,
            a_numbers,
            call_ids,
            source_ips,
            fraud_type,
            score,
            severity,
            distinct_callers,
            status,
            window_start,
            window_end,
            acknowledged_by,
            acknowledged_at,
            resolved_by,
            resolved_at,
            resolution,
            resolution_notes,
            ncc_reported,
            ncc_report_id,
            created_at,
            updated_at,
        }
    }

    // === Getters ===

    pub fn id(&self) -> Uuid {
        self.id
    }

    pub fn b_number(&self) -> &MSISDN {
        &self.b_number
    }

    pub fn a_numbers(&self) -> &[String] {
        &self.a_numbers
    }

    pub fn call_ids(&self) -> &[String] {
        &self.call_ids
    }

    pub fn source_ips(&self) -> &[String] {
        &self.source_ips
    }

    pub fn fraud_type(&self) -> FraudType {
        self.fraud_type
    }

    pub fn score(&self) -> FraudScore {
        self.score
    }

    pub fn severity(&self) -> Severity {
        self.severity
    }

    pub fn distinct_callers(&self) -> usize {
        self.distinct_callers
    }

    pub fn status(&self) -> AlertStatus {
        self.status
    }

    pub fn window_start(&self) -> DateTime<Utc> {
        self.window_start
    }

    pub fn window_end(&self) -> DateTime<Utc> {
        self.window_end
    }

    pub fn is_pending(&self) -> bool {
        self.status == AlertStatus::Pending
    }

    pub fn is_resolved(&self) -> bool {
        self.status == AlertStatus::Resolved
    }

    pub fn ncc_reported(&self) -> bool {
        self.ncc_reported
    }

    // === Behavior ===

    /// Acknowledges the alert
    pub fn acknowledge(&mut self, user_id: impl Into<String>) -> Result<AlertAcknowledgedEvent, DomainError> {
        if self.status != AlertStatus::Pending {
            return Err(DomainError::InvalidStateTransition {
                from: format!("{:?}", self.status),
                to: "Acknowledged".into(),
            });
        }

        let user = user_id.into();
        let now = Utc::now();

        self.status = AlertStatus::Acknowledged;
        self.acknowledged_by = Some(user.clone());
        self.acknowledged_at = Some(now);
        self.updated_at = now;

        Ok(AlertAcknowledgedEvent::new(self.id, user))
    }

    /// Starts investigation
    pub fn start_investigation(&mut self) -> Result<(), DomainError> {
        if self.status != AlertStatus::Acknowledged {
            return Err(DomainError::InvalidStateTransition {
                from: format!("{:?}", self.status),
                to: "Investigating".into(),
            });
        }

        self.status = AlertStatus::Investigating;
        self.updated_at = Utc::now();
        Ok(())
    }

    /// Resolves the alert
    pub fn resolve(
        &mut self,
        user_id: impl Into<String>,
        resolution: AlertResolution,
        notes: Option<String>,
    ) -> Result<AlertResolvedEvent, DomainError> {
        if self.status == AlertStatus::Resolved {
            return Err(DomainError::InvalidStateTransition {
                from: "Resolved".into(),
                to: "Resolved".into(),
            });
        }

        let user = user_id.into();
        let now = Utc::now();

        self.status = AlertStatus::Resolved;
        self.resolved_by = Some(user.clone());
        self.resolved_at = Some(now);
        self.resolution = Some(resolution);
        self.resolution_notes = notes.clone();
        self.updated_at = now;

        Ok(AlertResolvedEvent::new(self.id, user, resolution, notes))
    }

    /// Marks as reported to NCC
    pub fn mark_ncc_reported(&mut self, report_id: String) {
        self.ncc_reported = true;
        self.ncc_report_id = Some(report_id);
        self.status = AlertStatus::ReportedNCC;
        self.updated_at = Utc::now();
    }

    /// Adds additional calls to this alert (for escalating attacks)
    pub fn add_calls(&mut self, new_call_ids: Vec<String>, new_a_numbers: Vec<String>) {
        for call_id in new_call_ids {
            if !self.call_ids.contains(&call_id) {
                self.call_ids.push(call_id);
            }
        }
        for a_num in new_a_numbers {
            if !self.a_numbers.contains(&a_num) {
                self.a_numbers.push(a_num);
            }
        }
        self.distinct_callers = self.a_numbers.len();
        self.updated_at = Utc::now();
    }

    /// Checks if this alert should trigger automatic blocking
    pub fn should_auto_block(&self) -> bool {
        self.score.exceeds_block_threshold() && self.severity == Severity::Critical
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::events::DomainEvent;
    use chrono::Duration;

    fn create_test_alert() -> FraudAlert {
        let b_number = MSISDN::new("+2348098765432").unwrap();
        let now = Utc::now();

        let (alert, _) = FraudAlert::create(
            b_number,
            FraudType::MaskingAttack,
            FraudScore::new(0.85),
            vec!["+2348011111111".into(), "+2348022222222".into()],
            vec!["call-1".into(), "call-2".into()],
            vec!["192.168.1.1".into()],
            now - Duration::seconds(5),
            now,
        );
        alert
    }

    #[test]
    fn test_alert_creation() {
        let b_number = MSISDN::new("+2348098765432").unwrap();
        let now = Utc::now();

        let (alert, event) = FraudAlert::create(
            b_number,
            FraudType::MaskingAttack,
            FraudScore::new(0.95),
            vec!["+2348011111111".into()],
            vec!["call-1".into()],
            vec!["10.0.0.1".into()],
            now - Duration::seconds(5),
            now,
        );

        assert!(alert.is_pending());
        assert_eq!(alert.fraud_type(), FraudType::MaskingAttack);
        assert_eq!(alert.severity(), Severity::Critical);
        assert_eq!(event.event_type(), "FraudDetected");
    }

    #[test]
    fn test_acknowledge_workflow() {
        let mut alert = create_test_alert();

        // Acknowledge
        let event = alert.acknowledge("analyst-1").unwrap();
        assert_eq!(alert.status(), AlertStatus::Acknowledged);
        assert_eq!(event.event_type(), "AlertAcknowledged");

        // Cannot acknowledge again
        assert!(alert.acknowledge("analyst-2").is_err());

        // Start investigation
        assert!(alert.start_investigation().is_ok());
        assert_eq!(alert.status(), AlertStatus::Investigating);
    }

    #[test]
    fn test_resolve_workflow() {
        let mut alert = create_test_alert();
        alert.acknowledge("analyst-1").unwrap();

        let event = alert
            .resolve("analyst-1", AlertResolution::ConfirmedFraud, Some("Verified attack".into()))
            .unwrap();

        assert!(alert.is_resolved());
        assert_eq!(event.event_type(), "AlertResolved");

        // Cannot resolve again
        assert!(alert.resolve("analyst-2", AlertResolution::FalsePositive, None).is_err());
    }

    #[test]
    fn test_add_escalating_calls() {
        let mut alert = create_test_alert();
        assert_eq!(alert.distinct_callers(), 2);

        alert.add_calls(
            vec!["call-3".into()],
            vec!["+2348033333333".into()],
        );

        assert_eq!(alert.distinct_callers(), 3);
        assert_eq!(alert.call_ids().len(), 3);
    }

    #[test]
    fn test_auto_block_threshold() {
        let b_number = MSISDN::new("+2348098765432").unwrap();
        let now = Utc::now();

        // High score alert should auto-block
        let (alert, _) = FraudAlert::create(
            b_number.clone(),
            FraudType::MaskingAttack,
            FraudScore::new(0.95),
            vec!["+2348011111111".into()],
            vec!["call-1".into()],
            vec!["10.0.0.1".into()],
            now - Duration::seconds(5),
            now,
        );
        assert!(alert.should_auto_block());

        // Lower score should not auto-block
        let (alert2, _) = FraudAlert::create(
            b_number,
            FraudType::MaskingAttack,
            FraudScore::new(0.5),
            vec!["+2348011111111".into()],
            vec!["call-1".into()],
            vec!["10.0.0.1".into()],
            now - Duration::seconds(5),
            now,
        );
        assert!(!alert2.should_auto_block());
    }
}
