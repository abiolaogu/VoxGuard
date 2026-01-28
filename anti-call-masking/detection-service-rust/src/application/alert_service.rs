//! Alert Service - Manages alert lifecycle

use std::sync::Arc;
use uuid::Uuid;
use tracing::{info, instrument};

use crate::domain::{
    aggregates::FraudAlert,
    errors::{DomainError, DomainResult},
    events::AlertResolution,
};
use crate::ports::AlertRepository;
use crate::application::commands::{AcknowledgeAlertCommand, ResolveAlertCommand};

/// Service for managing fraud alerts
pub struct AlertService<A: AlertRepository> {
    alert_repo: Arc<A>,
}

impl<A: AlertRepository> AlertService<A> {
    pub fn new(alert_repo: Arc<A>) -> Self {
        Self { alert_repo }
    }

    /// Acknowledges an alert
    #[instrument(skip(self))]
    pub async fn acknowledge(&self, cmd: AcknowledgeAlertCommand) -> DomainResult<()> {
        let alert_id = Uuid::parse_str(&cmd.alert_id)
            .map_err(|_| DomainError::AlertNotFound(cmd.alert_id.clone()))?;

        let mut alert = self.alert_repo
            .find_by_id(alert_id)
            .await?
            .ok_or_else(|| DomainError::AlertNotFound(cmd.alert_id.clone()))?;

        let _event = alert.acknowledge(&cmd.user_id)?;
        self.alert_repo.save(&alert).await?;

        info!(alert_id = %alert_id, user = %cmd.user_id, "Alert acknowledged");
        Ok(())
    }

    /// Resolves an alert
    #[instrument(skip(self))]
    pub async fn resolve(&self, cmd: ResolveAlertCommand) -> DomainResult<()> {
        let alert_id = Uuid::parse_str(&cmd.alert_id)
            .map_err(|_| DomainError::AlertNotFound(cmd.alert_id.clone()))?;

        let mut alert = self.alert_repo
            .find_by_id(alert_id)
            .await?
            .ok_or_else(|| DomainError::AlertNotFound(cmd.alert_id.clone()))?;

        let resolution = match cmd.resolution.as_str() {
            "confirmed_fraud" => AlertResolution::ConfirmedFraud,
            "false_positive" => AlertResolution::FalsePositive,
            "escalated_ncc" => AlertResolution::EscalatedNCC,
            "whitelisted" => AlertResolution::Whitelisted,
            _ => return Err(DomainError::ValidationError("Invalid resolution type".into())),
        };

        let _event = alert.resolve(&cmd.user_id, resolution, cmd.notes)?;
        self.alert_repo.save(&alert).await?;

        info!(alert_id = %alert_id, resolution = %cmd.resolution, "Alert resolved");
        Ok(())
    }

    /// Gets recent pending alerts
    pub async fn get_pending_alerts(&self) -> DomainResult<Vec<FraudAlert>> {
        use crate::domain::aggregates::fraud_alert::AlertStatus;
        self.alert_repo.find_by_status(AlertStatus::Pending).await
    }

    /// Gets pending alert count
    pub async fn count_pending(&self) -> DomainResult<usize> {
        self.alert_repo.count_pending().await
    }
}
