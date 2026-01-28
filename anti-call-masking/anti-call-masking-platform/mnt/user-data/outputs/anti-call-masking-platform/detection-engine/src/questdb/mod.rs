// ============================================================================
// QuestDB Client - Real-time Time-Series Analytics
// Replaces kdb+ with open-source QuestDB for high-performance analytics
// Version: 2.0 | Date: 2026-01-22
// ============================================================================
//
// QuestDB Advantages over kdb+:
// - Open source (Apache 2.0 license)
// - SQL support (familiar syntax)
// - PostgreSQL wire protocol (use existing drivers)
// - InfluxDB Line Protocol for high-speed ingestion
// - Column-oriented storage optimized for time-series
// - 1.5M+ rows/second ingestion on commodity hardware
// - Built-in web console and REST API

use anyhow::{Context, Result};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use std::time::Duration;
use tokio::io::{AsyncBufReadExt, AsyncWriteExt, BufReader};
use tokio::net::TcpStream;
use tokio::sync::Mutex;
use tracing::{debug, error, info, warn};

/// QuestDB configuration
#[derive(Debug, Clone)]
pub struct QuestDbConfig {
    /// PostgreSQL wire protocol host (for queries)
    pub pg_host: String,
    pub pg_port: u16,
    /// InfluxDB Line Protocol host (for high-speed ingestion)
    pub ilp_host: String,
    pub ilp_port: u16,
    /// HTTP API host (for REST queries)
    pub http_host: String,
    pub http_port: u16,
    /// Connection pool size
    pub pool_size: u32,
    /// Query timeout
    pub timeout_secs: u64,
}

impl Default for QuestDbConfig {
    fn default() -> Self {
        Self {
            pg_host: "localhost".to_string(),
            pg_port: 8812,
            ilp_host: "localhost".to_string(),
            ilp_port: 9009,
            http_host: "localhost".to_string(),
            http_port: 9000,
            pool_size: 10,
            timeout_secs: 30,
        }
    }
}

/// High-performance QuestDB client for ACM analytics
pub struct QuestDbClient {
    config: QuestDbConfig,
    /// PostgreSQL connection pool for queries
    pg_pool: sqlx::PgPool,
    /// ILP sender for high-speed ingestion
    ilp_sender: Arc<Mutex<Option<IlpSender>>>,
    /// HTTP client for REST API
    http_client: reqwest::Client,
}

/// InfluxDB Line Protocol sender for high-speed ingestion
struct IlpSender {
    stream: TcpStream,
    buffer: Vec<u8>,
    buffer_size: usize,
    last_flush: std::time::Instant,
}

impl IlpSender {
    async fn new(host: &str, port: u16) -> Result<Self> {
        let stream = TcpStream::connect(format!("{}:{}", host, port))
            .await
            .context("Failed to connect to QuestDB ILP")?;
        
        Ok(Self {
            stream,
            buffer: Vec::with_capacity(65536),
            buffer_size: 0,
            last_flush: std::time::Instant::now(),
        })
    }

    /// Write a line to the buffer
    fn write_line(&mut self, line: &str) {
        self.buffer.extend_from_slice(line.as_bytes());
        self.buffer.push(b'\n');
        self.buffer_size += line.len() + 1;
    }

    /// Flush buffer to QuestDB
    async fn flush(&mut self) -> Result<()> {
        if self.buffer.is_empty() {
            return Ok(());
        }

        self.stream
            .write_all(&self.buffer)
            .await
            .context("Failed to write to QuestDB ILP")?;
        
        self.buffer.clear();
        self.buffer_size = 0;
        self.last_flush = std::time::Instant::now();
        
        Ok(())
    }

    /// Check if buffer should be flushed
    fn should_flush(&self) -> bool {
        self.buffer_size > 32768 || self.last_flush.elapsed() > Duration::from_millis(100)
    }
}

