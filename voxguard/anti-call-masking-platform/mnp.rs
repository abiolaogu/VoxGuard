//! Mobile Number Portability (MNP) lookup handlers
//! Implements proprietary MNP solution for Nigerian ICL

use crate::{
    models::{ApiError, MnpRecord, MnpLookupResponse, MnpBulkRequest, MnpBulkResponse},
    AppState,
};
use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    Json,
};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Debug, Deserialize)]
pub struct MnpLookupQuery {
    pub msisdn: String,
}

/// Single MNP lookup by query parameter
pub async fn lookup_mnp(
    State(state): State<AppState>,
    Query(params): Query<MnpLookupQuery>,
) -> Result<Json<MnpLookupResponse>, (StatusCode, Json<ApiError>)> {
    lookup_msisdn(&state, &params.msisdn).await
}

/// Single MNP lookup by path parameter
pub async fn lookup_mnp_path(
    State(state): State<AppState>,
    Path(msisdn): Path<String>,
) -> Result<Json<MnpLookupResponse>, (StatusCode, Json<ApiError>)> {
    lookup_msisdn(&state, &msisdn).await
}

/// Internal lookup function with L1 -> L2 -> L3 cache hierarchy
async fn lookup_msisdn(
    state: &AppState,
    msisdn: &str,
) -> Result<Json<MnpLookupResponse>, (StatusCode, Json<ApiError>)> {
    let start = std::time::Instant::now();
    let normalized = normalize_msisdn(msisdn);
    
    // L1: In-memory cache (sub-microsecond)
    if let Some(record) = state.mnp_cache.get(&normalized).await {
        let latency_us = start.elapsed().as_micros() as u64;
        tracing::debug!(msisdn = %normalized, latency_us, cache = "L1", "MNP lookup hit");
        return Ok(Json(MnpLookupResponse {
            msisdn: normalized,
            record: Some(record),
            ported: true,
            cache_level: "L1".to_string(),
            latency_us,
        }));
    }

    // L2: DragonflyDB regional cache (sub-millisecond)
    match state.cache.get_mnp(&normalized).await {
        Ok(Some(record)) => {
            // Store in L1 for future lookups
            state.mnp_cache.insert(normalized.clone(), record.clone()).await;
            let latency_us = start.elapsed().as_micros() as u64;
            tracing::debug!(msisdn = %normalized, latency_us, cache = "L2", "MNP lookup hit");
            return Ok(Json(MnpLookupResponse {
                msisdn: normalized,
                record: Some(record),
                ported: true,
                cache_level: "L2".to_string(),
                latency_us,
            }));
        }
        Ok(None) => {}
        Err(e) => {
            tracing::warn!("L2 cache lookup failed: {}", e);
        }
    }

    // L3: YugabyteDB master dataset (milliseconds)
    match state.yugabyte.get_mnp(&normalized).await {
        Ok(Some(record)) => {
            // Populate L1 and L2 caches
            state.mnp_cache.insert(normalized.clone(), record.clone()).await;
            if let Err(e) = state.cache.set_mnp(&normalized, &record).await {
                tracing::warn!("Failed to cache MNP record in L2: {}", e);
            }
            let latency_us = start.elapsed().as_micros() as u64;
            tracing::debug!(msisdn = %normalized, latency_us, cache = "L3", "MNP lookup hit");
            return Ok(Json(MnpLookupResponse {
                msisdn: normalized,
                record: Some(record),
                ported: true,
                cache_level: "L3".to_string(),
                latency_us,
            }));
        }
        Ok(None) => {
            // Not ported - use default routing based on prefix
            let latency_us = start.elapsed().as_micros() as u64;
            let default_record = get_default_routing(&normalized);
            tracing::debug!(msisdn = %normalized, latency_us, "MNP not found, using default routing");
            return Ok(Json(MnpLookupResponse {
                msisdn: normalized,
                record: default_record,
                ported: false,
                cache_level: "MISS".to_string(),
                latency_us,
            }));
        }
        Err(e) => {
            tracing::error!("L3 database lookup failed: {}", e);
            return Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new("mnp_lookup_failed", e.to_string())),
            ));
        }
    }
}

