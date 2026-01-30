//! Blacklist management handlers
//! Manages NCC blacklist and local blacklist for fraudulent IPs/numbers

use crate::{
    models::{ApiError, BlacklistEntry, BlacklistAddRequest, BlacklistSyncResponse},
    AppState,
};
use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    Json,
};
use serde::{Deserialize, Serialize};
use std::net::IpAddr;
use chrono::{DateTime, Utc};

#[derive(Debug, Deserialize)]
pub struct BlacklistQuery {
    pub group: Option<i32>,
    pub tag: Option<String>,
    pub limit: Option<i32>,
    pub offset: Option<i32>,
}

#[derive(Debug, Serialize)]
pub struct BlacklistListResponse {
    pub entries: Vec<BlacklistEntry>,
    pub total: i64,
    pub limit: i32,
    pub offset: i32,
}

/// List all blacklisted entries
pub async fn list_blacklist(
    State(state): State<AppState>,
    Query(params): Query<BlacklistQuery>,
) -> Result<Json<BlacklistListResponse>, (StatusCode, Json<ApiError>)> {
    let limit = params.limit.unwrap_or(100).min(1000);
    let offset = params.offset.unwrap_or(0);
    
    match state.yugabyte.list_blacklist(params.group, params.tag.as_deref(), limit, offset).await {
        Ok((entries, total)) => {
            Ok(Json(BlacklistListResponse {
                entries,
                total,
                limit,
                offset,
            }))
        }
        Err(e) => {
            tracing::error!("Failed to list blacklist: {}", e);
            Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new("blacklist_error", e.to_string())),
            ))
        }
    }
}

/// Add IP to blacklist
pub async fn add_to_blacklist(
    State(state): State<AppState>,
    Json(request): Json<BlacklistAddRequest>,
) -> Result<Json<BlacklistEntry>, (StatusCode, Json<ApiError>)> {
    // Validate IP address
    if request.ip.parse::<IpAddr>().is_err() && !request.ip.contains('/') {
        return Err((
            StatusCode::BAD_REQUEST,
            Json(ApiError::new("invalid_ip", "Invalid IP address or CIDR format")),
        ));
    }

    let entry = BlacklistEntry {
        id: 0,
        grp: request.grp.unwrap_or(66), // 66 = NCC Blacklist group
        ip: request.ip.clone(),
        mask: request.mask.unwrap_or(32),
        port: request.port.unwrap_or(0),
        proto: request.proto.clone().unwrap_or_else(|| "any".to_string()),
        pattern: request.pattern.clone(),
        tag: request.tag.clone().unwrap_or_else(|| "MANUAL".to_string()),
        reason: request.reason.clone(),
        added_by: request.added_by.clone().unwrap_or_else(|| "system".to_string()),
        added_at: Utc::now(),
        expires_at: request.expires_at,
    };

    match state.yugabyte.add_to_blacklist(&entry).await {
        Ok(entry) => {
            // Also add to DragonflyDB cache for fast lookups
            if let Err(e) = state.cache.add_to_blacklist(&entry.ip, entry.grp).await {
                tracing::warn!("Failed to add to cache blacklist: {}", e);
            }
            
            tracing::info!(ip = %entry.ip, tag = %entry.tag, "Added IP to blacklist");
            Ok(Json(entry))
        }
        Err(e) => {
            tracing::error!("Failed to add to blacklist: {}", e);
            Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new("blacklist_error", e.to_string())),
            ))
        }
    }
}

/// Remove IP from blacklist
pub async fn remove_from_blacklist(
    State(state): State<AppState>,
    Path(ip): Path<String>,
) -> Result<Json<serde_json::Value>, (StatusCode, Json<ApiError>)> {
    match state.yugabyte.remove_from_blacklist(&ip).await {
        Ok(removed) => {
            if removed {
                // Also remove from cache
                let _ = state.cache.remove_from_blacklist(&ip).await;
                tracing::info!(ip = %ip, "Removed IP from blacklist");
                Ok(Json(serde_json::json!({
                    "success": true,
                    "ip": ip,
                    "message": "IP removed from blacklist"
                })))
            } else {
                Err((
                    StatusCode::NOT_FOUND,
                    Json(ApiError::new("not_found", "IP not found in blacklist")),
                ))
            }
        }
        Err(e) => {
            tracing::error!("Failed to remove from blacklist: {}", e);
            Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new("blacklist_error", e.to_string())),
            ))
        }
    }
}

