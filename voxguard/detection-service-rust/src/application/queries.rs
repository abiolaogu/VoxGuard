//! Queries and DTOs for read operations

use serde::{Deserialize, Serialize};

/// Query for dashboard summary
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DashboardQuery {
    pub time_range_minutes: Option<i64>,
}

/// Query result for dashboard
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DashboardSummary {
    pub total_calls_24h: u64,
    pub fraud_calls_24h: u64,
    pub fraud_rate_24h: f64,
    pub active_gateways: usize,
    pub pending_alerts: usize,
    pub avg_detection_latency_us: f64,
    pub cache_hit_rate: f64,
}

/// Query for threat level
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ThreatQuery {
    pub b_number: String,
}

/// Query result for threat assessment
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ThreatAssessment {
    pub b_number: String,
    pub threat_level: String,
    pub distinct_callers: usize,
    pub distinct_ips: usize,
    pub call_count: usize,
    pub requires_action: bool,
}

/// Query for alerts with filters
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct AlertsQuery {
    pub event_type: Option<String>,
    pub severity_min: Option<i32>,
    pub status: Option<String>,
    pub start_time: Option<String>,
    pub end_time: Option<String>,
    pub page: Option<u32>,
    pub page_size: Option<u32>,
}

/// Paginated alert list result
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AlertsResult {
    pub alerts: Vec<AlertDetail>,
    pub total: usize,
    pub page: u32,
    pub page_size: u32,
}

/// Detailed alert information
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AlertDetail {
    pub id: String,
    pub b_number: String,
    pub fraud_type: String,
    pub severity: String,
    pub score: f64,
    pub distinct_callers: usize,
    pub status: String,
    pub created_at: String,
    pub acknowledged_by: Option<String>,
    pub resolved_by: Option<String>,
}
