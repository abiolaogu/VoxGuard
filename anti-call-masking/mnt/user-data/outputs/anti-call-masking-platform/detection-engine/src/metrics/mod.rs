//! Prometheus Metrics Module
//!
//! Exposes detection engine metrics in Prometheus format for monitoring.

use prometheus::{
    Counter, CounterVec, Gauge, GaugeVec, Histogram, HistogramOpts, HistogramVec,
    IntCounter, IntCounterVec, IntGauge, IntGaugeVec, Opts, Registry,
};
use std::sync::Arc;

/// Application metrics registry
pub struct Metrics {
    pub registry: Registry,
    
    // Detection metrics
    pub detections_total: IntCounterVec,
    pub fraud_detected_total: IntCounterVec,
    pub detection_latency: HistogramVec,
    pub detection_confidence: Histogram,
    
    // Call metrics
    pub calls_processed: IntCounter,
    pub active_calls: IntGauge,
    pub calls_blocked: IntCounterVec,
    
    // Cache metrics
    pub cache_hits: IntCounterVec,
    pub cache_misses: IntCounterVec,
    pub cache_latency: HistogramVec,
    
    // MNP metrics
    pub mnp_lookups_total: IntCounter,
    pub mnp_cache_hit_rate: Gauge,
    pub mnp_lookup_latency: Histogram,
    
    // Database metrics
    pub db_queries_total: IntCounterVec,
    pub db_query_latency: HistogramVec,
    pub db_connections_active: IntGaugeVec,
    
    // NCC reporting metrics
    pub ncc_reports_sent: IntCounter,
    pub ncc_reports_failed: IntCounter,
    pub ncc_report_latency: Histogram,
    
    // Gateway metrics
    pub gateway_calls: IntCounterVec,
    pub gateway_fraud_rate: GaugeVec,
    
    // SIM-box detection metrics
    pub simbox_suspects: IntGauge,
    pub simbox_blocked: IntCounter,
    pub cpm_threshold_breaches: IntCounterVec,
    
    // System metrics
    pub uptime_seconds: IntGauge,
    pub memory_bytes: IntGauge,
    pub goroutines: IntGauge,
}

