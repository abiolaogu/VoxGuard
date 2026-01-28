//! Gateway management handlers
//! Manages gateway profiles for CLI validation (International vs Local)

use crate::{
    models::{ApiError, GatewayProfile, GatewayCreateRequest, GatewayUpdateRequest},
    AppState,
};
use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    Json,
};
use serde::{Deserialize, Serialize};
use chrono::Utc;

/// Gateway groups as defined by NCC standards
pub mod gateway_groups {
    pub const TRUSTED_LOCAL: i32 = 1;      // Local MNOs (MTN, Airtel, Glo, 9mobile)
    pub const TRUSTED_INT: i32 = 5;        // Trusted international partners
    pub const INTERNATIONAL: i32 = 10;     // Standard international gateways
    pub const UNKNOWN: i32 = 50;           // Unknown/unverified sources
    pub const BLACKLISTED: i32 = 66;       // NCC blacklisted
    pub const HONEYPOT: i32 = 99;          // Redirect suspicious traffic
}

#[derive(Debug, Deserialize)]
pub struct GatewayQuery {
    pub group: Option<i32>,
    pub tag: Option<String>,
    pub active_only: Option<bool>,
    pub limit: Option<i32>,
    pub offset: Option<i32>,
}

#[derive(Debug, Serialize)]
pub struct GatewayListResponse {
    pub gateways: Vec<GatewayProfile>,
    pub total: i64,
    pub limit: i32,
    pub offset: i32,
}

/// List all gateway profiles
pub async fn list_gateways(
    State(state): State<AppState>,
    Query(params): Query<GatewayQuery>,
) -> Result<Json<GatewayListResponse>, (StatusCode, Json<ApiError>)> {
    let limit = params.limit.unwrap_or(100).min(1000);
    let offset = params.offset.unwrap_or(0);
    let active_only = params.active_only.unwrap_or(false);

    match state.yugabyte.list_gateways(params.group, params.tag.as_deref(), active_only, limit, offset).await {
        Ok((gateways, total)) => {
            Ok(Json(GatewayListResponse {
                gateways,
                total,
                limit,
                offset,
            }))
        }
        Err(e) => {
            tracing::error!("Failed to list gateways: {}", e);
            Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new("gateway_error", e.to_string())),
            ))
        }
    }
}

/// Get gateway by ID
pub async fn get_gateway(
    State(state): State<AppState>,
    Path(id): Path<i64>,
) -> Result<Json<GatewayProfile>, (StatusCode, Json<ApiError>)> {
    match state.yugabyte.get_gateway(id).await {
        Ok(Some(gateway)) => Ok(Json(gateway)),
        Ok(None) => {
            Err((
                StatusCode::NOT_FOUND,
                Json(ApiError::new("not_found", "Gateway not found")),
            ))
        }
        Err(e) => {
            tracing::error!("Failed to get gateway: {}", e);
            Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new("gateway_error", e.to_string())),
            ))
        }
    }
}

/// Create new gateway profile
pub async fn create_gateway(
    State(state): State<AppState>,
    Json(request): Json<GatewayCreateRequest>,
) -> Result<Json<GatewayProfile>, (StatusCode, Json<ApiError>)> {
    // Validate IP address or CIDR
    if !is_valid_ip_or_cidr(&request.ip) {
        return Err((
            StatusCode::BAD_REQUEST,
            Json(ApiError::new("invalid_ip", "Invalid IP address or CIDR format")),
        ));
    }

    // Validate group
    if !is_valid_group(request.grp) {
        return Err((
            StatusCode::BAD_REQUEST,
            Json(ApiError::new("invalid_group", "Invalid gateway group")),
        ));
    }

    let gateway = GatewayProfile {
        id: 0,
        grp: request.grp,
        ip: request.ip.clone(),
        mask: request.mask.unwrap_or(32),
        port: request.port.unwrap_or(5060),
        proto: request.proto.clone().unwrap_or_else(|| "udp".to_string()),
        pattern: request.pattern.clone(),
        tag: request.tag.clone(),
        description: request.description.clone(),
        carrier_name: request.carrier_name.clone(),
        carrier_code: request.carrier_code.clone(),
        country_code: request.country_code.clone(),
        is_active: request.is_active.unwrap_or(true),
        allow_local_cli: request.allow_local_cli.unwrap_or(false),
        max_cps: request.max_cps,
        created_at: Utc::now(),
        updated_at: Utc::now(),
    };

    match state.yugabyte.create_gateway(&gateway).await {
        Ok(created) => {
            // Update cache
            if let Err(e) = state.cache.set_gateway(&created.ip, &created).await {
                tracing::warn!("Failed to cache gateway: {}", e);
            }
            
            tracing::info!(
                id = created.id,
                ip = %created.ip,
                grp = created.grp,
                tag = ?created.tag,
                "Gateway created"
            );
            
            Ok(Json(created))
        }
        Err(e) => {
            tracing::error!("Failed to create gateway: {}", e);
            Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new("gateway_error", e.to_string())),
            ))
        }
    }
}