impl QuestDbClient {
    /// Create a new QuestDB client
    pub async fn new(config: QuestDbConfig) -> Result<Self> {
        // Create PostgreSQL connection pool for queries
        let pg_url = format!(
            "postgres://admin:quest@{}:{}/qdb",
            config.pg_host, config.pg_port
        );
        
        let pg_pool = sqlx::postgres::PgPoolOptions::new()
            .max_connections(config.pool_size)
            .acquire_timeout(Duration::from_secs(config.timeout_secs))
            .connect(&pg_url)
            .await
            .context("Failed to connect to QuestDB PostgreSQL interface")?;

        // Create HTTP client for REST API
        let http_client = reqwest::Client::builder()
            .timeout(Duration::from_secs(config.timeout_secs))
            .build()
            .context("Failed to create HTTP client")?;

        // Create ILP sender for high-speed ingestion
        let ilp_sender = match IlpSender::new(&config.ilp_host, config.ilp_port).await {
            Ok(sender) => Some(sender),
            Err(e) => {
                warn!("Failed to connect to QuestDB ILP, will retry: {}", e);
                None
            }
        };

        info!(
            "Connected to QuestDB at {}:{} (PG), {}:{} (ILP)",
            config.pg_host, config.pg_port, config.ilp_host, config.ilp_port
        );

        Ok(Self {
            config,
            pg_pool,
            ilp_sender: Arc::new(Mutex::new(ilp_sender)),
            http_client,
        })
    }

    /// Initialize QuestDB tables for ACM
    pub async fn initialize_tables(&self) -> Result<()> {
        let tables = vec![
            // Real-time CDR table (partitioned by day)
            r#"
            CREATE TABLE IF NOT EXISTS cdrs (
                timestamp TIMESTAMP,
                call_id SYMBOL,
                caller_id SYMBOL,
                called_number SYMBOL,
                source_ip SYMBOL,
                source_port INT,
                dest_ip SYMBOL,
                dest_port INT,
                duration_ms LONG,
                fraud_detected BOOLEAN,
                fraud_type SYMBOL,
                fraud_score DOUBLE,
                action_taken SYMBOL,
                gateway_id SYMBOL,
                region SYMBOL
            ) TIMESTAMP(timestamp) PARTITION BY DAY WAL
            "#,
            
            // Real-time fraud events
            r#"
            CREATE TABLE IF NOT EXISTS fraud_events (
                timestamp TIMESTAMP,
                call_id SYMBOL,
                fraud_type SYMBOL,
                confidence DOUBLE,
                severity INT,
                source_ip SYMBOL,
                caller_id SYMBOL,
                called_number SYMBOL,
                gateway_id SYMBOL,
                action SYMBOL,
                ncc_reported BOOLEAN,
                reasons STRING
            ) TIMESTAMP(timestamp) PARTITION BY DAY WAL
            "#,
            
            // Real-time detection metrics (for dashboards)
            r#"
            CREATE TABLE IF NOT EXISTS detection_metrics (
                timestamp TIMESTAMP,
                region SYMBOL,
                calls_processed LONG,
                fraud_detected LONG,
                avg_latency_us DOUBLE,
                p99_latency_us DOUBLE,
                cache_hits LONG,
                cache_misses LONG,
                mnp_lookups LONG
            ) TIMESTAMP(timestamp) PARTITION BY HOUR WAL
            "#,
            
            // SIM-box behavioral tracking
            r#"
            CREATE TABLE IF NOT EXISTS simbox_tracking (
                timestamp TIMESTAMP,
                a_number SYMBOL,
                cpm INT,
                acd_seconds DOUBLE,
                unique_destinations INT,
                concurrent_calls INT,
                risk_score DOUBLE,
                is_flagged BOOLEAN
            ) TIMESTAMP(timestamp) PARTITION BY DAY WAL
            "#,
            
            // Gateway performance metrics
            r#"
            CREATE TABLE IF NOT EXISTS gateway_metrics (
                timestamp TIMESTAMP,
                gateway_id SYMBOL,
                gateway_name SYMBOL,
                calls_attempted LONG,
                calls_completed LONG,
                calls_failed LONG,
                fraud_detected LONG,
                avg_duration_ms DOUBLE,
                asr DOUBLE,
                acd DOUBLE
            ) TIMESTAMP(timestamp) PARTITION BY HOUR WAL
            "#,
            
            // MNP lookup performance
            r#"
            CREATE TABLE IF NOT EXISTS mnp_metrics (
                timestamp TIMESTAMP,
                region SYMBOL,
                lookups LONG,
                cache_l1_hits LONG,
                cache_l2_hits LONG,
                db_lookups LONG,
                avg_latency_us DOUBLE,
                ported_found LONG
            ) TIMESTAMP(timestamp) PARTITION BY HOUR WAL
            "#,
        ];

        for table_ddl in tables {
            self.execute_ddl(table_ddl).await?;
        }

        info!("QuestDB tables initialized");
        Ok(())
    }

