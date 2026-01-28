//! Fraud alerts management handlers
//! Real-time alerts and historical alert queries

use crate::{
    models::{ApiError, FraudAlert, AlertStatus, AlertSeverity},
    AppState,
};
use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    Json,
};
use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc, Duration};

#[derive(Debug, Deserialize)]
pub struct AlertQuery {
    pub severity: Option<i32>,
    pub status: Option<String>,
    pub fraud_type: Option<String>,
    pub source_ip: Option<String>,
    pub from: Option<DateTime<Utc>>,
    pub to: Option<DateTime<Utc>>,
    pub limit: Option<i32>,
    pub offset: Option<i32>,
}

#[derive(Debug, Serialize)]
pub struct AlertListResponse {
    pub alerts: Vec<FraudAlert>,
    pub total: i64,
    pub limit: i32,
    pub offset: i32,
    pub summary: AlertSummary,
}

#[derive(Debug, Serialize)]
pub struct AlertSummary {
    pub critical: i64,
    pub high: i64,
    pub medium: i64,
    pub low: i64,
    pub total_24h: i64,
    pub pending: i64,
    pub investigating: i64,
    pub resolved: i64,
}

/// List fraud alerts with filtering
pub async fn list_alerts(
    State(state): State<AppState>,
    Query(params): Query<AlertQuery>,
) -> Result<Json<AlertListResponse>, (StatusCode, Json<ApiError>)> {
    let limit = params.limit.unwrap_or(100).min(1000);
    let offset = params.offset.unwrap_or(0);
    let from = params.from.unwrap_or_else(|| Utc::now() - Duration::hours(24));
    let to = params.to.unwrap_or_else(Utc::now);

    match state.yugabyte.list_alerts(
        params.severity,
        params.status.as_deref(),
        params.fraud_type.as_deref(),
        params.source_ip.as_deref(),
        from,
        to,
        limit,
        offset,
    ).await {
        Ok((alerts, total, summary)) => {
            Ok(Json(AlertListResponse {
                alerts,
                total,
                limit,
                offset,
                summary,
            }))
        }
        Err(e) => {
            tracing::error!("Failed to list alerts: {}", e);
            Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new("alert_error", e.to_string())),
            ))
        }
    }
}

/// Get alert by ID
pub async fn get_alert(
    State(state): State<AppState>,
    Path(id): Path<uuid::Uuid>,
) -> Result<Json<FraudAlert>, (StatusCode, Json<ApiError>)> {
    match state.yugabyte.get_alert(id).await {
        Ok(Some(alert)) => Ok(Json(alert)),
        Ok(None) => {
            Err((
                StatusCode::NOT_FOUND,
                Json(ApiError::new("not_found", "Alert not found")),
            ))
        }
        Err(e) => {
            tracing::error!("Failed to get alert: {}", e);
            Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new("alert_error", e.to_string())),
            ))
        }
    }
}

/// Update alert status (for investigation workflow)
#[derive(Debug, Deserialize)]
pub struct UpdateAlertRequest {
    pub status: String,
    pub notes: Option<String>,
    pub assigned_to: Option<String>,
    pub resolution: Option<String>,
}

pub async fn update_alert(
    State(state): State<AppState>,
    Path(id): Path<uuid::Uuid>,
    Json(request): Json<UpdateAlertRequest>,
) -> Result<Json<FraudAlert>, (StatusCode, Json<ApiError>)> {
    // Validate status
    let status = match request.status.to_uppercase().as_str() {
        "PENDING" => AlertStatus::Pending,
        "INVESTIGATING" => AlertStatus::Investigating,
        "CONFIRMED" => AlertStatus::Confirmed,
        "FALSE_POSITIVE" => AlertStatus::FalsePositive,
        "RESOLVED" => AlertStatus::Resolved,
        _ => {
            return Err((
                StatusCode::BAD_REQUEST,
                Json(ApiError::new("invalid_status", "Invalid alert status")),
            ));
        }
    };

    match state.yugabyte.update_alert(
        id,
        status,
        request.notes.as_deref(),
        request.assigned_to.as_deref(),
        request.resolution.as_deref(),
    ).await {
        Ok(alert) => {
            tracing::info!(alert_id = %id, status = ?status, "Alert updated");
            Ok(Json(alert))
        }
        Err(e) => {
            tracing::error!("Failed to update alert: {}", e);
            Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new("alert_error", e.to_string())),
            ))
        }
    }
}

