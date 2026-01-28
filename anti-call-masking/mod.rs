//! Cache management using DragonflyDB.
//!
//! Provides high-performance caching with:
//! - MNP lookup caching
//! - Blacklist caching
//! - Caller metrics (CPM, ACD)
//! - Gateway profiles
//! - Replication lag monitoring

use crate::models::{CallerMetrics, CachedMnp, MnpRecord};
use deadpool_redis::{Config, Pool, Runtime};
use redis::{AsyncCommands, RedisError};
use serde::{de::DeserializeOwned, Serialize};
use std::time::Duration;
use thiserror::Error;

#[derive(Debug, Error)]
pub enum CacheError {
    #[error("Redis connection error: {0}")]
    ConnectionError(#[from] RedisError),

    #[error("Pool error: {0}")]
    PoolError(#[from] deadpool_redis::PoolError),

    #[error("Serialization error: {0}")]
    SerializationError(#[from] serde_json::Error),

    #[error("Cache miss for key: {0}")]
    CacheMiss(String),

    #[error("Invalid data format")]
    InvalidFormat,
}

/// Cache key prefixes
pub mod keys {
    pub const MNP: &str = "mnp:";
    pub const BLACKLIST: &str = "blacklist:";
    pub const BLACKLIST_SET: &str = "blacklist_ips";
    pub const GATEWAY: &str = "gateway:";
    pub const GATEWAY_GROUP: &str = "gateway_grp:";
    pub const CALLER_METRICS: &str = "metrics:";
    pub const CALL_TIMESTAMPS: &str = "calls:";
    pub const UNIQUE_DST: &str = "dst:";
    pub const REPLICATION_INFO: &str = "INFO";
}

/// Cache manager for DragonflyDB operations
pub struct CacheManager {
    pool: Pool,
    fallback_pool: Option<Pool>,
    default_ttl: Duration,
}

impl CacheManager {
    /// Create a new cache manager
    pub async fn new(redis_url: &str) -> Result<Self, CacheError> {
        let cfg = Config::from_url(redis_url);
        let pool = cfg
            .create_pool(Some(Runtime::Tokio1))
            .map_err(|e| CacheError::ConnectionError(RedisError::from((redis::ErrorKind::IoError, "Pool creation failed", e.to_string()))))?;

        // Test connection
        let mut conn = pool.get().await?;
        let _: String = redis::cmd("PING").query_async(&mut *conn).await?;

        Ok(Self {
            pool,
            fallback_pool: None,
            default_ttl: Duration::from_secs(3600),
        })
    }

    /// Create with fallback URL for failover
    pub async fn with_fallback(redis_url: &str, fallback_url: &str) -> Result<Self, CacheError> {
        let mut manager = Self::new(redis_url).await?;

        let cfg = Config::from_url(fallback_url);
        if let Ok(pool) = cfg.create_pool(Some(Runtime::Tokio1)) {
            manager.fallback_pool = Some(pool);
        }

        Ok(manager)
    }

    /// Get a connection (with fallback on failure)
    async fn get_conn(&self) -> Result<deadpool_redis::Connection, CacheError> {
        match self.pool.get().await {
            Ok(conn) => Ok(conn),
            Err(e) => {
                if let Some(ref fallback) = self.fallback_pool {
                    tracing::warn!("Primary cache failed, using fallback: {}", e);
                    Ok(fallback.get().await?)
                } else {
                    Err(CacheError::PoolError(e))
                }
            }
        }
    }

    // ==================== MNP Operations ====================

    /// Get MNP record from cache
    pub async fn get_mnp(&self, msisdn: &str) -> Result<Option<CachedMnp>, CacheError> {
        let key = format!("{}{}", keys::MNP, msisdn);
        self.get_json(&key).await
    }

    /// Set MNP record in cache
    pub async fn set_mnp(&self, msisdn: &str, record: &MnpRecord) -> Result<(), CacheError> {
        let key = format!("{}{}", keys::MNP, msisdn);
        let cached = CachedMnp {
            is_ported: record.is_ported,
            operator: record.hosting_network.clone(),
            routing_number: record.routing_number.clone(),
        };
        self.set_json_ex(&key, &cached, 3600).await
    }

    // ==================== Blacklist Operations ====================

    /// Check if IP is blacklisted
    pub async fn is_blacklisted(&self, ip: &str) -> Result<bool, CacheError> {
        let mut conn = self.get_conn().await?;
        let exists: bool = conn.sismember(keys::BLACKLIST_SET, ip).await?;
        Ok(exists)
    }

    /// Add IP to blacklist
    pub async fn add_to_blacklist(&self, ip: &str, reason: &str) -> Result<(), CacheError> {
        let mut conn = self.get_conn().await?;
        
        // Add to set
        let _: () = conn.sadd(keys::BLACKLIST_SET, ip).await?;
        
        // Store reason
        let key = format!("{}{}", keys::BLACKLIST, ip);
        let _: () = conn.set_ex(&key, reason, 86400).await?;
        
        Ok(())
    }

    /// Remove IP from blacklist
    pub async fn remove_from_blacklist(&self, ip: &str) -> Result<(), CacheError> {
        let mut conn = self.get_conn().await?;
        let _: () = conn.srem(keys::BLACKLIST_SET, ip).await?;
        let key = format!("{}{}", keys::BLACKLIST, ip);
        let _: () = conn.del(&key).await?;
        Ok(())
    }

    /// Get all blacklisted IPs
    pub async fn get_all_blacklisted(&self) -> Result<Vec<String>, CacheError> {
        let mut conn = self.get_conn().await?;
        let ips: Vec<String> = conn.smembers(keys::BLACKLIST_SET).await?;
        Ok(ips)
    }

    /// Sync blacklist from database (bulk operation)
    pub async fn sync_blacklist(&self, ips: &[String]) -> Result<(), CacheError> {
        let mut conn = self.get_conn().await?;
        
        // Clear existing
        let _: () = conn.del(keys::BLACKLIST_SET).await?;
        
        // Add all new IPs
        if !ips.is_empty() {
            let _: () = conn.sadd(keys::BLACKLIST_SET, ips).await?;
        }
        
        tracing::info!("Synced {} IPs to blacklist cache", ips.len());
        Ok(())
    }

    // ==================== Gateway Operations ====================

    /// Check if IP belongs to a gateway group
    pub async fn is_gateway_group(&self, ip: &str, group_id: u8) -> Result<bool, CacheError> {
        let key = format!("{}{}",keys::GATEWAY_GROUP, group_id);
        let mut conn = self.get_conn().await?;
        let exists: bool = conn.sismember(&key, ip).await?;
        Ok(exists)
    }

    /// Add IP to gateway group
    pub async fn add_to_gateway_group(&self, ip: &str, group_id: u8) -> Result<(), CacheError> {
        let key = format!("{}{}", keys::GATEWAY_GROUP, group_id);
        let mut conn = self.get_conn().await?;
        let _: () = conn.sadd(&key, ip).await?;
        Ok(())
    }

    /// Sync gateway group from database
    pub async fn sync_gateway_group(&self, group_id: u8, ips: &[String]) -> Result<(), CacheError> {
        let key = format!("{}{}", keys::GATEWAY_GROUP, group_id);
        let mut conn = self.get_conn().await?;
        
        // Clear and rebuild
        let _: () = conn.del(&key).await?;
        if !ips.is_empty() {
            let _: () = conn.sadd(&key, ips).await?;
        }
        
        tracing::info!("Synced {} IPs to gateway group {}", ips.len(), group_id);
        Ok(())
    }

    // ==================== Caller Metrics Operations ====================

    /// Get caller metrics
    pub async fn get_caller_metrics(&self, caller_id: &str) -> Result<CallerMetrics, CacheError> {
        let key = format!("{}{}", keys::CALLER_METRICS, caller_id);
        
        match self.get_json::<CallerMetrics>(&key).await? {
            Some(metrics) => Ok(metrics),
            None => Ok(CallerMetrics::default()),
        }
    }

    /// Record a call and update metrics
    pub async fn record_call(
        &self,
        caller_id: &str,
        called_number: &str,
    ) -> Result<u32, CacheError> {
        let mut conn = self.get_conn().await?;
        let now = chrono::Utc::now().timestamp();

        // Use Redis pipeline for atomic operations
        let mut pipe = redis::pipe();
        
        // Add timestamp to sorted set (for CPM calculation)
        let ts_key = format!("{}{}", keys::CALL_TIMESTAMPS, caller_id);
        pipe.zadd(&ts_key, now, now);
        
        // Remove old timestamps (older than 60 seconds)
        let cutoff = now - 60;
        pipe.zrembyscore(&ts_key, "-inf", cutoff);
        
        // Set TTL on the key
        pipe.expire(&ts_key, 300);
        
        // Add to unique destinations set
        let dst_key = format!("{}{}", keys::UNIQUE_DST, caller_id);
        pipe.sadd(&dst_key, called_number);
        pipe.expire(&dst_key, 300);
        
        // Execute pipeline
        let _: () = pipe.query_async(&mut *conn).await?;
        
        // Get CPM (calls in last 60 seconds)
        let cpm: u32 = conn.zcount(&ts_key, cutoff, "+inf").await?;
        
        Ok(cpm)
    }

    /// Record call duration
    pub async fn record_call_duration(
        &self,
        caller_id: &str,
        duration_secs: u32,
    ) -> Result<(), CacheError> {
        let mut conn = self.get_conn().await?;
        let key = format!("{}{}:acd", keys::CALLER_METRICS, caller_id);
        
        // Use hash for count and total
        let mut pipe = redis::pipe();
        pipe.hincr(&key, "count", 1i64);
        pipe.hincr(&key, "total", duration_secs as i64);
        pipe.expire(&key, 300);
        
        let _: () = pipe.query_async(&mut *conn).await?;
        Ok(())
    }

    /// Get average call duration for a caller
    pub async fn get_acd(&self, caller_id: &str) -> Result<Option<f64>, CacheError> {
        let mut conn = self.get_conn().await?;
        let key = format!("{}{}:acd", keys::CALLER_METRICS, caller_id);
        
        let result: Option<(i64, i64)> = redis::pipe()
            .hget(&key, "count")
            .hget(&key, "total")
            .query_async(&mut *conn)
            .await
            .ok();
        
        match result {
            Some((count, total)) if count > 0 => Ok(Some(total as f64 / count as f64)),
            _ => Ok(None),
        }
    }

    // ==================== Replication Monitoring ====================

    /// Check replication lag (for geo-distributed setup)
    pub async fn check_replication_lag(&self) -> Result<i64, CacheError> {
        let mut conn = self.get_conn().await?;
        let info: String = redis::cmd("INFO")
            .arg("replication")
            .query_async(&mut *conn)
            .await?;
        
        // Parse replication info
        // Look for "master_link_down_since_seconds:-1" or lag value
        for line in info.lines() {
            if line.starts_with("master_link_down_since_seconds:") {
                if let Some(val) = line.split(':').nth(1) {
                    if let Ok(lag) = val.trim().parse::<i64>() {
                        if lag == -1 {
                            return Ok(0); // Connected, no lag
                        }
                        return Ok(lag);
                    }
                }
            }
            // Alternative: check slave lag
            if line.contains("lag=") {
                if let Some(lag_part) = line.split("lag=").nth(1) {
                    if let Some(lag_str) = lag_part.split(',').next() {
                        if let Ok(lag) = lag_str.trim().parse::<i64>() {
                            return Ok(lag);
                        }
                    }
                }
            }
        }
        
        Ok(0) // No replication info found, assume no lag
    }

    // ==================== Generic Operations ====================

    /// Get JSON value from cache
    async fn get_json<T: DeserializeOwned>(&self, key: &str) -> Result<Option<T>, CacheError> {
        let mut conn = self.get_conn().await?;
        let value: Option<String> = conn.get(key).await?;
        
        match value {
            Some(json) => Ok(Some(serde_json::from_str(&json)?)),
            None => Ok(None),
        }
    }

    /// Set JSON value with expiration
    async fn set_json_ex<T: Serialize>(
        &self,
        key: &str,
        value: &T,
        ttl_secs: u64,
    ) -> Result<(), CacheError> {
        let mut conn = self.get_conn().await?;
        let json = serde_json::to_string(value)?;
        let _: () = conn.set_ex(key, json, ttl_secs).await?;
        Ok(())
    }

    /// Delete a key
    pub async fn delete(&self, key: &str) -> Result<(), CacheError> {
        let mut conn = self.get_conn().await?;
        let _: () = conn.del(key).await?;
        Ok(())
    }

    /// Check if a key exists
    pub async fn exists(&self, key: &str) -> Result<bool, CacheError> {
        let mut conn = self.get_conn().await?;
        let exists: bool = conn.exists(key).await?;
        Ok(exists)
    }

    /// Get pool statistics
    pub fn pool_stats(&self) -> PoolStats {
        let status = self.pool.status();
        PoolStats {
            size: status.size as u32,
            available: status.available as u32,
            waiting: status.waiting as u32,
        }
    }
}

/// Pool statistics
#[derive(Debug, Clone)]
pub struct PoolStats {
    pub size: u32,
    pub available: u32,
    pub waiting: u32,
}

#[cfg(test)]
mod tests {
    use super::*;

    // Note: These tests require a running DragonflyDB instance
    // Run with: cargo test -- --ignored

    #[tokio::test]
    #[ignore]
    async fn test_cache_connection() {
        let cache = CacheManager::new("redis://127.0.0.1:6379")
            .await
            .expect("Failed to create cache");
        
        assert!(cache.pool_stats().available > 0);
    }

    #[tokio::test]
    #[ignore]
    async fn test_blacklist_operations() {
        let cache = CacheManager::new("redis://127.0.0.1:6379")
            .await
            .expect("Failed to create cache");
        
        // Add to blacklist
        cache.add_to_blacklist("192.168.1.1", "test").await.unwrap();
        
        // Check if blacklisted
        assert!(cache.is_blacklisted("192.168.1.1").await.unwrap());
        assert!(!cache.is_blacklisted("192.168.1.2").await.unwrap());
        
        // Remove from blacklist
        cache.remove_from_blacklist("192.168.1.1").await.unwrap();
        assert!(!cache.is_blacklisted("192.168.1.1").await.unwrap());
    }

    #[tokio::test]
    #[ignore]
    async fn test_cpm_tracking() {
        let cache = CacheManager::new("redis://127.0.0.1:6379")
            .await
            .expect("Failed to create cache");
        
        let caller = "+2348031234567";
        
        // Record 5 calls
        for i in 0..5 {
            let cpm = cache.record_call(caller, &format!("+23480512345{:02}", i)).await.unwrap();
            assert_eq!(cpm, i as u32 + 1);
        }
    }
}