/// Update gateway profile
pub async fn update_gateway(
    State(state): State<AppState>,
    Path(id): Path<i64>,
    Json(request): Json<GatewayUpdateRequest>,
) -> Result<Json<GatewayProfile>, (StatusCode, Json<ApiError>)> {
    // Check if gateway exists
    let existing = match state.yugabyte.get_gateway(id).await {
        Ok(Some(gw)) => gw,
        Ok(None) => {
            return Err((
                StatusCode::NOT_FOUND,
                Json(ApiError::new("not_found", "Gateway not found")),
            ));
        }
        Err(e) => {
            return Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new("gateway_error", e.to_string())),
            ));
        }
    };

    // Build updated gateway
    let updated = GatewayProfile {
        id: existing.id,
        grp: request.grp.unwrap_or(existing.grp),
        ip: request.ip.clone().unwrap_or(existing.ip.clone()),
        mask: request.mask.unwrap_or(existing.mask),
        port: request.port.unwrap_or(existing.port),
        proto: request.proto.clone().unwrap_or(existing.proto),
        pattern: request.pattern.clone().or(existing.pattern),
        tag: request.tag.clone().or(existing.tag),
        description: request.description.clone().or(existing.description),
        carrier_name: request.carrier_name.clone().or(existing.carrier_name),
        carrier_code: request.carrier_code.clone().or(existing.carrier_code),
        country_code: request.country_code.clone().or(existing.country_code),
        is_active: request.is_active.unwrap_or(existing.is_active),
        allow_local_cli: request.allow_local_cli.unwrap_or(existing.allow_local_cli),
        max_cps: request.max_cps.or(existing.max_cps),
        created_at: existing.created_at,
        updated_at: Utc::now(),
    };

    match state.yugabyte.update_gateway(&updated).await {
        Ok(saved) => {
            // Update cache
            if let Err(e) = state.cache.set_gateway(&saved.ip, &saved).await {
                tracing::warn!("Failed to update gateway cache: {}", e);
            }
            
            tracing::info!(id = saved.id, ip = %saved.ip, "Gateway updated");
            Ok(Json(saved))
        }
        Err(e) => {
            tracing::error!("Failed to update gateway: {}", e);
            Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new("gateway_error", e.to_string())),
            ))
        }
    }
}

/// Delete gateway profile
pub async fn delete_gateway(
    State(state): State<AppState>,
    Path(id): Path<i64>,
) -> Result<Json<serde_json::Value>, (StatusCode, Json<ApiError>)> {
    // Get gateway first to get IP for cache invalidation
    let gateway = match state.yugabyte.get_gateway(id).await {
        Ok(Some(gw)) => gw,
        Ok(None) => {
            return Err((
                StatusCode::NOT_FOUND,
                Json(ApiError::new("not_found", "Gateway not found")),
            ));
        }
        Err(e) => {
            return Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new("gateway_error", e.to_string())),
            ));
        }
    };

    match state.yugabyte.delete_gateway(id).await {
        Ok(true) => {
            // Remove from cache
            let _ = state.cache.remove_gateway(&gateway.ip).await;
            
            tracing::info!(id = id, ip = %gateway.ip, "Gateway deleted");
            Ok(Json(serde_json::json!({
                "success": true,
                "id": id,
                "message": "Gateway deleted successfully"
            })))
        }
        Ok(false) => {
            Err((
                StatusCode::NOT_FOUND,
                Json(ApiError::new("not_found", "Gateway not found")),
            ))
        }
        Err(e) => {
            tracing::error!("Failed to delete gateway: {}", e);
            Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new("gateway_error", e.to_string())),
            ))
        }
    }
}