/// Acknowledge multiple alerts
#[derive(Debug, Deserialize)]
pub struct BulkAcknowledgeRequest {
    pub alert_ids: Vec<uuid::Uuid>,
    pub acknowledged_by: String,
}

#[derive(Debug, Serialize)]
pub struct BulkAcknowledgeResponse {
    pub acknowledged: usize,
    pub failed: Vec<String>,
}

pub async fn bulk_acknowledge(
    State(state): State<AppState>,
    Json(request): Json<BulkAcknowledgeRequest>,
) -> Result<Json<BulkAcknowledgeResponse>, (StatusCode, Json<ApiError>)> {
    let mut acknowledged = 0;
    let mut failed = Vec::new();

    for id in request.alert_ids {
        match state.yugabyte.acknowledge_alert(id, &request.acknowledged_by).await {
            Ok(_) => acknowledged += 1,
            Err(e) => failed.push(format!("{}: {}", id, e)),
        }
    }

    tracing::info!(
        acknowledged,
        failed_count = failed.len(),
        by = %request.acknowledged_by,
        "Bulk acknowledge completed"
    );

    Ok(Json(BulkAcknowledgeResponse { acknowledged, failed }))
}

/// Get alert statistics
#[derive(Debug, Serialize)]
pub struct AlertStats {
    pub period: String,
    pub total_alerts: i64,
    pub by_severity: SeverityBreakdown,
    pub by_type: Vec<TypeCount>,
    pub top_sources: Vec<SourceCount>,
    pub trend: Vec<TrendPoint>,
}

#[derive(Debug, Serialize)]
pub struct SeverityBreakdown {
    pub critical: i64,
    pub high: i64,
    pub medium: i64,
    pub low: i64,
}

#[derive(Debug, Serialize)]
pub struct TypeCount {
    pub fraud_type: String,
    pub count: i64,
    pub percentage: f64,
}

#[derive(Debug, Serialize)]
pub struct SourceCount {
    pub source_ip: String,
    pub count: i64,
    pub carrier: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct TrendPoint {
    pub timestamp: DateTime<Utc>,
    pub count: i64,
}

#[derive(Debug, Deserialize)]
pub struct StatsQuery {
    pub period: Option<String>, // 1h, 6h, 24h, 7d, 30d
}

pub async fn get_alert_stats(
    State(state): State<AppState>,
    Query(params): Query<StatsQuery>,
) -> Result<Json<AlertStats>, (StatusCode, Json<ApiError>)> {
    let period = params.period.as_deref().unwrap_or("24h");
    let duration = match period {
        "1h" => Duration::hours(1),
        "6h" => Duration::hours(6),
        "24h" => Duration::hours(24),
        "7d" => Duration::days(7),
        "30d" => Duration::days(30),
        _ => Duration::hours(24),
    };

    let from = Utc::now() - duration;

    match state.yugabyte.get_alert_stats(from).await {
        Ok(stats) => Ok(Json(stats)),
        Err(e) => {
            tracing::error!("Failed to get alert stats: {}", e);
            Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new("alert_error", e.to_string())),
            ))
        }
    }
}

/// Get recent alerts for dashboard
pub async fn get_recent_alerts(
    State(state): State<AppState>,
) -> Result<Json<Vec<FraudAlert>>, (StatusCode, Json<ApiError>)> {
    match state.yugabyte.get_recent_alerts(20).await {
        Ok(alerts) => Ok(Json(alerts)),
        Err(e) => {
            tracing::error!("Failed to get recent alerts: {}", e);
            Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new("alert_error", e.to_string())),
            ))
        }
    }
}

