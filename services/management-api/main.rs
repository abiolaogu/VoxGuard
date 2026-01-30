//! ACM Detection Engine - Main Entry Point
//!
//! Starts the high-performance anti-call masking detection service.

use acm_detection::{
    config::AppConfig,
    detection::DetectionEngine,
    cache::CacheManager,
    db::{YugabyteClient, ClickHouseClient},
    reporting::NccReporter,
    metrics::Metrics,
    handlers,
    AppState, SlidingWindow,
};

use axum::{
    routing::{get, post},
    Router,
};
use std::sync::Arc;
use tokio::sync::RwLock;
use tower_http::{
    cors::{Any, CorsLayer},
    trace::TraceLayer,
    compression::CompressionLayer,
};
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // Initialize tracing
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "acm_detection=info,tower_http=debug".into()),
        )
        .with(tracing_subscriber::fmt::layer().json())
        .init();

    tracing::info!("🛡️ Starting ACM Detection Engine v1.0.0");

    // Load configuration
    let config = AppConfig::load()?;
    tracing::info!(
        "Loaded configuration for region: {}",
        config.region
    );

    // Initialize metrics
    let metrics = Arc::new(Metrics::new());
    tracing::info!("Metrics collector initialized");

    // Initialize cache manager (DragonflyDB)
    let cache = Arc::new(CacheManager::new(&config.dragonfly_url).await?);
    tracing::info!("Connected to DragonflyDB: {}", config.dragonfly_url);

    // Initialize YugabyteDB client
    let yugabyte = Arc::new(YugabyteClient::new(&config.yugabyte_url).await?);
    tracing::info!("Connected to YugabyteDB");

    // Initialize ClickHouse client
    let clickhouse = Arc::new(ClickHouseClient::new(&config.clickhouse_url).await?);
    tracing::info!("Connected to ClickHouse");

    // Initialize NCC reporter
    let ncc_reporter = Arc::new(NccReporter::new(&config)?);
    tracing::info!("NCC reporter initialized");

    // Initialize detection engine
    let detection_engine = Arc::new(DetectionEngine::new(
        Arc::clone(&cache),
        Arc::clone(&yugabyte),
        config.clone(),
    )?);
    tracing::info!("Detection engine initialized");

    // Initialize sliding window for behavioral analysis
    let sliding_window = Arc::new(RwLock::new(SlidingWindow::new(300))); // 5-minute window

    // Create application state
    let state = AppState {
        config: Arc::new(config.clone()),
        detection_engine,
        cache,
        yugabyte,
        clickhouse,
        ncc_reporter,
        metrics,
        sliding_window,
    };

    // Start background tasks
    start_background_tasks(state.clone());

    // Build router
    let app = build_router(state);

    // Start server
    let listener = tokio::net::TcpListener::bind(&config.listen_addr).await?;
    tracing::info!("🚀 ACM Detection Engine listening on {}", config.listen_addr);

    axum::serve(listener, app)
        .with_graceful_shutdown(shutdown_signal())
        .await?;

    tracing::info!("ACM Detection Engine shut down gracefully");
    Ok(())
}

