//! WebSocket handlers for real-time alerts and metrics streaming
//! Enables live dashboard updates and SOC monitoring

use crate::{AppState, models::FraudAlert};
use axum::{
    extract::{
        ws::{Message, WebSocket, WebSocketUpgrade},
        Query, State,
    },
    response::IntoResponse,
};
use futures_util::{SinkExt, StreamExt};
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use tokio::sync::broadcast;
use chrono::{DateTime, Utc};

/// WebSocket connection parameters
#[derive(Debug, Deserialize)]
pub struct WsQuery {
    /// Subscribe to specific alert severities (comma-separated: 1,2,3,4)
    pub severities: Option<String>,
    /// Subscribe to specific fraud types (comma-separated)
    pub fraud_types: Option<String>,
    /// Subscribe to specific regions
    pub regions: Option<String>,
    /// Receive metrics updates
    pub include_metrics: Option<bool>,
}

/// WebSocket message types
#[derive(Debug, Clone, Serialize)]
#[serde(tag = "type")]
pub enum WsMessage {
    #[serde(rename = "alert")]
    Alert(AlertMessage),
    #[serde(rename = "metrics")]
    Metrics(MetricsMessage),
    #[serde(rename = "status")]
    Status(StatusMessage),
    #[serde(rename = "heartbeat")]
    Heartbeat { timestamp: DateTime<Utc> },
}

#[derive(Debug, Clone, Serialize)]
pub struct AlertMessage {
    pub alert: FraudAlert,
    pub timestamp: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize)]
pub struct MetricsMessage {
    pub calls_per_second: f64,
    pub fraud_rate_percent: f64,
    pub avg_latency_us: u64,
    pub active_alerts: i64,
    pub timestamp: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize)]
pub struct StatusMessage {
    pub message: String,
    pub level: String, // info, warning, error
    pub timestamp: DateTime<Utc>,
}

/// WebSocket upgrade handler for alerts
pub async fn alerts_ws_handler(
    ws: WebSocketUpgrade,
    State(state): State<AppState>,
    Query(params): Query<WsQuery>,
) -> impl IntoResponse {
    let severities: Option<Vec<i32>> = params
        .severities
        .as_ref()
        .map(|s| s.split(',').filter_map(|v| v.parse().ok()).collect());
    
    let fraud_types: Option<Vec<String>> = params
        .fraud_types
        .as_ref()
        .map(|s| s.split(',').map(|v| v.to_string()).collect());

    let include_metrics = params.include_metrics.unwrap_or(false);

    ws.on_upgrade(move |socket| {
        handle_alerts_socket(socket, state, severities, fraud_types, include_metrics)
    })
}