    /// Execute DDL statement via HTTP API
    async fn execute_ddl(&self, ddl: &str) -> Result<()> {
        let url = format!(
            "http://{}:{}/exec",
            self.config.http_host, self.config.http_port
        );

        let response = self
            .http_client
            .get(&url)
            .query(&[("query", ddl)])
            .send()
            .await
            .context("Failed to execute DDL")?;

        if !response.status().is_success() {
            let error_text = response.text().await.unwrap_or_default();
            // Ignore "table already exists" errors
            if !error_text.contains("already exists") {
                return Err(anyhow::anyhow!("DDL failed: {}", error_text));
            }
        }

        Ok(())
    }

    // =========================================================================
    // High-Speed Ingestion via InfluxDB Line Protocol
    // =========================================================================

    /// Record a CDR using ILP (high-speed)
    pub async fn record_cdr(&self, cdr: &CdrRecord) -> Result<()> {
        let line = format!(
            "cdrs,call_id={},caller_id={},called_number={},source_ip={},gateway_id={},region={},fraud_type={},action={} \
             source_port={}i,dest_port={}i,duration_ms={}i,fraud_detected={},fraud_score={} {}",
            escape_tag(&cdr.call_id),
            escape_tag(&cdr.caller_id),
            escape_tag(&cdr.called_number),
            escape_tag(&cdr.source_ip),
            escape_tag(&cdr.gateway_id),
            escape_tag(&cdr.region),
            escape_tag(&cdr.fraud_type.as_deref().unwrap_or("NONE")),
            escape_tag(&cdr.action_taken.as_deref().unwrap_or("ALLOW")),
            cdr.source_port,
            cdr.dest_port.unwrap_or(0),
            cdr.duration_ms,
            cdr.fraud_detected,
            cdr.fraud_score.unwrap_or(0.0),
            cdr.timestamp.timestamp_nanos_opt().unwrap_or(0)
        );

        self.write_ilp_line(&line).await
    }

    /// Record a fraud event using ILP
    pub async fn record_fraud_event(&self, event: &FraudEvent) -> Result<()> {
        let line = format!(
            "fraud_events,call_id={},fraud_type={},source_ip={},caller_id={},gateway_id={},action={} \
             confidence={},severity={}i,ncc_reported={},reasons=\"{}\" {}",
            escape_tag(&event.call_id),
            escape_tag(&event.fraud_type),
            escape_tag(&event.source_ip),
            escape_tag(&event.caller_id),
            escape_tag(&event.gateway_id),
            escape_tag(&event.action),
            event.confidence,
            event.severity,
            event.ncc_reported,
            escape_string(&event.reasons.join("; ")),
            event.timestamp.timestamp_nanos_opt().unwrap_or(0)
        );

        self.write_ilp_line(&line).await
    }

    /// Record detection metrics using ILP
    pub async fn record_detection_metrics(&self, metrics: &DetectionMetrics) -> Result<()> {
        let line = format!(
            "detection_metrics,region={} \
             calls_processed={}i,fraud_detected={}i,avg_latency_us={},p99_latency_us={},\
             cache_hits={}i,cache_misses={}i,mnp_lookups={}i {}",
            escape_tag(&metrics.region),
            metrics.calls_processed,
            metrics.fraud_detected,
            metrics.avg_latency_us,
            metrics.p99_latency_us,
            metrics.cache_hits,
            metrics.cache_misses,
            metrics.mnp_lookups,
            metrics.timestamp.timestamp_nanos_opt().unwrap_or(0)
        );

        self.write_ilp_line(&line).await
    }

