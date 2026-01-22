//! Metrics handlers for Prometheus scraping and system statistics
//! Exposes operational metrics for monitoring the anti-call-masking platform

use crate::{AppState, models::ApiError};
use axum::{
    extract::State,
    http::StatusCode,
    response::IntoResponse,
    Json,
};
use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc, Duration};
use std::sync::atomic::Ordering;

/// Prometheus metrics endpoint
pub async fn prometheus_metrics(
    State(state): State<AppState>,
) -> impl IntoResponse {
    let metrics = state.metrics.render_prometheus();
    
    (
        StatusCode::OK,
        [("Content-Type", "text/plain; version=0.0.4")],
        metrics,
    )
}

/// System metrics summary
#[derive(Debug, Serialize)]
pub struct SystemMetrics {
    pub uptime_seconds: u64,
    pub detection: DetectionMetrics,
    pub cache: CacheMetrics,
    pub database: DatabaseMetrics,
    pub ncc: NccMetrics,
    pub system: ResourceMetrics,
}

#[derive(Debug, Serialize)]
pub struct DetectionMetrics {
    pub total_calls_processed: u64,
    pub fraud_detected: u64,
    pub fraud_rate_percent: f64,
    pub avg_latency_us: u64,
    pub p50_latency_us: u64,
    pub p95_latency_us: u64,
    pub p99_latency_us: u64,
    pub calls_per_second: f64,
    pub current_cps: f64,
}

#[derive(Debug, Serialize)]
pub struct CacheMetrics {
    pub l1_hits: u64,
    pub l1_misses: u64,
    pub l1_hit_rate: f64,
    pub l2_hits: u64,
    pub l2_misses: u64,
    pub l2_hit_rate: f64,
    pub l3_hits: u64,
    pub total_lookups: u64,
    pub mnp_cache_size: u64,
    pub blacklist_cache_size: u64,
}

#[derive(Debug, Serialize)]
pub struct DatabaseMetrics {
    pub yugabyte_connected: bool,
    pub yugabyte_latency_ms: u64,
    pub clickhouse_connected: bool,
    pub clickhouse_latency_ms: u64,
    pub active_connections: i32,
    pub query_count_1m: u64,
}

#[derive(Debug, Serialize)]
pub struct NccMetrics {
    pub reports_sent_24h: u64,
    pub reports_failed_24h: u64,
    pub last_sync: Option<DateTime<Utc>>,
    pub api_status: String,
    pub avg_response_time_ms: u64,
}

#[derive(Debug, Serialize)]
pub struct ResourceMetrics {
    pub cpu_usage_percent: f64,
    pub memory_used_mb: u64,
    pub memory_total_mb: u64,
    pub heap_size_mb: u64,
    pub thread_count: u32,
    pub open_connections: u32,
}

/// Get system metrics
pub async fn get_system_metrics(
    State(state): State<AppState>,
) -> Result<Json<SystemMetrics>, (StatusCode, Json<ApiError>)> {
    let metrics = state.metrics.snapshot();
    
    // Get database health
    let yugabyte_status = state.yugabyte.health_check().await;
    let clickhouse_status = state.clickhouse.health_check().await;
    
    // Get cache stats
    let cache_stats = state.cache.get_stats().await;
    
    // Get NCC reporter stats
    let ncc_stats = state.ncc_reporter.get_stats().await;

    let uptime = state.start_time.elapsed().as_secs();

    Ok(Json(SystemMetrics {
        uptime_seconds: uptime,
        detection: DetectionMetrics {
            total_calls_processed: metrics.total_calls.load(Ordering::Relaxed),
            fraud_detected: metrics.fraud_detected.load(Ordering::Relaxed),
            fraud_rate_percent: calculate_fraud_rate(&metrics),
            avg_latency_us: metrics.avg_latency_us.load(Ordering::Relaxed),
            p50_latency_us: metrics.p50_latency.load(Ordering::Relaxed),
            p95_latency_us: metrics.p95_latency.load(Ordering::Relaxed),
            p99_latency_us: metrics.p99_latency.load(Ordering::Relaxed),
            calls_per_second: calculate_cps(&metrics),
            current_cps: metrics.current_cps.load(Ordering::Relaxed) as f64,
        },
        cache: CacheMetrics {
            l1_hits: cache_stats.l1_hits,
            l1_misses: cache_stats.l1_misses,
            l1_hit_rate: calculate_hit_rate(cache_stats.l1_hits, cache_stats.l1_misses),
            l2_hits: cache_stats.l2_hits,
            l2_misses: cache_stats.l2_misses,
            l2_hit_rate: calculate_hit_rate(cache_stats.l2_hits, cache_stats.l2_misses),
            l3_hits: cache_stats.l3_hits,
            total_lookups: cache_stats.l1_hits + cache_stats.l1_misses,
            mnp_cache_size: cache_stats.mnp_cache_size,
            blacklist_cache_size: cache_stats.blacklist_cache_size,
        },
        database: DatabaseMetrics {
            yugabyte_connected: yugabyte_status.is_ok(),
            yugabyte_latency_ms: yugabyte_status.as_ref().map(|s| s.latency_ms).unwrap_or(0),
            clickhouse_connected: clickhouse_status.is_ok(),
            clickhouse_latency_ms: clickhouse_status.as_ref().map(|s| s.latency_ms).unwrap_or(0),
            active_connections: yugabyte_status.as_ref().map(|s| s.active_connections).unwrap_or(0),
            query_count_1m: metrics.db_queries_1m.load(Ordering::Relaxed),
        },
        ncc: NccMetrics {
            reports_sent_24h: ncc_stats.reports_sent,
            reports_failed_24h: ncc_stats.reports_failed,
            last_sync: ncc_stats.last_sync,
            api_status: ncc_stats.api_status,
            avg_response_time_ms: ncc_stats.avg_response_time_ms,
        },
        system: get_resource_metrics(),
    }))
}

