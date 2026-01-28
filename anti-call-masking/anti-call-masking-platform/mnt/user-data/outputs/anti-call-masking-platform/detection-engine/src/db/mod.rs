//! Database clients for YugabyteDB (YSQL) and ClickHouse.
//!
//! - YugabyteDB: Stores MNP data, blacklists, gateway profiles, fraud alerts
//! - ClickHouse: Stores CDRs and analytics data

use crate::models::{
    BlacklistEntry, CallDetailRecord, FraudAlert, FraudDetectionProfile,
    GatewayProfile, MnpRecord, SettlementDispute,
};
use crate::metrics::Metrics;
use chrono::{DateTime, Utc};
use deadpool_postgres::{Config, Pool, Runtime, ManagerConfig, RecyclingMethod};
use std::sync::Arc;
use thiserror::Error;
use tokio_postgres::NoTls;
use uuid::Uuid;

#[derive(Debug, Error)]
pub enum DbError {
    #[error("PostgreSQL error: {0}")]
    PostgresError(#[from] tokio_postgres::Error),

    #[error("Pool error: {0}")]
    PoolError(#[from] deadpool_postgres::PoolError),

    #[error("ClickHouse error: {0}")]
    ClickHouseError(String),

    #[error("Record not found")]
    NotFound,

    #[error("Serialization error: {0}")]
    SerializationError(String),
}

// ==================== YugabyteDB Client ====================

/// YugabyteDB client for YSQL operations
pub struct YugabyteClient {
    pool: Pool,
}

impl YugabyteClient {
    /// Create a new YugabyteDB client
    pub async fn new(database_url: &str) -> Result<Self, DbError> {
        // Parse the URL and create config
        let mut cfg = Config::new();
        
        // Parse postgres://user:pass@host:port/db format
        if let Ok(url) = url::Url::parse(database_url) {
            cfg.host = url.host_str().map(String::from);
            cfg.port = url.port();
            cfg.user = Some(url.username().to_string());
            cfg.password = url.password().map(String::from);
            cfg.dbname = Some(url.path().trim_start_matches('/').to_string());
        }

        cfg.manager = Some(ManagerConfig {
            recycling_method: RecyclingMethod::Fast,
        });

        let pool = cfg
            .create_pool(Some(Runtime::Tokio1), NoTls)
            .map_err(|e| DbError::ClickHouseError(e.to_string()))?;

        // Test connection
        let client = pool.get().await?;
        let _ = client.query_one("SELECT 1", &[]).await?;

        tracing::info!("Connected to YugabyteDB");
        Ok(Self { pool })
    }

    // ==================== MNP Operations ====================

    /// Get MNP record for a number
    pub async fn get_mnp_record(&self, msisdn: &str) -> Result<Option<MnpRecord>, DbError> {
        let client = self.pool.get().await?;
        
        let row = client
            .query_opt(
                "SELECT msisdn, hosting_network_id, routing_number, last_updated 
                 FROM mnp_data WHERE msisdn = $1",
                &[&msisdn],
            )
            .await?;

        match row {
            Some(row) => {
                let routing_number: String = row.get(2);
                let hosting_id: String = row.get(1);
                
                // Determine if ported based on prefix vs hosting network
                let default_operator = crate::nigerian_prefixes::get_default_operator(msisdn);
                let is_ported = default_operator
                    .map(|op| !hosting_id.to_lowercase().contains(&op.to_lowercase()))
                    .unwrap_or(false);

                Ok(Some(MnpRecord {
                    msisdn: row.get(0),
                    is_ported,
                    hosting_network: hosting_id.clone(),
                    hosting_network_id: hosting_id,
                    routing_number,
                    original_network: default_operator.map(String::from),
                    port_date: None,
                    last_updated: row.get(3),
                }))
            }
            None => Ok(None),
        }
    }

    /// Bulk upsert MNP records
    pub async fn bulk_upsert_mnp(&self, records: &[MnpRecord]) -> Result<usize, DbError> {
        if records.is_empty() {
            return Ok(0);
        }

        let client = self.pool.get().await?;
        let mut count = 0;

        // Process in batches of 1000
        for chunk in records.chunks(1000) {
            let mut query = String::from(
                "INSERT INTO mnp_data (msisdn, hosting_network_id, routing_number, last_updated) VALUES "
            );
            
            let mut params: Vec<&(dyn tokio_postgres::types::ToSql + Sync)> = Vec::new();
            let mut values = Vec::new();

            for (i, record) in chunk.iter().enumerate() {
                let base = i * 4;
                values.push(format!(
                    "(${}, ${}, ${}, ${})",
                    base + 1, base + 2, base + 3, base + 4
                ));
            }

            query.push_str(&values.join(", "));
            query.push_str(
                " ON CONFLICT (msisdn) DO UPDATE SET 
                 hosting_network_id = EXCLUDED.hosting_network_id,
                 routing_number = EXCLUDED.routing_number,
                 last_updated = EXCLUDED.last_updated"
            );

            // Build params dynamically
            for record in chunk {
                let stmt = client
                    .execute(
                        "INSERT INTO mnp_data (msisdn, hosting_network_id, routing_number, last_updated) 
                         VALUES ($1, $2, $3, $4)
                         ON CONFLICT (msisdn) DO UPDATE SET 
                         hosting_network_id = EXCLUDED.hosting_network_id,
                         routing_number = EXCLUDED.routing_number,
                         last_updated = EXCLUDED.last_updated",
                        &[&record.msisdn, &record.hosting_network_id, &record.routing_number, &record.last_updated],
                    )
                    .await?;
                count += stmt as usize;
            }
        }

        tracing::info!("Bulk upserted {} MNP records", count);
        Ok(count)
    }

    // ==================== Blacklist Operations ====================

    /// Get all blacklisted IPs
    pub async fn get_blacklisted_ips(&self) -> Result<Vec<String>, DbError> {
        let client = self.pool.get().await?;
        
        let rows = client
            .query(
                "SELECT ip FROM address WHERE grp = 66 AND (expires_at IS NULL OR expires_at > NOW())",
                &[],
            )
            .await?;

        let ips: Vec<String> = rows.iter().map(|row| row.get(0)).collect();
        Ok(ips)
    }

    /// Add IP to blacklist
    pub async fn add_blacklist_entry(&self, entry: &BlacklistEntry) -> Result<(), DbError> {
        let client = self.pool.get().await?;
        
        client
            .execute(
                "INSERT INTO address (id, grp, ip, mask, tag, port, proto) 
                 VALUES ($1, 66, $2, $3, $4, 0, 'any')
                 ON CONFLICT (ip, grp) DO UPDATE SET 
                 tag = EXCLUDED.tag, mask = EXCLUDED.mask",
                &[&entry.id, &entry.ip, &(entry.mask as i32), &entry.reason],
            )
            .await?;

        Ok(())
    }

    /// Remove IP from blacklist
    pub async fn remove_blacklist_entry(&self, ip: &str) -> Result<(), DbError> {
        let client = self.pool.get().await?;
        
        client
            .execute("DELETE FROM address WHERE ip = $1 AND grp = 66", &[&ip])
            .await?;

        Ok(())
    }

    // ==================== Gateway Operations ====================

    /// Get all gateway IPs for a group
    pub async fn get_gateway_ips(&self, group_id: u8) -> Result<Vec<String>, DbError> {
        let client = self.pool.get().await?;
        
        let rows = client
            .query(
                "SELECT ip FROM address WHERE grp = $1",
                &[&(group_id as i32)],
            )
            .await?;

        let ips: Vec<String> = rows.iter().map(|row| row.get(0)).collect();
        Ok(ips)
    }

    /// Get gateway profile by IP
    pub async fn get_gateway_by_ip(&self, ip: &str) -> Result<Option<GatewayProfile>, DbError> {
        let client = self.pool.get().await?;
        
        let row = client
            .query_opt(
                "SELECT id, grp, ip, mask, port, proto, pattern, tag 
                 FROM address WHERE ip = $1 LIMIT 1",
                &[&ip],
            )
            .await?;

        match row {
            Some(row) => {
                let id: i32 = row.get(0);
                Ok(Some(GatewayProfile {
                    id: Uuid::from_u128(id as u128),
                    name: row.get::<_, Option<String>>(7).unwrap_or_default(),
                    ip: row.get(2),
                    mask: row.get::<_, i32>(3) as u8,
                    group_id: row.get::<_, i32>(1) as u8,
                    protocol: row.get(5),
                    port: row.get::<_, i32>(4) as u16,
                    tag: row.get(7),
                    active: true,
                    carrier: None,
                    allowed_prefixes: vec![],
                    created_at: Utc::now(),
                    updated_at: Utc::now(),
                }))
            }
            None => Ok(None),
        }
    }

    // ==================== Fraud Alert Operations ====================

    /// Save a fraud alert
    pub async fn save_fraud_alert(&self, alert: &FraudAlert) -> Result<(), DbError> {
        let client = self.pool.get().await?;
        
        client
            .execute(
                "INSERT INTO fraud_alerts 
                 (id, call_id, fraud_type, source_ip, cli, called_number, confidence, 
                  severity, action, reason, timestamp, ncc_reported)
                 VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)",
                &[
                    &alert.id,
                    &alert.call_id,
                    &alert.fraud_type,
                    &alert.source_ip,
                    &alert.cli,
                    &alert.called_number,
                    &alert.confidence,
                    &(alert.severity as i32),
                    &alert.action,
                    &alert.reason,
                    &alert.timestamp,
                    &alert.ncc_reported,
                ],
            )
            .await?;

        Ok(())
    }

    /// Get unreported fraud alerts
    pub async fn get_unreported_alerts(&self, limit: i64) -> Result<Vec<FraudAlert>, DbError> {
        let client = self.pool.get().await?;
        
        let rows = client
            .query(
                "SELECT id, call_id, fraud_type, source_ip, cli, called_number, 
                        confidence, severity, action, reason, timestamp, ncc_reported
                 FROM fraud_alerts 
                 WHERE ncc_reported = false 
                 ORDER BY timestamp ASC 
                 LIMIT $1",
                &[&limit],
            )
            .await?;

        let alerts: Vec<FraudAlert> = rows
            .iter()
            .map(|row| FraudAlert {
                id: row.get(0),
                call_id: row.get(1),
                fraud_type: row.get(2),
                source_ip: row.get(3),
                cli: row.get(4),
                called_number: row.get(5),
                confidence: row.get(6),
                severity: row.get::<_, i32>(7) as u8,
                action: row.get(8),
                reason: row.get(9),
                timestamp: row.get(10),
                acknowledged: false,
                acknowledged_by: None,
                acknowledged_at: None,
                ncc_reported: row.get(11),
                ncc_reported_at: None,
                metadata: std::collections::HashMap::new(),
            })
            .collect();

        Ok(alerts)
    }

    /// Mark alert as reported to NCC
    pub async fn mark_alert_reported(&self, id: &Uuid) -> Result<(), DbError> {
        let client = self.pool.get().await?;
        
        client
            .execute(
                "UPDATE fraud_alerts SET ncc_reported = true, ncc_reported_at = NOW() WHERE id = $1",
                &[id],
            )
            .await?;

        Ok(())
    }

    // ==================== Fraud Detection Profile Operations ====================

    /// Get fraud detection profiles for a prefix
    pub async fn get_detection_profiles(&self, prefix: &str) -> Result<Vec<FraudDetectionProfile>, DbError> {
        let client = self.pool.get().await?;
        
        let rows = client
            .query(
                "SELECT id, profileid, prefix, cpm_warning, cpm_critical, 
                        call_duration_warning, call_duration_critical,
                        total_calls_warning, total_calls_critical,
                        concurrent_calls_warning, concurrent_calls_critical
                 FROM fraud_detection 
                 WHERE $1 LIKE prefix || '%' AND active = true",
                &[&prefix],
            )
            .await?;

        let profiles: Vec<FraudDetectionProfile> = rows
            .iter()
            .map(|row| FraudDetectionProfile {
                id: Uuid::new_v4(),
                name: format!("Profile-{}", row.get::<_, i32>(1)),
                prefix: row.get(2),
                cpm_warning: row.get::<_, i32>(3) as u32,
                cpm_critical: row.get::<_, i32>(4) as u32,
                acd_warning: row.get::<_, i32>(5) as f64,
                acd_critical: row.get::<_, i32>(6) as f64,
                total_calls_warning: row.get::<_, i32>(7) as u32,
                total_calls_critical: row.get::<_, i32>(8) as u32,
                concurrent_warning: row.get::<_, i32>(9) as u32,
                concurrent_critical: row.get::<_, i32>(10) as u32,
                start_hour: 0,
                end_hour: 23,
                days_of_week: 127,
                active: true,
            })
            .collect();

        Ok(profiles)
    }

    /// Health check
    pub async fn health_check(&self) -> Result<bool, DbError> {
        let client = self.pool.get().await?;
        let _ = client.query_one("SELECT 1", &[]).await?;
        Ok(true)
    }
}

// ==================== ClickHouse Client ====================

/// ClickHouse client for analytics and CDR storage
pub struct ClickHouseClient {
    client: clickhouse::Client,
}

impl ClickHouseClient {
    /// Create a new ClickHouse client
    pub async fn new(url: &str) -> Result<Self, DbError> {
        let client = clickhouse::Client::default()
            .with_url(url)
            .with_database("acm");

        // Test connection
        let _ = client
            .query("SELECT 1")
            .fetch_one::<u8>()
            .await
            .map_err(|e| DbError::ClickHouseError(e.to_string()))?;

        tracing::info!("Connected to ClickHouse");
        Ok(Self { client })
    }