/// Sync blacklist from NCC API
pub async fn sync_ncc_blacklist(
    State(state): State<AppState>,
) -> Result<Json<BlacklistSyncResponse>, (StatusCode, Json<ApiError>)> {
    tracing::info!("Starting NCC blacklist sync");
    let start = std::time::Instant::now();

    match state.ncc_reporter.fetch_blacklist().await {
        Ok(entries) => {
            let total_fetched = entries.len();
            let mut added = 0;
            let mut updated = 0;
            let mut errors = 0;

            for entry in entries {
                match state.yugabyte.upsert_blacklist(&entry).await {
                    Ok(was_new) => {
                        if was_new {
                            added += 1;
                        } else {
                            updated += 1;
                        }
                        // Update cache
                        let _ = state.cache.add_to_blacklist(&entry.ip, entry.grp).await;
                    }
                    Err(e) => {
                        tracing::warn!("Failed to upsert blacklist entry {}: {}", entry.ip, e);
                        errors += 1;
                    }
                }
            }

            let duration_ms = start.elapsed().as_millis() as u64;
            
            tracing::info!(
                total_fetched,
                added,
                updated,
                errors,
                duration_ms,
                "NCC blacklist sync completed"
            );

            Ok(Json(BlacklistSyncResponse {
                success: errors == 0,
                total_fetched,
                added,
                updated,
                errors,
                duration_ms,
                synced_at: Utc::now(),
            }))
        }
        Err(e) => {
            tracing::error!("Failed to fetch NCC blacklist: {}", e);
            Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new("ncc_sync_failed", e.to_string())),
            ))
        }
    }
}

/// Check if an IP is blacklisted
pub async fn check_ip(
    State(state): State<AppState>,
    Path(ip): Path<String>,
) -> Result<Json<IpCheckResponse>, (StatusCode, Json<ApiError>)> {
    // Check cache first
    let cached = state.cache.is_blacklisted(&ip).await.unwrap_or(false);
    
    if cached {
        return Ok(Json(IpCheckResponse {
            ip: ip.clone(),
            blacklisted: true,
            source: "cache".to_string(),
            entry: None,
        }));
    }

    // Check database
    match state.yugabyte.check_blacklist(&ip).await {
        Ok(Some(entry)) => {
            // Add to cache for future lookups
            let _ = state.cache.add_to_blacklist(&ip, entry.grp).await;
            Ok(Json(IpCheckResponse {
                ip,
                blacklisted: true,
                source: "database".to_string(),
                entry: Some(entry),
            }))
        }
        Ok(None) => {
            Ok(Json(IpCheckResponse {
                ip,
                blacklisted: false,
                source: "database".to_string(),
                entry: None,
            }))
        }
        Err(e) => {
            tracing::error!("Failed to check blacklist: {}", e);
            Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new("blacklist_error", e.to_string())),
            ))
        }
    }
}

#[derive(Debug, Serialize)]
pub struct IpCheckResponse {
    pub ip: String,
    pub blacklisted: bool,
    pub source: String,
    pub entry: Option<BlacklistEntry>,
}

/// Import blacklist from file (CSV format)
#[derive(Debug, Deserialize)]
pub struct ImportRequest {
    pub entries: Vec<BlacklistImportEntry>,
    pub overwrite: Option<bool>,
}

#[derive(Debug, Deserialize)]
pub struct BlacklistImportEntry {
    pub ip: String,
    pub mask: Option<i32>,
    pub tag: Option<String>,
    pub reason: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct ImportResponse {
    pub success: bool,
    pub total: usize,
    pub imported: usize,
    pub skipped: usize,
    pub errors: Vec<String>,
}

pub async fn import_blacklist(
    State(state): State<AppState>,
    Json(request): Json<ImportRequest>,
) -> Result<Json<ImportResponse>, (StatusCode, Json<ApiError>)> {
    let total = request.entries.len();
    let mut imported = 0;
    let mut skipped = 0;
    let mut errors = Vec::new();

    for entry in request.entries {
        // Validate IP
        if entry.ip.parse::<IpAddr>().is_err() && !entry.ip.contains('/') {
            errors.push(format!("Invalid IP: {}", entry.ip));
            skipped += 1;
            continue;
        }

        let blacklist_entry = BlacklistEntry {
            id: 0,
            grp: 66,
            ip: entry.ip.clone(),
            mask: entry.mask.unwrap_or(32),
            port: 0,
            proto: "any".to_string(),
            pattern: None,
            tag: entry.tag.unwrap_or_else(|| "IMPORT".to_string()),
            reason: entry.reason,
            added_by: "import".to_string(),
            added_at: Utc::now(),
            expires_at: None,
        };

        match state.yugabyte.add_to_blacklist(&blacklist_entry).await {
            Ok(_) => {
                let _ = state.cache.add_to_blacklist(&entry.ip, 66).await;
                imported += 1;
            }
            Err(e) => {
                errors.push(format!("Failed to import {}: {}", entry.ip, e));
                skipped += 1;
            }
        }
    }

    tracing::info!(
        total,
        imported,
        skipped,
        error_count = errors.len(),
        "Blacklist import completed"
    );

    Ok(Json(ImportResponse {
        success: errors.is_empty(),
        total,
        imported,
        skipped,
        errors,
    }))
}