fn calculate_fraud_rate(metrics: &crate::metrics::MetricsSnapshot) -> f64 {
    let total = metrics.total_calls.load(Ordering::Relaxed);
    let fraud = metrics.fraud_detected.load(Ordering::Relaxed);
    if total == 0 {
        0.0
    } else {
        (fraud as f64 / total as f64) * 100.0
    }
}

fn calculate_cps(metrics: &crate::metrics::MetricsSnapshot) -> f64 {
    let total = metrics.total_calls.load(Ordering::Relaxed);
    let uptime = metrics.uptime_seconds.load(Ordering::Relaxed);
    if uptime == 0 {
        0.0
    } else {
        total as f64 / uptime as f64
    }
}

fn calculate_hit_rate(hits: u64, misses: u64) -> f64 {
    let total = hits + misses;
    if total == 0 {
        0.0
    } else {
        (hits as f64 / total as f64) * 100.0
    }
}

fn get_resource_metrics() -> ResourceMetrics {
    // Get system metrics (simplified - would use sys-info crate in production)
    ResourceMetrics {
        cpu_usage_percent: 0.0, // Would need sys-info crate
        memory_used_mb: 0,
        memory_total_mb: 0,
        heap_size_mb: 0,
        thread_count: 0,
        open_connections: 0,
    }
}

/// Real-time metrics for dashboard
#[derive(Debug, Serialize)]
pub struct DashboardMetrics {
    pub timestamp: DateTime<Utc>,
    pub calls_per_second: f64,
    pub fraud_rate_percent: f64,
    pub avg_latency_us: u64,
    pub cache_hit_rate: f64,
    pub active_alerts: i64,
    pub pending_ncc_reports: i64,
    pub regional_status: Vec<RegionalStatus>,
}

#[derive(Debug, Serialize)]
pub struct RegionalStatus {
    pub region: String,
    pub node_count: i32,
    pub avg_latency_ms: f64,
    pub replication_lag_ms: u64,
    pub status: String,
}

pub async fn get_dashboard_metrics(
    State(state): State<AppState>,
) -> Result<Json<DashboardMetrics>, (StatusCode, Json<ApiError>)> {
    let metrics = state.metrics.snapshot();
    let cache_stats = state.cache.get_stats().await;
    
    // Get regional status from DragonflyDB replication
    let regional_status = state.cache.get_regional_status().await.unwrap_or_default();

    Ok(Json(DashboardMetrics {
        timestamp: Utc::now(),
        calls_per_second: metrics.current_cps.load(Ordering::Relaxed) as f64,
        fraud_rate_percent: calculate_fraud_rate(&metrics),
        avg_latency_us: metrics.avg_latency_us.load(Ordering::Relaxed),
        cache_hit_rate: calculate_hit_rate(
            cache_stats.l1_hits + cache_stats.l2_hits,
            cache_stats.l1_misses + cache_stats.l2_misses - cache_stats.l2_hits,
        ),
        active_alerts: state.yugabyte.count_active_alerts().await.unwrap_or(0),
        pending_ncc_reports: state.yugabyte.count_pending_ncc_reports().await.unwrap_or(0),
        regional_status,
    }))
}