    /// Insert CDR record
    pub async fn insert_cdr(&self, cdr: &CallDetailRecord) -> Result<(), DbError> {
        let mut insert = self.client.insert("cdrs")
            .map_err(|e| DbError::ClickHouseError(e.to_string()))?;

        insert.write(&CdrRow::from(cdr))
            .await
            .map_err(|e| DbError::ClickHouseError(e.to_string()))?;

        insert.end()
            .await
            .map_err(|e| DbError::ClickHouseError(e.to_string()))?;

        Ok(())
    }

    /// Insert batch of CDRs
    pub async fn insert_cdrs_batch(&self, cdrs: &[CallDetailRecord]) -> Result<(), DbError> {
        if cdrs.is_empty() {
            return Ok(());
        }

        let mut insert = self.client.insert("cdrs")
            .map_err(|e| DbError::ClickHouseError(e.to_string()))?;

        for cdr in cdrs {
            insert.write(&CdrRow::from(cdr))
                .await
                .map_err(|e| DbError::ClickHouseError(e.to_string()))?;
        }

        insert.end()
            .await
            .map_err(|e| DbError::ClickHouseError(e.to_string()))?;

        tracing::debug!("Inserted {} CDRs to ClickHouse", cdrs.len());
        Ok(())
    }

    /// Flush metrics to ClickHouse
    pub async fn flush_metrics(&self, metrics: &Metrics) -> Result<(), DbError> {
        let snapshot = metrics.snapshot();
        
        let row = MetricsRow {
            timestamp: Utc::now(),
            region: snapshot.region.clone(),
            node_id: snapshot.node_id.clone(),
            total_calls: snapshot.total_calls,
            fraud_detected: snapshot.fraud_detected,
            detection_latency_p50_us: snapshot.detection_latency_p50_us,
            detection_latency_p99_us: snapshot.detection_latency_p99_us,
            cache_hits: snapshot.cache_hits,
            cache_misses: snapshot.cache_misses,
            mnp_lookups: snapshot.mnp_lookups,
            replication_lag_secs: snapshot.replication_lag_secs,
        };

        let mut insert = self.client.insert("metrics")
            .map_err(|e| DbError::ClickHouseError(e.to_string()))?;

        insert.write(&row)
            .await
            .map_err(|e| DbError::ClickHouseError(e.to_string()))?;

        insert.end()
            .await
            .map_err(|e| DbError::ClickHouseError(e.to_string()))?;

        Ok(())
    }