    /// Record SIM-box tracking data
    pub async fn record_simbox_tracking(&self, tracking: &SimboxTracking) -> Result<()> {
        let line = format!(
            "simbox_tracking,a_number={} \
             cpm={}i,acd_seconds={},unique_destinations={}i,concurrent_calls={}i,\
             risk_score={},is_flagged={} {}",
            escape_tag(&tracking.a_number),
            tracking.cpm,
            tracking.acd_seconds,
            tracking.unique_destinations,
            tracking.concurrent_calls,
            tracking.risk_score,
            tracking.is_flagged,
            tracking.timestamp.timestamp_nanos_opt().unwrap_or(0)
        );

        self.write_ilp_line(&line).await
    }

    /// Record gateway metrics
    pub async fn record_gateway_metrics(&self, metrics: &GatewayMetrics) -> Result<()> {
        let line = format!(
            "gateway_metrics,gateway_id={},gateway_name={} \
             calls_attempted={}i,calls_completed={}i,calls_failed={}i,fraud_detected={}i,\
             avg_duration_ms={},asr={},acd={} {}",
            escape_tag(&metrics.gateway_id),
            escape_tag(&metrics.gateway_name),
            metrics.calls_attempted,
            metrics.calls_completed,
            metrics.calls_failed,
            metrics.fraud_detected,
            metrics.avg_duration_ms,
            metrics.asr,
            metrics.acd,
            metrics.timestamp.timestamp_nanos_opt().unwrap_or(0)
        );

        self.write_ilp_line(&line).await
    }

    /// Write a line via ILP
    async fn write_ilp_line(&self, line: &str) -> Result<()> {
        let mut sender_guard = self.ilp_sender.lock().await;
        
        // Reconnect if needed
        if sender_guard.is_none() {
            match IlpSender::new(&self.config.ilp_host, self.config.ilp_port).await {
                Ok(sender) => {
                    *sender_guard = Some(sender);
                    info!("Reconnected to QuestDB ILP");
                }
                Err(e) => {
                    return Err(anyhow::anyhow!("Failed to reconnect to QuestDB ILP: {}", e));
                }
            }
        }

        if let Some(ref mut sender) = *sender_guard {
            sender.write_line(line);
            
            // Flush if buffer is full or time elapsed
            if sender.should_flush() {
                if let Err(e) = sender.flush().await {
                    error!("Failed to flush ILP buffer: {}", e);
                    *sender_guard = None; // Force reconnect
                    return Err(e);
                }
            }
        }

        Ok(())
    }

    /// Force flush the ILP buffer
    pub async fn flush(&self) -> Result<()> {
        let mut sender_guard = self.ilp_sender.lock().await;
        if let Some(ref mut sender) = *sender_guard {
            sender.flush().await?;
        }
        Ok(())
    }

    // =========================================================================
    // SQL Queries via PostgreSQL Wire Protocol
    // =========================================================================

    /// Query fraud statistics for dashboard
    pub async fn get_fraud_stats(&self, hours: i32) -> Result<FraudStats> {
        let row = sqlx::query_as::<_, FraudStatsRow>(
            r#"
            SELECT 
                count() as total_calls,
                sum(CASE WHEN fraud_detected THEN 1 ELSE 0 END) as fraud_count,
                avg(fraud_score) as avg_fraud_score,
                count_distinct(source_ip) as unique_sources
            FROM cdrs
            WHERE timestamp > dateadd('h', -$1, now())
            "#,
        )
        .bind(hours)
        .fetch_one(&self.pg_pool)
        .await?;

        Ok(FraudStats {
            total_calls: row.total_calls,
            fraud_count: row.fraud_count,
            fraud_rate: if row.total_calls > 0 {
                row.fraud_count as f64 / row.total_calls as f64 * 100.0
            } else {
                0.0
            },
            avg_fraud_score: row.avg_fraud_score.unwrap_or(0.0),
            unique_fraud_sources: row.unique_sources,
        })
    }