/// Historical metrics for charting
#[derive(Debug, Deserialize)]
pub struct HistoricalQuery {
    pub metric: String,
    pub period: Option<String>,
    pub interval: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct HistoricalData {
    pub metric: String,
    pub period: String,
    pub interval: String,
    pub data: Vec<DataPoint>,
}

#[derive(Debug, Serialize)]
pub struct DataPoint {
    pub timestamp: DateTime<Utc>,
    pub value: f64,
}

pub async fn get_historical_metrics(
    State(state): State<AppState>,
    axum::extract::Query(params): axum::extract::Query<HistoricalQuery>,
) -> Result<Json<HistoricalData>, (StatusCode, Json<ApiError>)> {
    let period = params.period.as_deref().unwrap_or("24h");
    let interval = params.interval.as_deref().unwrap_or("5m");
    
    let duration = match period {
        "1h" => Duration::hours(1),
        "6h" => Duration::hours(6),
        "24h" => Duration::hours(24),
        "7d" => Duration::days(7),
        _ => Duration::hours(24),
    };

    let interval_duration = match interval {
        "1m" => Duration::minutes(1),
        "5m" => Duration::minutes(5),
        "15m" => Duration::minutes(15),
        "1h" => Duration::hours(1),
        _ => Duration::minutes(5),
    };

    let from = Utc::now() - duration;

    match state.clickhouse.get_metric_history(&params.metric, from, interval_duration).await {
        Ok(data) => {
            Ok(Json(HistoricalData {
                metric: params.metric,
                period: period.to_string(),
                interval: interval.to_string(),
                data,
            }))
        }
        Err(e) => {
            tracing::error!("Failed to get historical metrics: {}", e);
            Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new("metrics_error", e.to_string())),
            ))
        }
    }
}

/// Node-specific metrics
#[derive(Debug, Serialize)]
pub struct NodeMetrics {
    pub node_id: String,
    pub region: String,
    pub hostname: String,
    pub ip: String,
    pub uptime_seconds: u64,
    pub calls_processed: u64,
    pub fraud_detected: u64,
    pub avg_latency_us: u64,
    pub cache_hit_rate: f64,
    pub cpu_percent: f64,
    pub memory_mb: u64,
    pub status: String,
}

pub async fn get_node_metrics(
    State(state): State<AppState>,
) -> Result<Json<NodeMetrics>, (StatusCode, Json<ApiError>)> {
    let metrics = state.metrics.snapshot();
    let cache_stats = state.cache.get_stats().await;

    Ok(Json(NodeMetrics {
        node_id: state.config.node_id.clone(),
        region: state.config.region.clone(),
        hostname: hostname::get()
            .map(|h| h.to_string_lossy().to_string())
            .unwrap_or_else(|_| "unknown".to_string()),
        ip: state.config.bind_address.clone(),
        uptime_seconds: state.start_time.elapsed().as_secs(),
        calls_processed: metrics.total_calls.load(Ordering::Relaxed),
        fraud_detected: metrics.fraud_detected.load(Ordering::Relaxed),
        avg_latency_us: metrics.avg_latency_us.load(Ordering::Relaxed),
        cache_hit_rate: calculate_hit_rate(
            cache_stats.l1_hits + cache_stats.l2_hits,
            cache_stats.l1_misses + cache_stats.l2_misses - cache_stats.l2_hits,
        ),
        cpu_percent: 0.0,
        memory_mb: 0,
        status: "healthy".to_string(),
    }))
}

/// Fraud type breakdown
#[derive(Debug, Serialize)]
pub struct FraudTypeMetrics {
    pub period: String,
    pub breakdown: Vec<FraudTypeCount>,
    pub total: u64,
}

#[derive(Debug, Serialize)]
pub struct FraudTypeCount {
    pub fraud_type: String,
    pub count: u64,
    pub percentage: f64,
    pub trend: String, // up, down, stable
}

pub async fn get_fraud_breakdown(
    State(state): State<AppState>,
    axum::extract::Query(params): axum::extract::Query<HistoricalQuery>,
) -> Result<Json<FraudTypeMetrics>, (StatusCode, Json<ApiError>)> {
    let period = params.period.as_deref().unwrap_or("24h");
    let duration = match period {
        "1h" => Duration::hours(1),
        "6h" => Duration::hours(6),
        "24h" => Duration::hours(24),
        "7d" => Duration::days(7),
        _ => Duration::hours(24),
    };

    let from = Utc::now() - duration;

    match state.clickhouse.get_fraud_breakdown(from).await {
        Ok(breakdown) => {
            let total: u64 = breakdown.iter().map(|b| b.count).sum();
            Ok(Json(FraudTypeMetrics {
                period: period.to_string(),
                breakdown,
                total,
            }))
        }
        Err(e) => {
            tracing::error!("Failed to get fraud breakdown: {}", e);
            Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new("metrics_error", e.to_string())),
            ))
        }
    }
}