    /// Get fraud statistics for a time range
    pub async fn get_fraud_stats(
        &self,
        start: DateTime<Utc>,
        end: DateTime<Utc>,
    ) -> Result<FraudStats, DbError> {
        let stats = self.client
            .query(
                "SELECT 
                    count() as total_calls,
                    countIf(fraud_type != '') as fraud_count,
                    countIf(fraud_type = 'masking') as masking_count,
                    countIf(fraud_type = 'simbox') as simbox_count,
                    avg(duration) as avg_duration
                 FROM cdrs 
                 WHERE start_time >= ? AND start_time < ?"
            )
            .bind(start)
            .bind(end)
            .fetch_one::<FraudStats>()
            .await
            .map_err(|e| DbError::ClickHouseError(e.to_string()))?;

        Ok(stats)
    }

    /// Health check
    pub async fn health_check(&self) -> Result<bool, DbError> {
        let _ = self.client
            .query("SELECT 1")
            .fetch_one::<u8>()
            .await
            .map_err(|e| DbError::ClickHouseError(e.to_string()))?;
        Ok(true)
    }
}

// ==================== ClickHouse Row Types ====================

#[derive(Debug, Clone, clickhouse::Row, serde::Serialize)]
struct CdrRow {
    id: String,
    call_id: String,
    caller_id: String,
    called_number: String,
    source_ip: String,
    start_time: DateTime<Utc>,
    duration: u32,
    disposition: String,
    sip_code: u16,
    fraud_type: String,
}

impl From<&CallDetailRecord> for CdrRow {
    fn from(cdr: &CallDetailRecord) -> Self {
        Self {
            id: cdr.id.to_string(),
            call_id: cdr.call_id.clone(),
            caller_id: cdr.caller_id.clone(),
            called_number: cdr.called_number.clone(),
            source_ip: cdr.source_ip.clone(),
            start_time: cdr.start_time,
            duration: cdr.duration,
            disposition: cdr.disposition.clone(),
            sip_code: cdr.sip_code,
            fraud_type: cdr.fraud_type.clone().unwrap_or_default(),
        }
    }
}

#[derive(Debug, Clone, clickhouse::Row, serde::Serialize)]
struct MetricsRow {
    timestamp: DateTime<Utc>,
    region: String,
    node_id: String,
    total_calls: u64,
    fraud_detected: u64,
    detection_latency_p50_us: u64,
    detection_latency_p99_us: u64,
    cache_hits: u64,
    cache_misses: u64,
    mnp_lookups: u64,
    replication_lag_secs: i64,
}

#[derive(Debug, Clone, clickhouse::Row, serde::Deserialize)]
pub struct FraudStats {
    pub total_calls: u64,
    pub fraud_count: u64,
    pub masking_count: u64,
    pub simbox_count: u64,
    pub avg_duration: f64,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    #[ignore]
    async fn test_yugabyte_connection() {
        let client = YugabyteClient::new("postgres://opensips:opensips@localhost:5433/acm")
            .await
            .expect("Failed to connect");
        
        assert!(client.health_check().await.unwrap());
    }

    #[tokio::test]
    #[ignore]
    async fn test_clickhouse_connection() {
        let client = ClickHouseClient::new("http://localhost:8123")
            .await
            .expect("Failed to connect");
        
        assert!(client.health_check().await.unwrap());
    }
}