/// Bulk MNP lookup for batch processing
pub async fn lookup_mnp_bulk(
    State(state): State<AppState>,
    Json(request): Json<MnpBulkRequest>,
) -> Result<Json<MnpBulkResponse>, (StatusCode, Json<ApiError>)> {
    let start = std::time::Instant::now();
    
    if request.msisdns.len() > 1000 {
        return Err((
            StatusCode::BAD_REQUEST,
            Json(ApiError::new("batch_too_large", "Maximum 1000 MSISDNs per request")),
        ));
    }

    let mut results = HashMap::with_capacity(request.msisdns.len());
    let mut cache_stats = CacheStats::default();

    for msisdn in &request.msisdns {
        let normalized = normalize_msisdn(msisdn);
        
        // L1 check
        if let Some(record) = state.mnp_cache.get(&normalized).await {
            results.insert(normalized.clone(), Some(record));
            cache_stats.l1_hits += 1;
            continue;
        }

        // L2 check
        if let Ok(Some(record)) = state.cache.get_mnp(&normalized).await {
            state.mnp_cache.insert(normalized.clone(), record.clone()).await;
            results.insert(normalized.clone(), Some(record));
            cache_stats.l2_hits += 1;
            continue;
        }

        // L3 check
        if let Ok(Some(record)) = state.yugabyte.get_mnp(&normalized).await {
            state.mnp_cache.insert(normalized.clone(), record.clone()).await;
            let _ = state.cache.set_mnp(&normalized, &record).await;
            results.insert(normalized.clone(), Some(record));
            cache_stats.l3_hits += 1;
            continue;
        }

        results.insert(normalized, get_default_routing(msisdn));
        cache_stats.misses += 1;
    }

    let latency_ms = start.elapsed().as_millis() as u64;
    
    tracing::info!(
        total = request.msisdns.len(),
        l1_hits = cache_stats.l1_hits,
        l2_hits = cache_stats.l2_hits,
        l3_hits = cache_stats.l3_hits,
        misses = cache_stats.misses,
        latency_ms,
        "Bulk MNP lookup completed"
    );

    Ok(Json(MnpBulkResponse {
        results,
        total: request.msisdns.len(),
        cache_stats,
        latency_ms,
    }))
}

/// Normalize MSISDN to E.164 format (+234...)
fn normalize_msisdn(msisdn: &str) -> String {
    let cleaned: String = msisdn.chars().filter(|c| c.is_ascii_digit() || *c == '+').collect();
    
    if cleaned.starts_with("+234") {
        cleaned
    } else if cleaned.starts_with("234") {
        format!("+{}", cleaned)
    } else if cleaned.starts_with("0") {
        format!("+234{}", &cleaned[1..])
    } else {
        format!("+234{}", cleaned)
    }
}

/// Get default routing based on Nigerian MNO prefix assignments (2026)
fn get_default_routing(msisdn: &str) -> Option<MnpRecord> {
    let normalized = normalize_msisdn(msisdn);
    let prefix = if normalized.len() >= 7 { &normalized[..7] } else { return None };
    
    let (network_id, routing_number) = match prefix {
        // MTN Nigeria
        p if p.starts_with("+234703") || p.starts_with("+234706") || 
             p.starts_with("+234803") || p.starts_with("+234806") ||
             p.starts_with("+234810") || p.starts_with("+234813") ||
             p.starts_with("+234814") || p.starts_with("+234816") ||
             p.starts_with("+234903") || p.starts_with("+234906") ||
             p.starts_with("+234913") || p.starts_with("+234916") => ("MTN", "D013"),
        
        // Airtel Nigeria
        p if p.starts_with("+234701") || p.starts_with("+234708") ||
             p.starts_with("+234802") || p.starts_with("+234808") ||
             p.starts_with("+234812") || p.starts_with("+234901") ||
             p.starts_with("+234902") || p.starts_with("+234904") ||
             p.starts_with("+234907") || p.starts_with("+234912") => ("Airtel", "D018"),
        
        // Globacom (Glo)
        p if p.starts_with("+234705") || p.starts_with("+234805") ||
             p.starts_with("+234807") || p.starts_with("+234811") ||
             p.starts_with("+234815") || p.starts_with("+234905") ||
             p.starts_with("+234915") => ("Glo", "D015"),
        
        // 9mobile
        p if p.starts_with("+234809") || p.starts_with("+234817") ||
             p.starts_with("+234818") || p.starts_with("+234908") ||
             p.starts_with("+234909") => ("9mobile", "D019"),
        
        _ => return None,
    };

    Some(MnpRecord {
        msisdn: normalized,
        hosting_network_id: network_id.to_string(),
        routing_number: routing_number.to_string(),
        ported: false,
        original_network_id: Some(network_id.to_string()),
        port_date: None,
        last_updated: chrono::Utc::now(),
    })
}

#[derive(Debug, Default, Clone, Serialize, Deserialize)]
pub struct CacheStats {
    pub l1_hits: usize,
    pub l2_hits: usize,
    pub l3_hits: usize,
    pub misses: usize,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_normalize_msisdn() {
        assert_eq!(normalize_msisdn("+2348031234567"), "+2348031234567");
        assert_eq!(normalize_msisdn("2348031234567"), "+2348031234567");
        assert_eq!(normalize_msisdn("08031234567"), "+2348031234567");
        assert_eq!(normalize_msisdn("8031234567"), "+2348031234567");
    }

    #[test]
    fn test_default_routing() {
        let mtn = get_default_routing("+2348031234567").unwrap();
        assert_eq!(mtn.hosting_network_id, "MTN");
        assert_eq!(mtn.routing_number, "D013");

        let airtel = get_default_routing("+2348081234567").unwrap();
        assert_eq!(airtel.hosting_network_id, "Airtel");
        assert_eq!(airtel.routing_number, "D018");

        let glo = get_default_routing("+2348051234567").unwrap();
        assert_eq!(glo.hosting_network_id, "Glo");
        assert_eq!(glo.routing_number, "D015");

        let nine_mobile = get_default_routing("+2348091234567").unwrap();
        assert_eq!(nine_mobile.hosting_network_id, "9mobile");
        assert_eq!(nine_mobile.routing_number, "D019");
    }
}
