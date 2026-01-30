//! Domain Aggregates - Rich domain models with encapsulated behavior
//!
//! Aggregates maintain consistency boundaries and enforce invariants.

pub mod call;
pub mod fraud_alert;
pub mod gateway;
pub mod threat_level;

pub use call::Call;
pub use fraud_alert::FraudAlert;
pub use gateway::Gateway;
pub use threat_level::ThreatLevel;