/// Handle WebSocket connection for alerts
async fn handle_alerts_socket(
    socket: WebSocket,
    state: AppState,
    severities: Option<Vec<i32>>,
    fraud_types: Option<Vec<String>>,
    include_metrics: bool,
) {
    let (mut sender, mut receiver) = socket.split();
    
    // Subscribe to alert broadcast channel
    let mut alert_rx = state.alert_broadcaster.subscribe();
    let mut metrics_rx = if include_metrics {
        Some(state.metrics_broadcaster.subscribe())
    } else {
        None
    };

    // Send initial connection status
    let status = WsMessage::Status(StatusMessage {
        message: "Connected to ACM alert stream".to_string(),
        level: "info".to_string(),
        timestamp: Utc::now(),
    });
    
    if let Ok(json) = serde_json::to_string(&status) {
        let _ = sender.send(Message::Text(json.into())).await;
    }

    // Heartbeat interval
    let mut heartbeat_interval = tokio::time::interval(tokio::time::Duration::from_secs(30));

    loop {
        tokio::select! {
            // Handle incoming messages from client
            Some(msg) = receiver.next() => {
                match msg {
                    Ok(Message::Text(text)) => {
                        // Handle client commands (e.g., filter updates)
                        if let Ok(cmd) = serde_json::from_str::<ClientCommand>(&text) {
                            match cmd.command.as_str() {
                                "ping" => {
                                    let pong = WsMessage::Heartbeat { timestamp: Utc::now() };
                                    if let Ok(json) = serde_json::to_string(&pong) {
                                        let _ = sender.send(Message::Text(json.into())).await;
                                    }
                                }
                                "subscribe" => {
                                    // Handle subscription updates
                                    tracing::debug!("Client subscription update: {:?}", cmd.params);
                                }
                                _ => {}
                            }
                        }
                    }
                    Ok(Message::Close(_)) => {
                        tracing::debug!("WebSocket client disconnected");
                        break;
                    }
                    Err(e) => {
                        tracing::warn!("WebSocket error: {}", e);
                        break;
                    }
                    _ => {}
                }
            }
            
            // Handle alert broadcasts
            result = alert_rx.recv() => {
                match result {
                    Ok(alert) => {
                        // Apply filters
                        let should_send = match (&severities, &fraud_types) {
                            (Some(sevs), Some(types)) => {
                                sevs.contains(&alert.severity) && 
                                types.contains(&alert.fraud_type)
                            }
                            (Some(sevs), None) => sevs.contains(&alert.severity),
                            (None, Some(types)) => types.contains(&alert.fraud_type),
                            (None, None) => true,
                        };

                        if should_send {
                            let msg = WsMessage::Alert(AlertMessage {
                                alert,
                                timestamp: Utc::now(),
                            });
                            if let Ok(json) = serde_json::to_string(&msg) {
                                if sender.send(Message::Text(json.into())).await.is_err() {
                                    break;
                                }
                            }
                        }
                    }
                    Err(broadcast::error::RecvError::Lagged(n)) => {
                        tracing::warn!("WebSocket client lagged {} messages", n);
                    }
                    Err(broadcast::error::RecvError::Closed) => {
                        break;
                    }
                }
            }

            // Handle metrics broadcasts
            result = async {
                match &mut metrics_rx {
                    Some(rx) => rx.recv().await,
                    None => std::future::pending().await,
                }
            } => {
                if let Ok(metrics) = result {
                    let msg = WsMessage::Metrics(metrics);
                    if let Ok(json) = serde_json::to_string(&msg) {
                        if sender.send(Message::Text(json.into())).await.is_err() {
                            break;
                        }
                    }
                }
            }

            // Send heartbeat
            _ = heartbeat_interval.tick() => {
                let heartbeat = WsMessage::Heartbeat { timestamp: Utc::now() };
                if let Ok(json) = serde_json::to_string(&heartbeat) {
                    if sender.send(Message::Text(json.into())).await.is_err() {
                        break;
                    }
                }
            }
        }
    }

    tracing::debug!("WebSocket connection closed");
}

#[derive(Debug, Deserialize)]
struct ClientCommand {
    command: String,
    params: Option<serde_json::Value>,
}

/// Dedicated metrics WebSocket endpoint
pub async fn metrics_ws_handler(
    ws: WebSocketUpgrade,
    State(state): State<AppState>,
) -> impl IntoResponse {
    ws.on_upgrade(move |socket| handle_metrics_socket(socket, state))
}

/// Handle WebSocket connection for metrics only
async fn handle_metrics_socket(socket: WebSocket, state: AppState) {
    let (mut sender, mut receiver) = socket.split();
    let mut metrics_rx = state.metrics_broadcaster.subscribe();
    let mut heartbeat_interval = tokio::time::interval(tokio::time::Duration::from_secs(30));

    loop {
        tokio::select! {
            Some(msg) = receiver.next() => {
                match msg {
                    Ok(Message::Close(_)) => break,
                    Err(_) => break,
                    _ => {}
                }
            }
            
            result = metrics_rx.recv() => {
                if let Ok(metrics) = result {
                    let msg = WsMessage::Metrics(metrics);
                    if let Ok(json) = serde_json::to_string(&msg) {
                        if sender.send(Message::Text(json.into())).await.is_err() {
                            break;
                        }
                    }
                }
            }

            _ = heartbeat_interval.tick() => {
                let heartbeat = WsMessage::Heartbeat { timestamp: Utc::now() };
                if let Ok(json) = serde_json::to_string(&heartbeat) {
                    if sender.send(Message::Text(json.into())).await.is_err() {
                        break;
                    }
                }
            }
        }
    }
}

/// Call activity WebSocket for live call monitoring
#[derive(Debug, Clone, Serialize)]
pub struct CallActivityMessage {
    pub call_id: String,
    pub caller_id: String,
    pub called_number: String,
    pub source_ip: String,
    pub detection_result: DetectionSummary,
    pub timestamp: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize)]
pub struct DetectionSummary {
    pub is_fraud: bool,
    pub fraud_types: Vec<String>,
    pub confidence: f64,
    pub action: String,
    pub latency_us: u64,
}