    /// Query fraud by type for the last N hours
    pub async fn get_fraud_by_type(&self, hours: i32) -> Result<Vec<FraudTypeCount>> {
        let rows = sqlx::query_as::<_, FraudTypeCountRow>(
            r#"
            SELECT 
                fraud_type,
                count() as count,
                avg(confidence) as avg_confidence
            FROM fraud_events
            WHERE timestamp > dateadd('h', -$1, now())
            GROUP BY fraud_type
            ORDER BY count DESC
            "#,
        )
        .bind(hours)
        .fetch_all(&self.pg_pool)
        .await?;

        Ok(rows
            .into_iter()
            .map(|r| FraudTypeCount {
                fraud_type: r.fraud_type,
                count: r.count,
                avg_confidence: r.avg_confidence.unwrap_or(0.0),
            })
            .collect())
    }

    /// Query top fraud sources (IPs)
    pub async fn get_top_fraud_sources(&self, hours: i32, limit: i32) -> Result<Vec<FraudSource>> {
        let rows = sqlx::query_as::<_, FraudSourceRow>(
            r#"
            SELECT 
                source_ip,
                count() as fraud_count,
                count_distinct(fraud_type) as fraud_types
            FROM fraud_events
            WHERE timestamp > dateadd('h', -$1, now())
            GROUP BY source_ip
            ORDER BY fraud_count DESC
            LIMIT $2
            "#,
        )
        .bind(hours)
        .bind(limit)
        .fetch_all(&self.pg_pool)
        .await?;

        Ok(rows
            .into_iter()
            .map(|r| FraudSource {
                source_ip: r.source_ip,
                fraud_count: r.fraud_count,
                fraud_types: r.fraud_types,
            })
            .collect())
    }

    /// Query SIM-box suspects
    pub async fn get_simbox_suspects(&self, min_risk_score: f64) -> Result<Vec<SimboxSuspect>> {
        let rows = sqlx::query_as::<_, SimboxSuspectRow>(
            r#"
            SELECT 
                a_number,
                last(cpm) as last_cpm,
                last(acd_seconds) as last_acd,
                last(unique_destinations) as last_unique_dest,
                max(risk_score) as max_risk_score,
                last(timestamp) as last_seen
            FROM simbox_tracking
            WHERE timestamp > dateadd('d', -1, now())
            GROUP BY a_number
            HAVING max(risk_score) >= $1
            ORDER BY max_risk_score DESC
            LIMIT 100
            "#,
        )
        .bind(min_risk_score)
        .fetch_all(&self.pg_pool)
        .await?;

        Ok(rows
            .into_iter()
            .map(|r| SimboxSuspect {
                a_number: r.a_number,
                last_cpm: r.last_cpm,
                last_acd: r.last_acd,
                last_unique_destinations: r.last_unique_dest,
                max_risk_score: r.max_risk_score,
                last_seen: r.last_seen,
            })
            .collect())
    }

    /// Query gateway performance
    pub async fn get_gateway_performance(&self, hours: i32) -> Result<Vec<GatewayPerformance>> {
        let rows = sqlx::query_as::<_, GatewayPerformanceRow>(
            r#"
            SELECT 
                gateway_id,
                gateway_name,
                sum(calls_attempted) as total_calls,
                sum(fraud_detected) as total_fraud,
                avg(asr) as avg_asr,
                avg(acd) as avg_acd
            FROM gateway_metrics
            WHERE timestamp > dateadd('h', -$1, now())
            GROUP BY gateway_id, gateway_name
            ORDER BY total_fraud DESC
            "#,
        )
        .bind(hours)
        .fetch_all(&self.pg_pool)
        .await?;

        Ok(rows
            .into_iter()
            .map(|r| GatewayPerformance {
                gateway_id: r.gateway_id,
                gateway_name: r.gateway_name,
                total_calls: r.total_calls,
                total_fraud: r.total_fraud,
                fraud_rate: if r.total_calls > 0 {
                    r.total_fraud as f64 / r.total_calls as f64 * 100.0
                } else {
                    0.0
                },
                avg_asr: r.avg_asr.unwrap_or(0.0),
                avg_acd: r.avg_acd.unwrap_or(0.0),
            })
            .collect())
    }