fn build_router(state: AppState) -> Router {
    Router::new()
        // Health endpoints
        .route("/health", get(handlers::health::health_check))
        .route("/ready", get(handlers::health::readiness_check))
        
        // Detection endpoints
        .route("/detect", post(handlers::detection::detect_fraud))
        .route("/detect/batch", post(handlers::detection::detect_batch))
        
        // MNP endpoints
        .route("/mnp/lookup", get(handlers::mnp::lookup_mnp))
        .route("/mnp/lookup/:msisdn", get(handlers::mnp::lookup_mnp_single))
        .route("/mnp/bulk", post(handlers::mnp::bulk_lookup))
        
        // Blacklist management
        .route("/blacklist", get(handlers::blacklist::list_blacklist))
        .route("/blacklist", post(handlers::blacklist::add_to_blacklist))
        .route("/blacklist/:ip", axum::routing::delete(handlers::blacklist::remove_from_blacklist))
        .route("/blacklist/sync", post(handlers::blacklist::sync_ncc_blacklist))
        
        // Gateway profiles
        .route("/gateways", get(handlers::gateway::list_gateways))
        .route("/gateways", post(handlers::gateway::create_gateway))
        .route("/gateways/:id", get(handlers::gateway::get_gateway))
        .route("/gateways/:id", axum::routing::put(handlers::gateway::update_gateway))
        
        // Fraud alerts
        .route("/alerts", get(handlers::alerts::list_alerts))
        .route("/alerts/:id/acknowledge", post(handlers::alerts::acknowledge_alert))
        
        // Metrics endpoint (Prometheus)
        .route("/metrics", get(handlers::metrics::prometheus_metrics))
        
        // WebSocket for real-time alerts
        .route("/ws/alerts", get(handlers::websocket::alerts_stream))
        
        // Apply state and middleware
        .with_state(state)
        .layer(TraceLayer::new_for_http())
        .layer(CompressionLayer::new())
        .layer(
            CorsLayer::new()
                .allow_origin(Any)
                .allow_methods(Any)
                .allow_headers(Any),
        )
}

fn start_background_tasks(state: AppState) {
    // Task 1: Sliding window cleanup (every 30 seconds)
    {
        let state = state.clone();
        tokio::spawn(async move {
            let mut interval = tokio::time::interval(tokio::time::Duration::from_secs(30));
            loop {
                interval.tick().await;
                let window = state.sliding_window.read().await;
                window.cleanup();
                tracing::debug!("Sliding window cleanup completed");
            }
        });
    }

    // Task 2: Metrics push to ClickHouse (every 10 seconds)
    {
        let state = state.clone();
        tokio::spawn(async move {
            let mut interval = tokio::time::interval(tokio::time::Duration::from_secs(10));
            loop {
                interval.tick().await;
                if let Err(e) = state.clickhouse.flush_metrics(&state.metrics).await {
                    tracing::error!("Failed to flush metrics to ClickHouse: {}", e);
                }
            }
        });
    }

    // Task 3: NCC blacklist sync (every 5 minutes)
    {
        let state = state.clone();
        tokio::spawn(async move {
            let mut interval = tokio::time::interval(tokio::time::Duration::from_secs(300));
            loop {
                interval.tick().await;
                tracing::info!("Syncing NCC blacklist...");
                if let Err(e) = state.ncc_reporter.sync_blacklist(&state.yugabyte).await {
                    tracing::error!("Failed to sync NCC blacklist: {}", e);
                }
            }
        });
    }

    // Task 4: DragonflyDB replication lag monitoring (every 10 seconds)
    {
        let state = state.clone();
        tokio::spawn(async move {
            let mut interval = tokio::time::interval(tokio::time::Duration::from_secs(10));
            loop {
                interval.tick().await;
                match state.cache.check_replication_lag().await {
                    Ok(lag) => {
                        if lag > 1 {
                            tracing::warn!(
                                "DragonflyDB replication lag: {}s (threshold: 1s)",
                                lag
                            );
                        }
                        state.metrics.set_replication_lag(lag);
                    }
                    Err(e) => {
                        tracing::error!("Failed to check replication lag: {}", e);
                    }
                }
            }
        });
    }

    tracing::info!("Background tasks started");
}

async fn shutdown_signal() {
    let ctrl_c = async {
        tokio::signal::ctrl_c()
            .await
            .expect("Failed to install Ctrl+C handler");
    };

    #[cfg(unix)]
    let terminate = async {
        tokio::signal::unix::signal(tokio::signal::unix::SignalKind::terminate())
            .expect("Failed to install signal handler")
            .recv()
            .await;
    };

    #[cfg(not(unix))]
    let terminate = std::future::pending::<()>();

    tokio::select! {
        _ = ctrl_c => {},
        _ = terminate => {},
    }

    tracing::info!("Shutdown signal received, starting graceful shutdown");
}
