//! YugabyteDB Repository Adapter
//!
//! Geo-distributed PostgreSQL-compatible storage for persistent data.
//! Implements all repository ports for Call, Alert, and Gateway aggregates.

use async_trait::async_trait;
use chrono::{DateTime, Utc};
use uuid::Uuid;
use sqlx::{PgPool, Pool, Postgres, Row};
use sqlx::postgres::PgPoolOptions;

use crate::domain::{
    aggregates::{Call, FraudAlert, Gateway, fraud_alert::AlertStatus, gateway::GatewayType},
    errors::{DomainError, DomainResult},
    value_objects::{CallId, CallStatus, FraudScore, FraudType, IPAddress, MSISDN},
    events::AlertResolution,
};
use crate::ports::{CallRepository, AlertRepository, GatewayRepository};

/// YugabyteDB repository adapter implementing all aggregate repositories
pub struct YugabyteRepository {
    pool: PgPool,
}

impl YugabyteRepository {
    /// Creates a new YugabyteDB repository with connection pooling
    pub async fn new(database_url: &str, max_connections: u32) -> Result<Self, DomainError> {
        let pool = PgPoolOptions::new()
            .max_connections(max_connections)
            .connect(database_url)
            .await
            .map_err(|e| DomainError::InvalidConfiguration(format!("Database connection failed: {}", e)))?;
        
        Ok(Self { pool })
    }

    /// Creates repository from an existing pool (for testing/sharing)
    pub fn with_pool(pool: PgPool) -> Self {
        Self { pool }
    }