impl Metrics {
    pub fn new() -> Self {
        let registry = Registry::new();

        // Detection metrics
        let detections_total = IntCounterVec::new(
            Opts::new("acm_detections_total", "Total number of fraud detection checks"),
            &["region", "result"],
        ).unwrap();
        registry.register(Box::new(detections_total.clone())).unwrap();

        let fraud_detected_total = IntCounterVec::new(
            Opts::new("acm_fraud_detected_total", "Total fraud events detected"),
            &["fraud_type", "severity"],
        ).unwrap();
        registry.register(Box::new(fraud_detected_total.clone())).unwrap();

        let detection_latency = HistogramVec::new(
            HistogramOpts::new(
                "acm_detection_latency_microseconds",
                "Detection latency in microseconds"
            ).buckets(vec![50.0, 100.0, 200.0, 500.0, 1000.0, 2000.0, 5000.0]),
            &["detection_type"],
        ).unwrap();
        registry.register(Box::new(detection_latency.clone())).unwrap();

        let detection_confidence = Histogram::with_opts(
            HistogramOpts::new(
                "acm_detection_confidence",
                "Distribution of fraud detection confidence scores"
            ).buckets(vec![0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 0.95, 0.99]),
        ).unwrap();
        registry.register(Box::new(detection_confidence.clone())).unwrap();

        // Call metrics
        let calls_processed = IntCounter::new(
            "acm_calls_processed_total",
            "Total calls processed"
        ).unwrap();
        registry.register(Box::new(calls_processed.clone())).unwrap();

        let active_calls = IntGauge::new(
            "acm_active_calls",
            "Currently active calls being monitored"
        ).unwrap();
        registry.register(Box::new(active_calls.clone())).unwrap();

        let calls_blocked = IntCounterVec::new(
            Opts::new("acm_calls_blocked_total", "Calls blocked due to fraud"),
            &["reason"],
        ).unwrap();
        registry.register(Box::new(calls_blocked.clone())).unwrap();

        // Cache metrics
        let cache_hits = IntCounterVec::new(
            Opts::new("acm_cache_hits_total", "Cache hit count"),
            &["cache_type"],
        ).unwrap();
        registry.register(Box::new(cache_hits.clone())).unwrap();

        let cache_misses = IntCounterVec::new(
            Opts::new("acm_cache_misses_total", "Cache miss count"),
            &["cache_type"],
        ).unwrap();
        registry.register(Box::new(cache_misses.clone())).unwrap();

        let cache_latency = HistogramVec::new(
            HistogramOpts::new(
                "acm_cache_latency_microseconds",
                "Cache operation latency"
            ).buckets(vec![10.0, 50.0, 100.0, 500.0, 1000.0, 5000.0]),
            &["operation", "cache_type"],
        ).unwrap();
        registry.register(Box::new(cache_latency.clone())).unwrap();

        // MNP metrics
        let mnp_lookups_total = IntCounter::new(
            "acm_mnp_lookups_total",
            "Total MNP lookups performed"
        ).unwrap();
        registry.register(Box::new(mnp_lookups_total.clone())).unwrap();

        let mnp_cache_hit_rate = Gauge::new(
            "acm_mnp_cache_hit_rate",
            "MNP cache hit rate (0-1)"
        ).unwrap();
        registry.register(Box::new(mnp_cache_hit_rate.clone())).unwrap();

        let mnp_lookup_latency = Histogram::with_opts(
            HistogramOpts::new(
                "acm_mnp_lookup_latency_microseconds",
                "MNP lookup latency"
            ).buckets(vec![100.0, 500.0, 1000.0, 5000.0, 10000.0, 50000.0]),
        ).unwrap();
        registry.register(Box::new(mnp_lookup_latency.clone())).unwrap();

        // Database metrics
        let db_queries_total = IntCounterVec::new(
            Opts::new("acm_db_queries_total", "Total database queries"),
            &["database", "operation"],
        ).unwrap();
        registry.register(Box::new(db_queries_total.clone())).unwrap();

        let db_query_latency = HistogramVec::new(
            HistogramOpts::new(
                "acm_db_query_latency_milliseconds",
                "Database query latency"
            ).buckets(vec![1.0, 5.0, 10.0, 25.0, 50.0, 100.0, 250.0, 500.0]),
            &["database", "operation"],
        ).unwrap();
        registry.register(Box::new(db_query_latency.clone())).unwrap();

        let db_connections_active = IntGaugeVec::new(
            Opts::new("acm_db_connections_active", "Active database connections"),
            &["database"],
        ).unwrap();
        registry.register(Box::new(db_connections_active.clone())).unwrap();

        // NCC reporting metrics
        let ncc_reports_sent = IntCounter::new(
            "acm_ncc_reports_sent_total",
            "Total fraud reports sent to NCC"
        ).unwrap();
        registry.register(Box::new(ncc_reports_sent.clone())).unwrap();

        let ncc_reports_failed = IntCounter::new(
            "acm_ncc_reports_failed_total",
            "Failed NCC report submissions"
        ).unwrap();
        registry.register(Box::new(ncc_reports_failed.clone())).unwrap();

        let ncc_report_latency = Histogram::with_opts(
            HistogramOpts::new(
                "acm_ncc_report_latency_milliseconds",
                "NCC API report submission latency"
            ).buckets(vec![50.0, 100.0, 250.0, 500.0, 1000.0, 2500.0, 5000.0]),
        ).unwrap();
        registry.register(Box::new(ncc_report_latency.clone())).unwrap();

        // Gateway metrics
        let gateway_calls = IntCounterVec::new(
            Opts::new("acm_gateway_calls_total", "Calls per gateway"),
            &["gateway_id", "gateway_group"],
        ).unwrap();
        registry.register(Box::new(gateway_calls.clone())).unwrap();

        let gateway_fraud_rate = GaugeVec::new(
            Opts::new("acm_gateway_fraud_rate", "Fraud rate per gateway (0-1)"),
            &["gateway_id"],
        ).unwrap();
        registry.register(Box::new(gateway_fraud_rate.clone())).unwrap();

        // SIM-box metrics
        let simbox_suspects = IntGauge::new(
            "acm_simbox_suspects",
            "Current number of suspected SIM-box CLIs"
        ).unwrap();
        registry.register(Box::new(simbox_suspects.clone())).unwrap();

        let simbox_blocked = IntCounter::new(
            "acm_simbox_blocked_total",
            "Total SIM-box calls blocked"
        ).unwrap();
        registry.register(Box::new(simbox_blocked.clone())).unwrap();

        let cpm_threshold_breaches = IntCounterVec::new(
            Opts::new("acm_cpm_threshold_breaches_total", "CPM threshold breaches"),
            &["threshold_level"],
        ).unwrap();
        registry.register(Box::new(cpm_threshold_breaches.clone())).unwrap();

        // System metrics
        let uptime_seconds = IntGauge::new(
            "acm_uptime_seconds",
            "Time since service started"
        ).unwrap();
        registry.register(Box::new(uptime_seconds.clone())).unwrap();

        let memory_bytes = IntGauge::new(
            "acm_memory_bytes",
            "Current memory usage in bytes"
        ).unwrap();
        registry.register(Box::new(memory_bytes.clone())).unwrap();

        let goroutines = IntGauge::new(
            "acm_goroutines",
            "Number of active goroutines/tasks"
        ).unwrap();
        registry.register(Box::new(goroutines.clone())).unwrap();

        Self {
            registry,
            detections_total,
            fraud_detected_total,
            detection_latency,
            detection_confidence,
            calls_processed,
            active_calls,
            calls_blocked,
            cache_hits,
            cache_misses,
            cache_latency,
            mnp_lookups_total,
            mnp_cache_hit_rate,
            mnp_lookup_latency,
            db_queries_total,
            db_query_latency,
            db_connections_active,
            ncc_reports_sent,
            ncc_reports_failed,
            ncc_report_latency,
            gateway_calls,
            gateway_fraud_rate,
            simbox_suspects,
            simbox_blocked,
            cpm_threshold_breaches,
            uptime_seconds,
            memory_bytes,
            goroutines,
        }
    }

