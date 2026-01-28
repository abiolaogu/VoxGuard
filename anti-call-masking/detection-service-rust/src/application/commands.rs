//! Commands and DTOs for application layer

use serde::{Deserialize, Serialize};
use validator::Validate;

/// Command to register a new call for detection
#[derive(Debug, Clone, Serialize, Deserialize, Validate)]
pub struct RegisterCallCommand {
    #[validate(length(min = 1))]
    pub call_id: Option<String>,  // Optional - will generate if not provided
    #[validate(length(min = 8, max = 20))]
    pub a_number: String,
    #[validate(length(min = 8, max = 20))]
    pub b_number: String,
    pub source_ip: String,
    pub switch_id: Option<String>,
}

/// Command to acknowledge an alert
#[derive(Debug, Clone, Serialize, Deserialize, Validate)]
pub struct AcknowledgeAlertCommand {
    #[validate(length(min = 1))]
    pub alert_id: String,
    #[validate(length(min = 1))]
    pub user_id: String,
}

/// Command to resolve an alert
#[derive(Debug, Clone, Serialize, Deserialize, Validate)]
pub struct ResolveAlertCommand {
    #[validate(length(min = 1))]
    pub alert_id: String,
    #[validate(length(min = 1))]
    pub user_id: String,
    pub resolution: String,  // "confirmed_fraud", "false_positive", "escalated_ncc", "whitelisted"
    pub notes: Option<String>,
}

/// Command to blacklist a gateway
#[derive(Debug, Clone, Serialize, Deserialize, Validate)]
pub struct BlacklistGatewayCommand {
    pub ip_address: String,
    #[validate(length(min = 1))]
    pub reason: String,
    pub expires_in_hours: Option<u32>,
}

/// Result of call registration (detection response)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CallRegistrationResult {
    pub status: String,  // "processed" or "alert"
    pub call_id: String,
    pub distinct_callers: usize,
    pub alert: Option<AlertResult>,
}

/// Alert information returned when fraud is detected
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AlertResult {
    pub alert_id: String,
    pub b_number: String,
    pub fraud_type: String,
    pub severity: String,
    pub score: f64,
    pub distinct_callers: usize,
    pub description: String,
}