pub async fn call_activity_ws_handler(
    ws: WebSocketUpgrade,
    State(state): State<AppState>,
) -> impl IntoResponse {
    ws.on_upgrade(move |socket| handle_call_activity_socket(socket, state))
}

async fn handle_call_activity_socket(socket: WebSocket, state: AppState) {
    let (mut sender, mut receiver) = socket.split();
    let mut activity_rx = state.call_activity_broadcaster.subscribe();
    let mut heartbeat_interval = tokio::time::interval(tokio::time::Duration::from_secs(30));

    // Rate limit to prevent overwhelming the client
    let mut last_send = std::time::Instant::now();
    let min_interval = std::time::Duration::from_millis(50); // Max 20 msgs/sec

    loop {
        tokio::select! {
            Some(msg) = receiver.next() => {
                match msg {
                    Ok(Message::Close(_)) => break,
                    Err(_) => break,
                    _ => {}
                }
            }
            
            result = activity_rx.recv() => {
                if let Ok(activity) = result {
                    // Rate limiting
                    if last_send.elapsed() >= min_interval {
                        if let Ok(json) = serde_json::to_string(&activity) {
                            if sender.send(Message::Text(json.into())).await.is_err() {
                                break;
                            }
                            last_send = std::time::Instant::now();
                        }
                    }
                }
            }

            _ = heartbeat_interval.tick() => {
                let heartbeat = WsMessage::Heartbeat { timestamp: Utc::now() };
                if let Ok(json) = serde_json::to_string(&heartbeat) {
                    if sender.send(Message::Text(json.into())).await.is_err() {
                        break;
                    }
                }
            }
        }
    }
}

/// Regional status WebSocket for geo-distributed monitoring
#[derive(Debug, Clone, Serialize)]
pub struct RegionalStatusMessage {
    pub regions: Vec<RegionStatus>,
    pub timestamp: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize)]
pub struct RegionStatus {
    pub region: String,
    pub node_count: i32,
    pub active_nodes: i32,
    pub replication_lag_ms: u64,
    pub calls_per_second: f64,
    pub fraud_rate: f64,
    pub status: String,
}

pub async fn regional_status_ws_handler(
    ws: WebSocketUpgrade,
    State(state): State<AppState>,
) -> impl IntoResponse {
    ws.on_upgrade(move |socket| handle_regional_status_socket(socket, state))
}

async fn handle_regional_status_socket(socket: WebSocket, state: AppState) {
    let (mut sender, mut receiver) = socket.split();
    let mut status_rx = state.regional_status_broadcaster.subscribe();
    let mut heartbeat_interval = tokio::time::interval(tokio::time::Duration::from_secs(30));

    loop {
        tokio::select! {
            Some(msg) = receiver.next() => {
                match msg {
                    Ok(Message::Close(_)) => break,
                    Err(_) => break,
                    _ => {}
                }
            }
            
            result = status_rx.recv() => {
                if let Ok(status) = result {
                    if let Ok(json) = serde_json::to_string(&status) {
                        if sender.send(Message::Text(json.into())).await.is_err() {
                            break;
                        }
                    }
                }
            }

            _ = heartbeat_interval.tick() => {
                let heartbeat = WsMessage::Heartbeat { timestamp: Utc::now() };
                if let Ok(json) = serde_json::to_string(&heartbeat) {
                    if sender.send(Message::Text(json.into())).await.is_err() {
                        break;
                    }
                }
            }
        }
    }
}

/// Broadcast helper functions for the AppState
impl AppState {
    /// Broadcast a new fraud alert to all connected WebSocket clients
    pub fn broadcast_alert(&self, alert: FraudAlert) {
        let _ = self.alert_broadcaster.send(alert);
    }

    /// Broadcast metrics update to all connected WebSocket clients
    pub fn broadcast_metrics(&self, metrics: MetricsMessage) {
        let _ = self.metrics_broadcaster.send(metrics);
    }

    /// Broadcast call activity to all connected WebSocket clients
    pub fn broadcast_call_activity(&self, activity: CallActivityMessage) {
        let _ = self.call_activity_broadcaster.send(activity);
    }

    /// Broadcast regional status update
    pub fn broadcast_regional_status(&self, status: RegionalStatusMessage) {
        let _ = self.regional_status_broadcaster.send(status);
    }
}