    /// Query hourly traffic for the last N hours
    pub async fn get_hourly_traffic(&self, hours: i32) -> Result<Vec<HourlyTraffic>> {
        let rows = sqlx::query_as::<_, HourlyTrafficRow>(
            r#"
            SELECT 
                date_trunc('hour', timestamp) as hour,
                count() as calls,
                sum(CASE WHEN fraud_detected THEN 1 ELSE 0 END) as fraud,
                avg(duration_ms) as avg_duration
            FROM cdrs
            WHERE timestamp > dateadd('h', -$1, now())
            GROUP BY hour
            ORDER BY hour
            "#,
        )
        .bind(hours)
        .fetch_all(&self.pg_pool)
        .await?;

        Ok(rows
            .into_iter()
            .map(|r| HourlyTraffic {
                hour: r.hour,
                calls: r.calls,
                fraud: r.fraud,
                avg_duration_ms: r.avg_duration.unwrap_or(0.0),
            })
            .collect())
    }

    /// Get real-time metrics sample
    pub async fn get_realtime_metrics(&self) -> Result<RealtimeMetrics> {
        // Get last 10 seconds of data
        let row = sqlx::query_as::<_, RealtimeMetricsRow>(
            r#"
            SELECT 
                sum(calls_processed) as calls,
                sum(fraud_detected) as fraud,
                avg(avg_latency_us) as latency,
                sum(cache_hits) as hits,
                sum(cache_misses) as misses
            FROM detection_metrics
            WHERE timestamp > dateadd('s', -10, now())
            "#,
        )
        .fetch_one(&self.pg_pool)
        .await?;

        Ok(RealtimeMetrics {
            calls_per_second: row.calls.unwrap_or(0) / 10,
            fraud_per_second: row.fraud.unwrap_or(0) / 10,
            avg_latency_us: row.latency.unwrap_or(0.0),
            cache_hit_rate: if (row.hits.unwrap_or(0) + row.misses.unwrap_or(0)) > 0 {
                row.hits.unwrap_or(0) as f64
                    / (row.hits.unwrap_or(0) + row.misses.unwrap_or(0)) as f64
                    * 100.0
            } else {
                0.0
            },
        })
    }
}

