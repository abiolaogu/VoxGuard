//! Domain Errors - Typed errors for domain operations

use thiserror::Error;

/// Domain-level errors that can occur during business logic execution
#[derive(Error, Debug, Clone)]
pub enum DomainError {
    /// Invalid call identifier format
    #[error("Invalid call ID: {0}")]
    InvalidCallId(String),

    /// Invalid phone number format
    #[error("Invalid MSISDN: {0}")]
    InvalidMSISDN(String),

    /// Invalid IP address format
    #[error("Invalid IP address: {0}")]
    InvalidIPAddress(String),

    /// Invalid configuration value
    #[error("Invalid configuration: {0}")]
    InvalidConfiguration(String),

    /// Alert already exists
    #[error("Alert already exists: {0}")]
    AlertAlreadyExists(String),

    /// Alert not found
    #[error("Alert not found: {0}")]
    AlertNotFound(String),

    /// Call not found
    #[error("Call not found: {0}")]
    CallNotFound(String),

    /// Gateway not found
    #[error("Gateway not found: {0}")]
    GatewayNotFound(String),

    /// Invalid state transition
    #[error("Invalid state transition: from {from} to {to}")]
    InvalidStateTransition { from: String, to: String },

    /// Cooldown period active
    #[error("Target {0} is in cooldown period until {1}")]
    CooldownActive(String, String),

    /// Validation error
    #[error("Validation error: {0}")]
    ValidationError(String),

    /// Invariant violation
    #[error("Domain invariant violated: {0}")]
    InvariantViolation(String),
}

/// Result type for domain operations
pub type DomainResult<T> = Result<T, DomainError>;
