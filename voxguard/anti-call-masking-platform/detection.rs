//! Detection handlers for fraud analysis

use crate::{
    models::{ApiError, BatchDetectionRequest, BatchDetectionResponse, CallEvent, FraudAlert},
    detection::{DetectionResult, FraudType},
    AppState,
};
use axum::{extract::State, http::StatusCode, Json};
use std::sync::Arc;

/// Single call fraud detection endpoint
pub async fn detect_fraud(
    State(state): State<AppState>,
    Json(event): Json<CallEvent>,
) -> Result<Json<DetectionResult>, (StatusCode, Json<ApiError>)> {
    let start = std::time::Instant::now();

    // Record the call in sliding window
    {
        let window = state.sliding_window.read().await;
        window.record_call(&event.caller_id, &event.called_number);
    }

    // Run detection
    match state.detection_engine.detect(&event).await {
        Ok(result) => {
            // Update metrics
            state.metrics.record_detection(result.latency_us, result.is_fraud);

            // If fraud detected, save alert and report to NCC
            if result.is_fraud {
                let alert = FraudAlert::new(
                    &event.call_id,
                    result.fraud_types.first().map(|f| f.ncc_event_code()).unwrap_or("UNKNOWN"),
                    &event.source_ip,
                    &event.caller_id,
                    &event.called_number,
                    result.confidence,
                    result.fraud_types.first().map(|f| f.severity()).unwrap_or(1),
                    format!("{:?}", result.action),
                    result.reasons.join("; "),
                );

                // Save asynchronously
                let yugabyte = Arc::clone(&state.yugabyte);
                let ncc = Arc::clone(&state.ncc_reporter);
                let alert_clone = alert.clone();
                tokio::spawn(async move {
                    if let Err(e) = yugabyte.save_fraud_alert(&alert_clone).await {
                        tracing::error!("Failed to save fraud alert: {}", e);
                    }
                    if let Err(e) = ncc.report_fraud(&alert_clone).await {
                        tracing::error!("Failed to report fraud to NCC: {}", e);
                    }
                });
            }

            tracing::info!(
                call_id = %event.call_id,
                fraud = result.is_fraud,
                latency_us = result.latency_us,
                "Detection completed"
            );

            Ok(Json(result))
        }
        Err(e) => {
            tracing::error!("Detection failed: {}", e);
            Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new("detection_error", e.to_string())),
            ))
        }
    }
}

/// Batch detection endpoint for multiple calls
pub async fn detect_batch(
    State(state): State<AppState>,
    Json(request): Json<BatchDetectionRequest>,
) -> Result<Json<BatchDetectionResponse>, (StatusCode, Json<ApiError>)> {
    let start = std::time::Instant::now();
    let total = request.events.len();
    
    if total > 1000 {
        return Err((
            StatusCode::BAD_REQUEST,
            Json(ApiError::new("batch_too_large", "Maximum 1000 events per batch")),
        ));
    }

    let mut results = Vec::with_capacity(total);
    let mut fraud_count = 0;

    for event in request.events {
        match state.detection_engine.detect(&event).await {
            Ok(result) => {
                if result.is_fraud {
                    fraud_count += 1;
                }
                results.push(result);
            }
            Err(e) => {
                tracing::warn!("Detection failed for call {}: {}", event.call_id, e);
                // Create a "failed" result
                results.push(DetectionResult {
                    id: uuid::Uuid::new_v4(),
                    call_id: event.call_id,
                    is_fraud: false,
                    fraud_types: vec![],
                    confidence: 0.0,
                    action: crate::detection::DetectionAction::Allow,
                    latency_us: 0,
                    timestamp: chrono::Utc::now(),
                    mnp_result: None,
                    reasons: vec![format!("Detection error: {}", e)],
                });
            }
        }
    }

    let processing_time_ms = start.elapsed().as_millis() as u64;

    tracing::info!(
        total = total,
        fraud_count = fraud_count,
        processing_time_ms = processing_time_ms,
        "Batch detection completed"
    );

    Ok(Json(BatchDetectionResponse {
        results,
        total,
        fraud_count,
        processing_time_ms,
    }))
}