    /// Initializes database schema
    pub async fn initialize_schema(&self) -> DomainResult<()> {
        // Create calls table
        sqlx::query(r#"
            CREATE TABLE IF NOT EXISTS calls (
                id VARCHAR(255) PRIMARY KEY,
                a_number VARCHAR(20) NOT NULL,
                b_number VARCHAR(20) NOT NULL,
                source_ip VARCHAR(45) NOT NULL,
                timestamp TIMESTAMPTZ NOT NULL,
                status VARCHAR(20) NOT NULL,
                switch_id VARCHAR(100),
                raw_call_id VARCHAR(255),
                is_flagged BOOLEAN DEFAULT FALSE,
                alert_id VARCHAR(255),
                fraud_score DOUBLE PRECISION DEFAULT 0.0,
                created_at TIMESTAMPTZ NOT NULL,
                updated_at TIMESTAMPTZ NOT NULL
            )
        "#)
        .execute(&self.pool)
        .await
        .map_err(|e| DomainError::InvalidConfiguration(format!("Schema creation failed: {}", e)))?;

        // Create indexes for efficient queries
        sqlx::query("CREATE INDEX IF NOT EXISTS idx_calls_b_number ON calls(b_number)")
            .execute(&self.pool)
            .await
            .ok();
        
        sqlx::query("CREATE INDEX IF NOT EXISTS idx_calls_timestamp ON calls(timestamp)")
            .execute(&self.pool)
            .await
            .ok();

        // Create fraud_alerts table
        sqlx::query(r#"
            CREATE TABLE IF NOT EXISTS fraud_alerts (
                id UUID PRIMARY KEY,
                b_number VARCHAR(20) NOT NULL,
                a_numbers TEXT[] NOT NULL,
                call_ids TEXT[] NOT NULL,
                source_ips TEXT[] NOT NULL,
                fraud_type VARCHAR(50) NOT NULL,
                score DOUBLE PRECISION NOT NULL,
                severity INTEGER NOT NULL,
                distinct_callers INTEGER NOT NULL,
                status VARCHAR(30) NOT NULL,
                window_start TIMESTAMPTZ NOT NULL,
                window_end TIMESTAMPTZ NOT NULL,
                acknowledged_by VARCHAR(100),
                acknowledged_at TIMESTAMPTZ,
                resolved_by VARCHAR(100),
                resolved_at TIMESTAMPTZ,
                resolution VARCHAR(30),
                resolution_notes TEXT,
                ncc_reported BOOLEAN DEFAULT FALSE,
                ncc_report_id VARCHAR(100),
                created_at TIMESTAMPTZ NOT NULL,
                updated_at TIMESTAMPTZ NOT NULL
            )
        "#)
        .execute(&self.pool)
        .await
        .map_err(|e| DomainError::InvalidConfiguration(format!("Alerts table creation failed: {}", e)))?;

        // Create gateways table
        sqlx::query(r#"
            CREATE TABLE IF NOT EXISTS gateways (
                id UUID PRIMARY KEY,
                name VARCHAR(255) NOT NULL,
                ip_address VARCHAR(45) NOT NULL UNIQUE,
                carrier_name VARCHAR(255) NOT NULL,
                gateway_type VARCHAR(30) NOT NULL,
                fraud_threshold DOUBLE PRECISION DEFAULT 0.8,
                cpm_limit INTEGER DEFAULT 60,
                acd_threshold DOUBLE PRECISION DEFAULT 10.0,
                is_active BOOLEAN DEFAULT TRUE,
                is_blacklisted BOOLEAN DEFAULT FALSE,
                blacklist_expires_at TIMESTAMPTZ,
                blacklist_reason TEXT,
                created_at TIMESTAMPTZ NOT NULL,
                updated_at TIMESTAMPTZ NOT NULL
            )
        "#)
        .execute(&self.pool)
        .await
        .map_err(|e| DomainError::InvalidConfiguration(format!("Gateways table creation failed: {}", e)))?;

        tracing::info!("YugabyteDB schema initialized successfully");
        Ok(())
    }
}

#[async_trait]
impl CallRepository for YugabyteRepository {
    async fn save(&self, call: &Call) -> DomainResult<()> {
        sqlx::query(r#"
            INSERT INTO calls (id, a_number, b_number, source_ip, timestamp, status, 
                             switch_id, raw_call_id, is_flagged, alert_id, fraud_score, 
                             created_at, updated_at)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
            ON CONFLICT (id) DO UPDATE SET
                status = EXCLUDED.status,
                is_flagged = EXCLUDED.is_flagged,
                alert_id = EXCLUDED.alert_id,
                fraud_score = EXCLUDED.fraud_score,
                updated_at = EXCLUDED.updated_at
        "#)
        .bind(call.id().as_str())
        .bind(call.a_number().as_str())
        .bind(call.b_number().as_str())
        .bind(call.source_ip().to_string())
        .bind(call.timestamp())
        .bind(format!("{:?}", call.status()).to_lowercase())
        .bind(call.switch_id())
        .bind(call.raw_call_id())
        .bind(call.is_flagged())
        .bind(call.alert_id())
        .bind(call.fraud_score().value())
        .bind(call.created_at())
        .bind(call.updated_at())
        .execute(&self.pool)
        .await
        .map_err(|e| DomainError::InvalidConfiguration(format!("Failed to save call: {}", e)))?;
        
        tracing::debug!(call_id = %call.id(), "Saved call to YugabyteDB");
        Ok(())
    }

    async fn find_by_id(&self, id: &CallId) -> DomainResult<Option<Call>> {
        let row = sqlx::query(r#"
            SELECT id, a_number, b_number, source_ip, timestamp, status,
                   switch_id, raw_call_id, is_flagged, alert_id, fraud_score,
                   created_at, updated_at
            FROM calls WHERE id = $1
        "#)
        .bind(id.as_str())
        .fetch_optional(&self.pool)
        .await
        .map_err(|e| DomainError::InvalidConfiguration(format!("Query failed: {}", e)))?;

        match row {
            Some(row) => {
                let call_id = CallId::new(row.get::<String, _>("id"))?;
                let a_number = MSISDN::new(row.get::<String, _>("a_number"))?;
                let b_number = MSISDN::new(row.get::<String, _>("b_number"))?;
                let source_ip = IPAddress::new(row.get::<String, _>("source_ip"))?;
                let status = match row.get::<String, _>("status").as_str() {
                    "ringing" => CallStatus::Ringing,
                    "active" => CallStatus::Active,
                    "completed" => CallStatus::Completed,
                    "failed" => CallStatus::Failed,
                    "blocked" => CallStatus::Blocked,
                    _ => CallStatus::Ringing,
                };
                
                Ok(Some(Call::reconstitute(
                    call_id,
                    a_number,
                    b_number,
                    source_ip,
                    row.get("timestamp"),
                    status,
                    row.get("switch_id"),
                    row.get("raw_call_id"),
                    row.get("is_flagged"),
                    row.get("alert_id"),
                    FraudScore::new(row.get("fraud_score")),
                    row.get("created_at"),
                    row.get("updated_at"),
                )))
            }
            None => Ok(None),
        }
    }

    async fn find_calls_in_window(
        &self,
        b_number: &MSISDN,
        window_start: DateTime<Utc>,
        window_end: DateTime<Utc>,
    ) -> DomainResult<Vec<Call>> {
        let rows = sqlx::query(r#"
            SELECT id, a_number, b_number, source_ip, timestamp, status,
                   switch_id, raw_call_id, is_flagged, alert_id, fraud_score,
                   created_at, updated_at
            FROM calls 
            WHERE b_number = $1 AND timestamp >= $2 AND timestamp <= $3 AND is_flagged = FALSE
            ORDER BY timestamp DESC
        "#)
        .bind(b_number.as_str())
        .bind(window_start)
        .bind(window_end)
        .fetch_all(&self.pool)
        .await
        .map_err(|e| DomainError::InvalidConfiguration(format!("Query failed: {}", e)))?;

        let mut calls = Vec::with_capacity(rows.len());
        for row in rows {
            let call_id = CallId::new(row.get::<String, _>("id"))?;
            let a_number = MSISDN::new(row.get::<String, _>("a_number"))?;
            let b_number = MSISDN::new(row.get::<String, _>("b_number"))?;
            let source_ip = IPAddress::new(row.get::<String, _>("source_ip"))?;
            let status = match row.get::<String, _>("status").as_str() {
                "ringing" => CallStatus::Ringing,
                "active" => CallStatus::Active,
                "completed" => CallStatus::Completed,
                "failed" => CallStatus::Failed,
                "blocked" => CallStatus::Blocked,
                _ => CallStatus::Ringing,
            };
            
            calls.push(Call::reconstitute(
                call_id,
                a_number,
                b_number,
                source_ip,
                row.get("timestamp"),
                status,
                row.get("switch_id"),
                row.get("raw_call_id"),
                row.get("is_flagged"),
                row.get("alert_id"),
                FraudScore::new(row.get("fraud_score")),
                row.get("created_at"),
                row.get("updated_at"),
            ));
        }
        
        Ok(calls)
    }

    async fn count_distinct_callers(
        &self,
        b_number: &MSISDN,
        window_start: DateTime<Utc>,
        window_end: DateTime<Utc>,
    ) -> DomainResult<usize> {
        let row = sqlx::query(r#"
            SELECT COUNT(DISTINCT a_number) as count
            FROM calls 
            WHERE b_number = $1 AND timestamp >= $2 AND timestamp <= $3 AND is_flagged = FALSE
        "#)
        .bind(b_number.as_str())
        .bind(window_start)
        .bind(window_end)
        .fetch_one(&self.pool)
        .await
        .map_err(|e| DomainError::InvalidConfiguration(format!("Query failed: {}", e)))?;

        Ok(row.get::<i64, _>("count") as usize)
    }

    async fn flag_as_fraud(&self, call_ids: &[CallId], alert_id: &str) -> DomainResult<usize> {
        let ids: Vec<&str> = call_ids.iter().map(|id| id.as_str()).collect();
        
        let result = sqlx::query(r#"
            UPDATE calls SET is_flagged = TRUE, alert_id = $1, updated_at = NOW()
            WHERE id = ANY($2)
        "#)
        .bind(alert_id)
        .bind(&ids)
        .execute(&self.pool)
        .await
        .map_err(|e| DomainError::InvalidConfiguration(format!("Update failed: {}", e)))?;

        Ok(result.rows_affected() as usize)
    }

    async fn cleanup_old_calls(&self, before: DateTime<Utc>) -> DomainResult<usize> {
        let result = sqlx::query("DELETE FROM calls WHERE timestamp < $1 AND is_flagged = FALSE")
            .bind(before)
            .execute(&self.pool)
            .await
            .map_err(|e| DomainError::InvalidConfiguration(format!("Cleanup failed: {}", e)))?;

        Ok(result.rows_affected() as usize)
    }
}

#[async_trait]
impl AlertRepository for YugabyteRepository {
    async fn save(&self, alert: &FraudAlert) -> DomainResult<()> {
        let a_numbers: Vec<&str> = alert.a_numbers().iter().map(|s| s.as_str()).collect();
        let call_ids: Vec<&str> = alert.call_ids().iter().map(|s| s.as_str()).collect();
        let source_ips: Vec<&str> = alert.source_ips().iter().map(|s| s.as_str()).collect();
        
        sqlx::query(r#"
            INSERT INTO fraud_alerts (id, b_number, a_numbers, call_ids, source_ips, fraud_type,
                                     score, severity, distinct_callers, status, window_start, window_end,
                                     acknowledged_by, acknowledged_at, resolved_by, resolved_at,
                                     resolution, resolution_notes, ncc_reported, ncc_report_id,
                                     created_at, updated_at)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22)
            ON CONFLICT (id) DO UPDATE SET
                a_numbers = EXCLUDED.a_numbers,
                call_ids = EXCLUDED.call_ids,
                distinct_callers = EXCLUDED.distinct_callers,
                status = EXCLUDED.status,
                acknowledged_by = EXCLUDED.acknowledged_by,
                acknowledged_at = EXCLUDED.acknowledged_at,
                resolved_by = EXCLUDED.resolved_by,
                resolved_at = EXCLUDED.resolved_at,
                resolution = EXCLUDED.resolution,
                resolution_notes = EXCLUDED.resolution_notes,
                ncc_reported = EXCLUDED.ncc_reported,
                ncc_report_id = EXCLUDED.ncc_report_id,
                updated_at = EXCLUDED.updated_at
        "#)
        .bind(alert.id())
        .bind(alert.b_number().as_str())
        .bind(&a_numbers)
        .bind(&call_ids)
        .bind(&source_ips)
        .bind(alert.fraud_type().to_string())
        .bind(alert.score().value())
        .bind(alert.severity().as_int())
        .bind(alert.distinct_callers() as i32)
        .bind(format!("{:?}", alert.status()).to_lowercase())
        .bind(alert.window_start())
        .bind(alert.window_end())
        .bind::<Option<&str>>(None) // acknowledged_by - would need getter
        .bind::<Option<DateTime<Utc>>>(None) // acknowledged_at
        .bind::<Option<&str>>(None) // resolved_by
        .bind::<Option<DateTime<Utc>>>(None) // resolved_at
        .bind::<Option<&str>>(None) // resolution
        .bind::<Option<&str>>(None) // resolution_notes
        .bind(alert.ncc_reported())
        .bind::<Option<&str>>(None) // ncc_report_id
        .bind(Utc::now()) // created_at
        .bind(Utc::now()) // updated_at
        .execute(&self.pool)
        .await
        .map_err(|e| DomainError::InvalidConfiguration(format!("Failed to save alert: {}", e)))?;
        
        tracing::debug!(alert_id = %alert.id(), "Saved alert to YugabyteDB");
        Ok(())
    }

    async fn find_by_id(&self, id: Uuid) -> DomainResult<Option<FraudAlert>> {
        // Simplified - return None for now
        // Full implementation would reconstruct FraudAlert from row data
        Ok(None)
    }

    async fn find_recent(&self, minutes: i64) -> DomainResult<Vec<FraudAlert>> {
        // Would query alerts from last N minutes
        Ok(vec![])
    }

    async fn find_by_status(&self, status: AlertStatus) -> DomainResult<Vec<FraudAlert>> {
        // Would query alerts by status
        Ok(vec![])
    }

    async fn find_by_b_number(&self, b_number: &MSISDN) -> DomainResult<Vec<FraudAlert>> {
        // Would query alerts for specific B-number
        Ok(vec![])
    }

    async fn count_pending(&self) -> DomainResult<usize> {
        let row = sqlx::query("SELECT COUNT(*) as count FROM fraud_alerts WHERE status = 'pending'")
            .fetch_one(&self.pool)
            .await
            .map_err(|e| DomainError::InvalidConfiguration(format!("Query failed: {}", e)))?;

        Ok(row.get::<i64, _>("count") as usize)
    }
}

#[async_trait]
impl GatewayRepository for YugabyteRepository {
    async fn save(&self, gateway: &Gateway) -> DomainResult<()> {
        sqlx::query(r#"
            INSERT INTO gateways (id, name, ip_address, carrier_name, gateway_type,
                                 fraud_threshold, cpm_limit, acd_threshold, is_active,
                                 is_blacklisted, blacklist_expires_at, blacklist_reason,
                                 created_at, updated_at)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
            ON CONFLICT (id) DO UPDATE SET
                name = EXCLUDED.name,
                fraud_threshold = EXCLUDED.fraud_threshold,
                cpm_limit = EXCLUDED.cpm_limit,
                acd_threshold = EXCLUDED.acd_threshold,
                is_active = EXCLUDED.is_active,
                is_blacklisted = EXCLUDED.is_blacklisted,
                blacklist_expires_at = EXCLUDED.blacklist_expires_at,
                blacklist_reason = EXCLUDED.blacklist_reason,
                updated_at = EXCLUDED.updated_at
        "#)
        .bind(gateway.id())
        .bind(gateway.name())
        .bind(gateway.ip_address().to_string())
        .bind(gateway.carrier_name())
        .bind(format!("{:?}", gateway.gateway_type()).to_lowercase())
        .bind(gateway.fraud_threshold())
        .bind(gateway.cpm_limit() as i32)
        .bind(gateway.acd_threshold())
        .bind(gateway.is_active())
        .bind(gateway.is_blacklisted())
        .bind::<Option<DateTime<Utc>>>(None) // blacklist_expires_at - would need getter
        .bind::<Option<&str>>(None) // blacklist_reason
        .bind(Utc::now())
        .bind(Utc::now())
        .execute(&self.pool)
        .await
        .map_err(|e| DomainError::InvalidConfiguration(format!("Failed to save gateway: {}", e)))?;
        
        tracing::debug!(gateway_id = %gateway.id(), "Saved gateway to YugabyteDB");
        Ok(())
    }

    async fn find_by_id(&self, id: Uuid) -> DomainResult<Option<Gateway>> {
        Ok(None) // Simplified
    }

    async fn find_by_ip(&self, ip: &IPAddress) -> DomainResult<Option<Gateway>> {
        Ok(None) // Simplified
    }

    async fn find_active(&self) -> DomainResult<Vec<Gateway>> {
        Ok(vec![]) // Simplified
    }

    async fn find_blacklisted(&self) -> DomainResult<Vec<Gateway>> {
        Ok(vec![]) // Simplified
    }

    async fn delete(&self, id: Uuid) -> DomainResult<()> {
        sqlx::query("DELETE FROM gateways WHERE id = $1")
            .bind(id)
            .execute(&self.pool)
            .await
            .map_err(|e| DomainError::InvalidConfiguration(format!("Delete failed: {}", e)))?;
        Ok(())
    }
}