// ============================================================================
// Data Models
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CdrRecord {
    pub timestamp: DateTime<Utc>,
    pub call_id: String,
    pub caller_id: String,
    pub called_number: String,
    pub source_ip: String,
    pub source_port: i32,
    pub dest_ip: Option<String>,
    pub dest_port: Option<i32>,
    pub duration_ms: i64,
    pub fraud_detected: bool,
    pub fraud_type: Option<String>,
    pub fraud_score: Option<f64>,
    pub action_taken: Option<String>,
    pub gateway_id: String,
    pub region: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FraudEvent {
    pub timestamp: DateTime<Utc>,
    pub call_id: String,
    pub fraud_type: String,
    pub confidence: f64,
    pub severity: i32,
    pub source_ip: String,
    pub caller_id: String,
    pub called_number: String,
    pub gateway_id: String,
    pub action: String,
    pub ncc_reported: bool,
    pub reasons: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DetectionMetrics {
    pub timestamp: DateTime<Utc>,
    pub region: String,
    pub calls_processed: i64,
    pub fraud_detected: i64,
    pub avg_latency_us: f64,
    pub p99_latency_us: f64,
    pub cache_hits: i64,
    pub cache_misses: i64,
    pub mnp_lookups: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SimboxTracking {
    pub timestamp: DateTime<Utc>,
    pub a_number: String,
    pub cpm: i32,
    pub acd_seconds: f64,
    pub unique_destinations: i32,
    pub concurrent_calls: i32,
    pub risk_score: f64,
    pub is_flagged: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GatewayMetrics {
    pub timestamp: DateTime<Utc>,
    pub gateway_id: String,
    pub gateway_name: String,
    pub calls_attempted: i64,
    pub calls_completed: i64,
    pub calls_failed: i64,
    pub fraud_detected: i64,
    pub avg_duration_ms: f64,
    pub asr: f64,  // Answer Seizure Ratio
    pub acd: f64,  // Average Call Duration
}

// Query result models
#[derive(Debug, Serialize)]
pub struct FraudStats {
    pub total_calls: i64,
    pub fraud_count: i64,
    pub fraud_rate: f64,
    pub avg_fraud_score: f64,
    pub unique_fraud_sources: i64,
}

#[derive(Debug, Serialize)]
pub struct FraudTypeCount {
    pub fraud_type: String,
    pub count: i64,
    pub avg_confidence: f64,
}

#[derive(Debug, Serialize)]
pub struct FraudSource {
    pub source_ip: String,
    pub fraud_count: i64,
    pub fraud_types: i64,
}

#[derive(Debug, Serialize)]
pub struct SimboxSuspect {
    pub a_number: String,
    pub last_cpm: i32,
    pub last_acd: f64,
    pub last_unique_destinations: i32,
    pub max_risk_score: f64,
    pub last_seen: DateTime<Utc>,
}

#[derive(Debug, Serialize)]
pub struct GatewayPerformance {
    pub gateway_id: String,
    pub gateway_name: String,
    pub total_calls: i64,
    pub total_fraud: i64,
    pub fraud_rate: f64,
    pub avg_asr: f64,
    pub avg_acd: f64,
}

#[derive(Debug, Serialize)]
pub struct HourlyTraffic {
    pub hour: DateTime<Utc>,
    pub calls: i64,
    pub fraud: i64,
    pub avg_duration_ms: f64,
}

#[derive(Debug, Serialize)]
pub struct RealtimeMetrics {
    pub calls_per_second: i64,
    pub fraud_per_second: i64,
    pub avg_latency_us: f64,
    pub cache_hit_rate: f64,
}

// SQLx row types
#[derive(sqlx::FromRow)]
struct FraudStatsRow {
    total_calls: i64,
    fraud_count: i64,
    avg_fraud_score: Option<f64>,
    unique_sources: i64,
}

#[derive(sqlx::FromRow)]
struct FraudTypeCountRow {
    fraud_type: String,
    count: i64,
    avg_confidence: Option<f64>,
}

#[derive(sqlx::FromRow)]
struct FraudSourceRow {
    source_ip: String,
    fraud_count: i64,
    fraud_types: i64,
}

#[derive(sqlx::FromRow)]
struct SimboxSuspectRow {
    a_number: String,
    last_cpm: i32,
    last_acd: f64,
    last_unique_dest: i32,
    max_risk_score: f64,
    last_seen: DateTime<Utc>,
}

#[derive(sqlx::FromRow)]
struct GatewayPerformanceRow {
    gateway_id: String,
    gateway_name: String,
    total_calls: i64,
    total_fraud: i64,
    avg_asr: Option<f64>,
    avg_acd: Option<f64>,
}

#[derive(sqlx::FromRow)]
struct HourlyTrafficRow {
    hour: DateTime<Utc>,
    calls: i64,
    fraud: i64,
    avg_duration: Option<f64>,
}

#[derive(sqlx::FromRow)]
struct RealtimeMetricsRow {
    calls: Option<i64>,
    fraud: Option<i64>,
    latency: Option<f64>,
    hits: Option<i64>,
    misses: Option<i64>,
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Escape tag value for ILP
fn escape_tag(s: &str) -> String {
    s.replace(' ', "\\ ")
        .replace(',', "\\,")
        .replace('=', "\\=")
}

/// Escape string value for ILP
fn escape_string(s: &str) -> String {
    s.replace('\\', "\\\\").replace('"', "\\\"")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_escape_tag() {
        assert_eq!(escape_tag("hello world"), "hello\\ world");
        assert_eq!(escape_tag("key=value"), "key\\=value");
        assert_eq!(escape_tag("a,b,c"), "a\\,b\\,c");
    }

    #[test]
    fn test_escape_string() {
        assert_eq!(escape_string("hello\"world"), "hello\\\"world");
        assert_eq!(escape_string("path\\to\\file"), "path\\\\to\\\\file");
    }
}