/// Get alerts by call ID
pub async fn get_alerts_by_call(
    State(state): State<AppState>,
    Path(call_id): Path<String>,
) -> Result<Json<Vec<FraudAlert>>, (StatusCode, Json<ApiError>)> {
    match state.yugabyte.get_alerts_by_call(&call_id).await {
        Ok(alerts) => Ok(Json(alerts)),
        Err(e) => {
            tracing::error!("Failed to get alerts by call: {}", e);
            Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new("alert_error", e.to_string())),
            ))
        }
    }
}

/// Export alerts to CSV
#[derive(Debug, Deserialize)]
pub struct ExportQuery {
    pub from: DateTime<Utc>,
    pub to: DateTime<Utc>,
    pub format: Option<String>, // csv, json
}

pub async fn export_alerts(
    State(state): State<AppState>,
    Query(params): Query<ExportQuery>,
) -> Result<axum::response::Response, (StatusCode, Json<ApiError>)> {
    let format = params.format.as_deref().unwrap_or("csv");
    
    match state.yugabyte.export_alerts(params.from, params.to).await {
        Ok(alerts) => {
            match format {
                "json" => {
                    let json = serde_json::to_string_pretty(&alerts)
                        .map_err(|e| (
                            StatusCode::INTERNAL_SERVER_ERROR,
                            Json(ApiError::new("export_error", e.to_string())),
                        ))?;
                    
                    Ok(axum::response::Response::builder()
                        .status(StatusCode::OK)
                        .header("Content-Type", "application/json")
                        .header("Content-Disposition", "attachment; filename=fraud_alerts.json")
                        .body(axum::body::Body::from(json))
                        .unwrap())
                }
                _ => {
                    // CSV format
                    let mut csv = String::from("id,call_id,fraud_type,source_ip,caller_id,called_number,confidence,severity,action,reasons,timestamp,ncc_reported\n");
                    for alert in alerts {
                        csv.push_str(&format!(
                            "{},{},{},{},{},{},{},{},{},{},{},{}\n",
                            alert.id,
                            alert.call_id,
                            alert.fraud_type,
                            alert.source_ip,
                            alert.caller_id,
                            alert.called_number,
                            alert.confidence,
                            alert.severity,
                            alert.action,
                            alert.reasons.replace(',', ";"),
                            alert.timestamp,
                            alert.ncc_reported,
                        ));
                    }
                    
                    Ok(axum::response::Response::builder()
                        .status(StatusCode::OK)
                        .header("Content-Type", "text/csv")
                        .header("Content-Disposition", "attachment; filename=fraud_alerts.csv")
                        .body(axum::body::Body::from(csv))
                        .unwrap())
                }
            }
        }
        Err(e) => {
            tracing::error!("Failed to export alerts: {}", e);
            Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new("export_error", e.to_string())),
            ))
        }
    }
}

/// Report alert to NCC (manual trigger)
pub async fn report_to_ncc(
    State(state): State<AppState>,
    Path(id): Path<uuid::Uuid>,
) -> Result<Json<serde_json::Value>, (StatusCode, Json<ApiError>)> {
    // Get alert
    let alert = match state.yugabyte.get_alert(id).await {
        Ok(Some(a)) => a,
        Ok(None) => {
            return Err((
                StatusCode::NOT_FOUND,
                Json(ApiError::new("not_found", "Alert not found")),
            ));
        }
        Err(e) => {
            return Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new("alert_error", e.to_string())),
            ));
        }
    };

    if alert.ncc_reported {
        return Err((
            StatusCode::CONFLICT,
            Json(ApiError::new("already_reported", "Alert already reported to NCC")),
        ));
    }

    // Report to NCC
    match state.ncc_reporter.report_fraud(&alert).await {
        Ok(_) => {
            // Mark as reported
            let _ = state.yugabyte.mark_alert_reported(id).await;
            
            tracing::info!(alert_id = %id, "Alert reported to NCC");
            Ok(Json(serde_json::json!({
                "success": true,
                "alert_id": id,
                "message": "Alert reported to NCC successfully"
            })))
        }
        Err(e) => {
            tracing::error!("Failed to report alert to NCC: {}", e);
            Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new("ncc_report_failed", e.to_string())),
            ))
        }
    }
}
