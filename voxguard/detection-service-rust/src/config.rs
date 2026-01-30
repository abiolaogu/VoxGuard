//! Configuration module

use std::env;

use crate::application::detection_service::DetectionConfig;
use crate::domain::value_objects::{DetectionThreshold, DetectionWindow};

/// Application configuration
#[derive(Debug, Clone)]
pub struct AppConfig {
    /// Server host
    pub host: String,
    /// Server port
    pub port: u16,
    /// Metrics port
    pub metrics_port: u16,

    /// DragonflyDB URL
    pub dragonfly_url: String,
    /// DragonflyDB pool size
    pub dragonfly_pool_size: usize,

    /// YugabyteDB URL
    pub yugabyte_url: String,

    /// QuestDB ILP host
    pub questdb_ilp_host: String,
    /// QuestDB ILP port
    pub questdb_ilp_port: u16,
    /// QuestDB PostgreSQL host
    pub questdb_pg_host: String,
    /// QuestDB PostgreSQL port
    pub questdb_pg_port: u16,

    /// ClickHouse URL
    pub clickhouse_url: String,

    /// Detection configuration
    pub detection: DetectionConfig,

    /// Region identifier
    pub region: String,
    /// Node identifier
    pub node_id: String,
}

impl AppConfig {
    /// Loads configuration from environment variables
    pub fn from_env() -> Self {
        dotenv::dotenv().ok();

        let window_seconds: u32 = env::var("DETECTION_WINDOW_SECONDS")
            .unwrap_or_else(|_| "5".into())
            .parse()
            .unwrap_or(5);

        let threshold: usize = env::var("DETECTION_THRESHOLD")
            .unwrap_or_else(|_| "5".into())
            .parse()
            .unwrap_or(5);

        let cooldown_seconds: u32 = env::var("COOLDOWN_SECONDS")
            .unwrap_or_else(|_| "60".into())
            .parse()
            .unwrap_or(60);

        let detection = DetectionConfig {
            window: DetectionWindow::new(window_seconds).unwrap_or_default(),
            threshold: DetectionThreshold::new(threshold).unwrap_or_default(),
            cooldown_seconds,
            auto_block_enabled: env::var("AUTO_BLOCK_ENABLED")
                .map(|v| v == "true" || v == "1")
                .unwrap_or(true),
        };

        Self {
            host: env::var("ACM_HOST").unwrap_or_else(|_| "0.0.0.0".into()),
            port: env::var("ACM_PORT")
                .unwrap_or_else(|_| "8080".into())
                .parse()
                .unwrap_or(8080),
            metrics_port: env::var("ACM_METRICS_PORT")
                .unwrap_or_else(|_| "9090".into())
                .parse()
                .unwrap_or(9090),

            dragonfly_url: env::var("DRAGONFLY_URL")
                .unwrap_or_else(|_| "redis://dragonfly:6379".into()),
            dragonfly_pool_size: env::var("DRAGONFLY_POOL_SIZE")
                .unwrap_or_else(|_| "32".into())
                .parse()
                .unwrap_or(32),

            yugabyte_url: env::var("YUGABYTE_URL")
                .unwrap_or_else(|_| "postgres://opensips:password@yugabyte:5433/opensips".into()),

            questdb_ilp_host: env::var("QUESTDB_ILP_HOST")
                .unwrap_or_else(|_| "questdb".into()),
            questdb_ilp_port: env::var("QUESTDB_ILP_PORT")
                .unwrap_or_else(|_| "9009".into())
                .parse()
                .unwrap_or(9009),
            questdb_pg_host: env::var("QUESTDB_PG_HOST")
                .unwrap_or_else(|_| "questdb".into()),
            questdb_pg_port: env::var("QUESTDB_PG_PORT")
                .unwrap_or_else(|_| "8812".into())
                .parse()
                .unwrap_or(8812),

            clickhouse_url: env::var("CLICKHOUSE_URL")
                .unwrap_or_else(|_| "http://clickhouse:8123".into()),

            detection,

            region: env::var("ACM_REGION").unwrap_or_else(|_| "lagos".into()),
            node_id: env::var("ACM_NODE_ID").unwrap_or_else(|_| "acm-engine-1".into()),
        }
    }
}
