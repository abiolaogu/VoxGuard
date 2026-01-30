//! Anti-Call Masking Detection Service - Main Entry Point
//!
//! High-performance fraud detection engine with DDD architecture.
//! Handles 150K+ CPS with sub-millisecond detection latency.

use actix_web::{get, post, web, App, HttpResponse, HttpServer, Responder, middleware::Logger};
use std::sync::Arc;
use std::time::Instant;
use tracing::{info, Level};
use tracing_subscriber::FmtSubscriber;

// Import our DDD modules
mod domain;
mod application;
mod ports;
mod adapters;
mod config;
mod metrics;

use ports::DetectionCache;  // Needed for trait methods on Arc<DragonflyCache>

use application::commands::RegisterCallCommand;
use config::AppConfig;
use adapters::DragonflyCache;

/// Application state shared across handlers
struct AppState {
    config: AppConfig,
    cache: Arc<DragonflyCache>,
    region: String,
}

/// Health check endpoint
#[get("/health")]
async fn health(data: web::Data<AppState>) -> impl Responder {
    HttpResponse::Ok().json(serde_json::json!({
        "status": "healthy",
        "service": "ACM Detection Engine v2.0",
        "region": data.region,
        "architecture": "DDD/Hexagonal",
        "databases": {
            "cache": "DragonflyDB",
            "timeseries": "QuestDB",
            "persistent": "YugabyteDB",
            "analytics": "ClickHouse"
        }
    }))
}

/// Prometheus metrics endpoint
#[get("/metrics")]
async fn metrics_handler() -> impl Responder {
    HttpResponse::Ok()
        .content_type("text/plain; charset=utf-8")
        .body(metrics::get_metrics())
}

/// Call event handler - main detection endpoint
#[post("/event")]
async fn handle_event(
    event: web::Json<CallEventRequest>,
    data: web::Data<AppState>,
) -> impl Responder {
    let start = Instant::now();

    // Convert to command
    let cmd = RegisterCallCommand {
        call_id: event.call_id.clone(),
        a_number: event.a_number.clone(),
        b_number: event.b_number.clone(),
        source_ip: event.source_ip.clone().unwrap_or_else(|| "0.0.0.0".into()),
        switch_id: event.switch_id.clone(),
    };

    // Simplified inline detection (in production would use DetectionService)
    // Add caller to sliding window
    match data.cache.add_caller_to_window(
        &domain::value_objects::MSISDN::new(&cmd.b_number).unwrap(),
        &domain::value_objects::MSISDN::new(&cmd.a_number).unwrap(),
        data.config.detection.window.seconds(),
    ).await {
        Ok(_) => {}
        Err(e) => {
            return HttpResponse::InternalServerError().json(serde_json::json!({
                "error": format!("Cache error: {}", e)
            }));
        }
    }

    // Get distinct caller count
    let count = match data.cache.get_distinct_caller_count(
        &domain::value_objects::MSISDN::new(&cmd.b_number).unwrap(),
    ).await {
        Ok(c) => c,
        Err(e) => {
            return HttpResponse::InternalServerError().json(serde_json::json!({
                "error": format!("Cache error: {}", e)
            }));
        }
    };

    let latency = start.elapsed();
    metrics::record_latency(latency.as_secs_f64(), &data.region);

    // Check threshold
    if count >= data.config.detection.threshold.distinct_callers() {
        metrics::record_call("alert", &data.region);
        metrics::record_alert("MASKING_ATTACK", "Critical", &data.region);

        let alert = serde_json::json!({
            "alert_id": format!("ALERT-{}", chrono::Utc::now().timestamp_nanos_opt().unwrap_or(0)),
            "b_number": cmd.b_number,
            "call_count": count,
            "created_at": chrono::Utc::now().to_rfc3339(),
            "description": "Masking Attack Detected"
        });

        return HttpResponse::Ok().json(serde_json::json!({
            "status": "alert",
            "alert": alert,
            "latency_us": latency.as_micros()
        }));
    }

    metrics::record_call("processed", &data.region);

    HttpResponse::Ok().json(serde_json::json!({
        "status": "processed",
        "distinct_callers": count,
        "threshold": data.config.detection.threshold.distinct_callers(),
        "latency_us": latency.as_micros()
    }))
}

/// Call event request DTO
#[derive(serde::Deserialize)]
struct CallEventRequest {
    #[serde(default)]
    call_id: Option<String>,
    a_number: String,
    b_number: String,
    source_ip: Option<String>,
    switch_id: Option<String>,
    #[serde(default)]
    timestamp: Option<String>,
}

/// Alert acknowledgment DTO
#[derive(serde::Deserialize)]
struct AcknowledgeRequest {
    alert_id: String,
    user_id: String,
}

/// Acknowledge an alert
#[post("/alerts/{alert_id}/acknowledge")]
async fn acknowledge_alert(
    path: web::Path<String>,
    body: web::Json<AcknowledgeRequest>,
) -> impl Responder {
    let alert_id = path.into_inner();

    // Would use AlertService in production
    HttpResponse::Ok().json(serde_json::json!({
        "status": "acknowledged",
        "alert_id": alert_id,
        "acknowledged_by": body.user_id
    }))
}

/// Get threat level for a B-number
#[get("/threat/{b_number}")]
async fn get_threat_level(
    path: web::Path<String>,
    data: web::Data<AppState>,
) -> impl Responder {
    let b_number = path.into_inner();

    // Get current count from cache
    let count = match domain::value_objects::MSISDN::new(&b_number) {
        Ok(msisdn) => data.cache.get_distinct_caller_count(&msisdn).await.unwrap_or(0),
        Err(_) => return HttpResponse::BadRequest().json(serde_json::json!({
            "error": "Invalid B-number format"
        })),
    };

    let threshold = data.config.detection.threshold.distinct_callers();
    let level = if count >= threshold {
        "critical"
    } else if count >= threshold - 1 {
        "high"
    } else if count >= threshold - 2 {
        "medium"
    } else {
        "low"
    };

    HttpResponse::Ok().json(serde_json::json!({
        "b_number": b_number,
        "threat_level": level,
        "distinct_callers": count,
        "threshold": threshold,
        "requires_action": level == "critical" || level == "high"
    }))
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    // Initialize tracing
    let subscriber = FmtSubscriber::builder()
        .with_max_level(Level::INFO)
        .with_target(false)
        .json()
        .finish();
    tracing::subscriber::set_global_default(subscriber)
        .expect("Failed to set tracing subscriber");

    // Load configuration
    let config = AppConfig::from_env();

    info!(
        "Starting ACM Detection Engine v2.0",
    );
    info!(
        "Configuration: window={}s, threshold={}, region={}",
        config.detection.window.seconds(),
        config.detection.threshold.distinct_callers(),
        config.region
    );

    // Initialize cache adapter
    let cache = Arc::new(
        DragonflyCache::new(&config.dragonfly_url, config.dragonfly_pool_size)
            .expect("Failed to connect to DragonflyDB"),
    );

    let bind_addr = format!("{}:{}", config.host, config.port);
    let region = config.region.clone();

    let app_state = web::Data::new(AppState {
        config,
        cache,
        region,
    });

    info!("Listening on {}", bind_addr);

    HttpServer::new(move || {
        App::new()
            .app_data(app_state.clone())
            .wrap(Logger::default())
            .service(health)
            .service(metrics_handler)
            .service(handle_event)
            .service(acknowledge_alert)
            .service(get_threat_level)
    })
    .bind(&bind_addr)?
    .run()
    .await
}
