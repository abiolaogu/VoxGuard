//! Prometheus metrics for observability

use prometheus::{
    register_counter_vec, register_gauge, register_histogram_vec,
    CounterVec, Gauge, HistogramVec, Encoder, TextEncoder,
};
use lazy_static::lazy_static;

lazy_static! {
    /// Total calls processed
    pub static ref CALLS_TOTAL: CounterVec = register_counter_vec!(
        "acm_calls_total",
        "Total number of calls processed",
        &["status", "region"]
    ).unwrap();

    /// Fraud alerts generated
    pub static ref ALERTS_TOTAL: CounterVec = register_counter_vec!(
        "acm_alerts_total",
        "Total number of fraud alerts generated",
        &["fraud_type", "severity", "region"]
    ).unwrap();

    /// Detection latency histogram
    pub static ref DETECTION_LATENCY: HistogramVec = register_histogram_vec!(
        "acm_detection_latency_seconds",
        "Detection latency in seconds",
        &["region"],
        vec![0.0001, 0.0005, 0.001, 0.005, 0.01, 0.05, 0.1]
    ).unwrap();

    /// Cache operations
    pub static ref CACHE_OPS: CounterVec = register_counter_vec!(
        "acm_cache_operations_total",
        "Total cache operations",
        &["operation", "result"]
    ).unwrap();

    /// Current active calls
    pub static ref ACTIVE_CALLS: Gauge = register_gauge!(
        "acm_active_calls",
        "Current number of active calls in detection window"
    ).unwrap();

    /// Pending alerts gauge
    pub static ref PENDING_ALERTS: Gauge = register_gauge!(
        "acm_pending_alerts",
        "Number of unacknowledged fraud alerts"
    ).unwrap();
}

/// Returns Prometheus metrics as text
pub fn get_metrics() -> String {
    let encoder = TextEncoder::new();
    let metric_families = prometheus::gather();
    let mut buffer = Vec::new();
    encoder.encode(&metric_families, &mut buffer).unwrap();
    String::from_utf8(buffer).unwrap()
}

/// Records a call processing event
pub fn record_call(status: &str, region: &str) {
    CALLS_TOTAL.with_label_values(&[status, region]).inc();
}

/// Records a fraud alert
pub fn record_alert(fraud_type: &str, severity: &str, region: &str) {
    ALERTS_TOTAL.with_label_values(&[fraud_type, severity, region]).inc();
}

/// Records detection latency
pub fn record_latency(latency_secs: f64, region: &str) {
    DETECTION_LATENCY.with_label_values(&[region]).observe(latency_secs);
}
