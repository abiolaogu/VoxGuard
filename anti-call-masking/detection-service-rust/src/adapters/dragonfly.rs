//! DragonflyDB Cache Adapter
//!
//! High-performance Redis-compatible cache for sliding window detection.

use async_trait::async_trait;
use redis::{AsyncCommands, Client};
use std::sync::Arc;
use tokio::sync::RwLock;

use crate::domain::{
    errors::{DomainError, DomainResult},
    value_objects::{IPAddress, MSISDN},
};
use crate::ports::DetectionCache;

/// DragonflyDB cache adapter implementing DetectionCache port
pub struct DragonflyCache {
    client: Client,
    pool_size: usize,
}

impl DragonflyCache {
    /// Creates a new DragonflyDB cache adapter
    pub fn new(redis_url: &str, pool_size: usize) -> Result<Self, DomainError> {
        let client = Client::open(redis_url)
            .map_err(|e| DomainError::InvalidConfiguration(format!("Redis connection error: {}", e)))?;

        Ok(Self { client, pool_size })
    }

    /// Gets an async connection from the pool
    async fn get_connection(&self) -> DomainResult<redis::aio::MultiplexedConnection> {
        self.client
            .get_multiplexed_async_connection()
            .await
            .map_err(|e| DomainError::InvalidConfiguration(format!("Connection error: {}", e)))
    }
}

#[async_trait]
impl DetectionCache for DragonflyCache {
    async fn add_caller_to_window(
        &self,
        b_number: &MSISDN,
        a_number: &MSISDN,
        window_seconds: u32,
    ) -> DomainResult<()> {
        let mut conn = self.get_connection().await?;
        let key = format!("window:{}", b_number);

        // Use pipeline for atomicity and performance
        let _: () = redis::pipe()
            .sadd(&key, a_number.as_str())
            .expire(&key, window_seconds as i64)
            .query_async(&mut conn)
            .await
            .map_err(|e| DomainError::InvalidConfiguration(format!("Cache error: {}", e)))?;

        Ok(())
    }

    async fn get_distinct_caller_count(&self, b_number: &MSISDN) -> DomainResult<usize> {
        let mut conn = self.get_connection().await?;
        let key = format!("window:{}", b_number);

        let count: usize = conn
            .scard(&key)
            .await
            .map_err(|e| DomainError::InvalidConfiguration(format!("Cache error: {}", e)))?;

        Ok(count)
    }

    async fn get_distinct_callers(&self, b_number: &MSISDN) -> DomainResult<Vec<String>> {
        let mut conn = self.get_connection().await?;
        let key = format!("window:{}", b_number);

        let members: Vec<String> = conn
            .smembers(&key)
            .await
            .map_err(|e| DomainError::InvalidConfiguration(format!("Cache error: {}", e)))?;

        Ok(members)
    }

    async fn is_in_cooldown(&self, b_number: &MSISDN) -> DomainResult<bool> {
        let mut conn = self.get_connection().await?;
        let key = format!("cooldown:{}", b_number);

        let exists: bool = conn
            .exists(&key)
            .await
            .map_err(|e| DomainError::InvalidConfiguration(format!("Cache error: {}", e)))?;

        Ok(exists)
    }

    async fn set_cooldown(&self, b_number: &MSISDN, seconds: u32) -> DomainResult<()> {
        let mut conn = self.get_connection().await?;
        let key = format!("cooldown:{}", b_number);

        conn.set_ex(&key, "1", seconds as u64)
            .await
            .map_err(|e| DomainError::InvalidConfiguration(format!("Cache error: {}", e)))?;

        Ok(())
    }

    async fn is_ip_blacklisted(&self, ip: &IPAddress) -> DomainResult<bool> {
        let mut conn = self.get_connection().await?;
        let key = format!("blacklist:ip:{}", ip);

        let exists: bool = conn
            .exists(&key)
            .await
            .map_err(|e| DomainError::InvalidConfiguration(format!("Cache error: {}", e)))?;

        Ok(exists)
    }

    async fn add_to_blacklist(&self, ip: &IPAddress, ttl_seconds: Option<u32>) -> DomainResult<()> {
        let mut conn = self.get_connection().await?;
        let key = format!("blacklist:ip:{}", ip);

        if let Some(ttl) = ttl_seconds {
            conn.set_ex(&key, "1", ttl as u64)
                .await
                .map_err(|e| DomainError::InvalidConfiguration(format!("Cache error: {}", e)))?;
        } else {
            conn.set(&key, "1")
                .await
                .map_err(|e| DomainError::InvalidConfiguration(format!("Cache error: {}", e)))?;
        }

        Ok(())
    }
}