/// Get gateway by IP address
pub async fn get_gateway_by_ip(
    State(state): State<AppState>,
    Path(ip): Path<String>,
) -> Result<Json<GatewayProfile>, (StatusCode, Json<ApiError>)> {
    // Check cache first
    if let Ok(Some(gateway)) = state.cache.get_gateway(&ip).await {
        return Ok(Json(gateway));
    }

    // Check database
    match state.yugabyte.get_gateway_by_ip(&ip).await {
        Ok(Some(gateway)) => {
            // Cache for future lookups
            let _ = state.cache.set_gateway(&ip, &gateway).await;
            Ok(Json(gateway))
        }
        Ok(None) => {
            Err((
                StatusCode::NOT_FOUND,
                Json(ApiError::new("not_found", "Gateway not found")),
            ))
        }
        Err(e) => {
            tracing::error!("Failed to get gateway by IP: {}", e);
            Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new("gateway_error", e.to_string())),
            ))
        }
    }
}

/// Get gateway statistics
#[derive(Debug, Serialize)]
pub struct GatewayStats {
    pub id: i64,
    pub ip: String,
    pub tag: Option<String>,
    pub total_calls_24h: i64,
    pub fraud_detected_24h: i64,
    pub fraud_rate: f64,
    pub avg_cps: f64,
    pub peak_cps: f64,
    pub avg_duration_sec: f64,
}

pub async fn get_gateway_stats(
    State(state): State<AppState>,
    Path(id): Path<i64>,
) -> Result<Json<GatewayStats>, (StatusCode, Json<ApiError>)> {
    match state.yugabyte.get_gateway_stats(id).await {
        Ok(stats) => Ok(Json(stats)),
        Err(e) => {
            tracing::error!("Failed to get gateway stats: {}", e);
            Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new("gateway_error", e.to_string())),
            ))
        }
    }
}

/// Bulk import gateways
#[derive(Debug, Deserialize)]
pub struct BulkImportRequest {
    pub gateways: Vec<GatewayCreateRequest>,
}

#[derive(Debug, Serialize)]
pub struct BulkImportResponse {
    pub total: usize,
    pub imported: usize,
    pub errors: Vec<String>,
}

pub async fn bulk_import_gateways(
    State(state): State<AppState>,
    Json(request): Json<BulkImportRequest>,
) -> Result<Json<BulkImportResponse>, (StatusCode, Json<ApiError>)> {
    let total = request.gateways.len();
    let mut imported = 0;
    let mut errors = Vec::new();

    for gw_req in request.gateways {
        let gateway = GatewayProfile {
            id: 0,
            grp: gw_req.grp,
            ip: gw_req.ip.clone(),
            mask: gw_req.mask.unwrap_or(32),
            port: gw_req.port.unwrap_or(5060),
            proto: gw_req.proto.unwrap_or_else(|| "udp".to_string()),
            pattern: gw_req.pattern,
            tag: gw_req.tag,
            description: gw_req.description,
            carrier_name: gw_req.carrier_name,
            carrier_code: gw_req.carrier_code,
            country_code: gw_req.country_code,
            is_active: gw_req.is_active.unwrap_or(true),
            allow_local_cli: gw_req.allow_local_cli.unwrap_or(false),
            max_cps: gw_req.max_cps,
            created_at: Utc::now(),
            updated_at: Utc::now(),
        };

        match state.yugabyte.create_gateway(&gateway).await {
            Ok(created) => {
                let _ = state.cache.set_gateway(&created.ip, &created).await;
                imported += 1;
            }
            Err(e) => {
                errors.push(format!("Failed to import {}: {}", gw_req.ip, e));
            }
        }
    }

    tracing::info!(total, imported, error_count = errors.len(), "Bulk gateway import completed");

    Ok(Json(BulkImportResponse {
        total,
        imported,
        errors,
    }))
}

fn is_valid_ip_or_cidr(ip: &str) -> bool {
    use std::net::IpAddr;
    
    if let Some((addr, prefix)) = ip.split_once('/') {
        addr.parse::<IpAddr>().is_ok() && prefix.parse::<u8>().is_ok()
    } else {
        ip.parse::<IpAddr>().is_ok()
    }
}

fn is_valid_group(group: i32) -> bool {
    matches!(
        group,
        gateway_groups::TRUSTED_LOCAL
            | gateway_groups::TRUSTED_INT
            | gateway_groups::INTERNATIONAL
            | gateway_groups::UNKNOWN
            | gateway_groups::BLACKLISTED
            | gateway_groups::HONEYPOT
    )
}