    /// Record a detection event
    pub fn record_detection(&self, latency_us: u64, is_fraud: bool) {
        self.calls_processed.inc();
        self.detections_total.with_label_values(&["lagos", if is_fraud { "fraud" } else { "clean" }]).inc();
        self.detection_latency.with_label_values(&["full"]).observe(latency_us as f64);
    }

    /// Record fraud detection
    pub fn record_fraud(&self, fraud_type: &str, severity: u8, confidence: f64) {
        self.fraud_detected_total.with_label_values(&[fraud_type, &severity.to_string()]).inc();
        self.detection_confidence.observe(confidence);
    }

    /// Record cache access
    pub fn record_cache_access(&self, cache_type: &str, hit: bool, latency_us: u64) {
        if hit {
            self.cache_hits.with_label_values(&[cache_type]).inc();
        } else {
            self.cache_misses.with_label_values(&[cache_type]).inc();
        }
        self.cache_latency.with_label_values(&["get", cache_type]).observe(latency_us as f64);
    }

    /// Record MNP lookup
    pub fn record_mnp_lookup(&self, latency_us: u64) {
        self.mnp_lookups_total.inc();
        self.mnp_lookup_latency.observe(latency_us as f64);
    }

    /// Record database query
    pub fn record_db_query(&self, database: &str, operation: &str, latency_ms: f64) {
        self.db_queries_total.with_label_values(&[database, operation]).inc();
        self.db_query_latency.with_label_values(&[database, operation]).observe(latency_ms);
    }

    /// Record NCC report
    pub fn record_ncc_report(&self, success: bool, latency_ms: f64) {
        if success {
            self.ncc_reports_sent.inc();
        } else {
            self.ncc_reports_failed.inc();
        }
        self.ncc_report_latency.observe(latency_ms);
    }

    /// Record gateway call
    pub fn record_gateway_call(&self, gateway_id: &str, group: &str) {
        self.gateway_calls.with_label_values(&[gateway_id, group]).inc();
    }

    /// Update gateway fraud rate
    pub fn update_gateway_fraud_rate(&self, gateway_id: &str, rate: f64) {
        self.gateway_fraud_rate.with_label_values(&[gateway_id]).set(rate);
    }

    /// Record SIM-box detection
    pub fn record_simbox_blocked(&self) {
        self.simbox_blocked.inc();
    }

    /// Update SIM-box suspect count
    pub fn update_simbox_suspects(&self, count: i64) {
        self.simbox_suspects.set(count);
    }

    /// Record CPM threshold breach
    pub fn record_cpm_breach(&self, level: &str) {
        self.cpm_threshold_breaches.with_label_values(&[level]).inc();
    }

    /// Encode metrics in Prometheus format
    pub fn encode(&self) -> String {
        use prometheus::Encoder;
        let encoder = prometheus::TextEncoder::new();
        let metric_families = self.registry.gather();
        let mut buffer = Vec::new();
        encoder.encode(&metric_families, &mut buffer).unwrap();
        String::from_utf8(buffer).unwrap()
    }
}

impl Default for Metrics {
    fn default() -> Self {
        Self::new()
    }
}

/// Create a shared metrics instance
pub fn create_metrics() -> Arc<Metrics> {
    Arc::new(Metrics::new())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_metrics_creation() {
        let metrics = Metrics::new();
        metrics.record_detection(500, false);
        metrics.record_detection(200, true);
        
        let output = metrics.encode();
        assert!(output.contains("acm_calls_processed_total"));
        assert!(output.contains("acm_detections_total"));
    }

    #[test]
    fn test_fraud_recording() {
        let metrics = Metrics::new();
        metrics.record_fraud("CLI_MASK", 3, 0.95);
        
        let output = metrics.encode();
        assert!(output.contains("acm_fraud_detected_total"));
    }
}
