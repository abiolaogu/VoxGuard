//! Health check handlers

use crate::AppState;
use axum::{extract::State, http::StatusCode, Json};
use serde::Serialize;

#[derive(Serialize)]
pub struct HealthResponse {
    pub status: &'static str,
    pub version: &'static str,
    pub region: String,
    pub node_id: String,
}

#[derive(Serialize)]
pub struct ReadinessResponse {
    pub status: &'static str,
    pub cache: ComponentStatus,
    pub yugabyte: ComponentStatus,
    pub clickhouse: ComponentStatus,
}

#[derive(Serialize)]
pub struct ComponentStatus {
    pub healthy: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub latency_ms: Option<u64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub error: Option<String>,
}

/// Health check endpoint - always returns OK if the server is running
pub async fn health_check(State(state): State<AppState>) -> Json<HealthResponse> {
    Json(HealthResponse {
        status: "healthy",
        version: env!("CARGO_PKG_VERSION"),
        region: state.config.region.clone(),
        node_id: state.config.node_id.clone(),
    })
}

/// Readiness check - verifies all dependencies are accessible
pub async fn readiness_check(
    State(state): State<AppState>,
) -> Result<Json<ReadinessResponse>, (StatusCode, Json<ReadinessResponse>)> {
    let mut all_healthy = true;

    // Check cache (DragonflyDB)
    let cache_status = {
        let start = std::time::Instant::now();
        match state.cache.exists("__health_check__").await {
            Ok(_) => ComponentStatus {
                healthy: true,
                latency_ms: Some(start.elapsed().as_millis() as u64),
                error: None,
            },
            Err(e) => {
                all_healthy = false;
                ComponentStatus {
                    healthy: false,
                    latency_ms: None,
                    error: Some(e.to_string()),
                }
            }
        }
    };

    // Check YugabyteDB
    let yugabyte_status = {
        let start = std::time::Instant::now();
        match state.yugabyte.health_check().await {
            Ok(_) => ComponentStatus {
                healthy: true,
                latency_ms: Some(start.elapsed().as_millis() as u64),
                error: None,
            },
            Err(e) => {
                all_healthy = false;
                ComponentStatus {
                    healthy: false,
                    latency_ms: None,
                    error: Some(e.to_string()),
                }
            }
        }
    };

    // Check ClickHouse
    let clickhouse_status = {
        let start = std::time::Instant::now();
        match state.clickhouse.health_check().await {
            Ok(_) => ComponentStatus {
                healthy: true,
                latency_ms: Some(start.elapsed().as_millis() as u64),
                error: None,
            },
            Err(e) => {
                // ClickHouse is not critical for detection
                ComponentStatus {
                    healthy: false,
                    latency_ms: None,
                    error: Some(e.to_string()),
                }
            }
        }
    };

    let response = ReadinessResponse {
        status: if all_healthy { "ready" } else { "degraded" },
        cache: cache_status,
        yugabyte: yugabyte_status,
        clickhouse: clickhouse_status,
    };

    if all_healthy {
        Ok(Json(response))
    } else {
        // Return 503 if not ready, but still include the response body
        Err((StatusCode::SERVICE_UNAVAILABLE, Json(response)))
    }
}
