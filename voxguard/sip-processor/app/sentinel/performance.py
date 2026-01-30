"""Performance optimization utilities for Sentinel Engine.

This module provides caching, connection pooling, and performance monitoring
utilities for production deployments.
"""

import time
import functools
from typing import Any, Callable, Optional, Dict
from datetime import datetime, timedelta
import asyncio
import logging

logger = logging.getLogger(__name__)


class SimpleCache:
    """Simple in-memory cache with TTL support for frequently accessed data."""

    def __init__(self, default_ttl_seconds: int = 300):
        """Initialize cache with default TTL.

        Args:
            default_ttl_seconds: Default time-to-live for cached items (default: 5 minutes)
        """
        self._cache: Dict[str, tuple[Any, datetime]] = {}
        self._default_ttl = default_ttl_seconds
        self._hits = 0
        self._misses = 0
        self._lock = asyncio.Lock()

    async def get(self, key: str) -> Optional[Any]:
        """Get value from cache if not expired.

        Args:
            key: Cache key

        Returns:
            Cached value or None if not found/expired
        """
        async with self._lock:
            if key not in self._cache:
                self._misses += 1
                return None

            value, expires_at = self._cache[key]
            if datetime.now() > expires_at:
                del self._cache[key]
                self._misses += 1
                return None

            self._hits += 1
            return value

    async def set(self, key: str, value: Any, ttl_seconds: Optional[int] = None):
        """Set value in cache with TTL.

        Args:
            key: Cache key
            value: Value to cache
            ttl_seconds: Time-to-live in seconds (uses default if not specified)
        """
        ttl = ttl_seconds if ttl_seconds is not None else self._default_ttl
        expires_at = datetime.now() + timedelta(seconds=ttl)

        async with self._lock:
            self._cache[key] = (value, expires_at)

    async def delete(self, key: str):
        """Delete key from cache.

        Args:
            key: Cache key to delete
        """
        async with self._lock:
            self._cache.pop(key, None)

    async def clear(self):
        """Clear all cached items."""
        async with self._lock:
            self._cache.clear()
            self._hits = 0
            self._misses = 0

    def get_stats(self) -> Dict[str, Any]:
        """Get cache statistics.

        Returns:
            Dictionary with cache hits, misses, and hit rate
        """
        total = self._hits + self._misses
        hit_rate = (self._hits / total * 100) if total > 0 else 0

        return {
            "hits": self._hits,
            "misses": self._misses,
            "hit_rate": round(hit_rate, 2),
            "size": len(self._cache)
        }


# Global cache instance
_sentinel_cache = SimpleCache(default_ttl_seconds=300)


def get_cache() -> SimpleCache:
    """Get global cache instance.

    Returns:
        Global SimpleCache instance
    """
    return _sentinel_cache


def cached(ttl_seconds: int = 300, key_prefix: str = ""):
    """Decorator to cache function results.

    Args:
        ttl_seconds: Cache time-to-live in seconds
        key_prefix: Prefix for cache keys

    Example:
        @cached(ttl_seconds=60, key_prefix="alerts")
        async def get_alerts(severity: str):
            return await fetch_alerts(severity)
    """
    def decorator(func: Callable):
        @functools.wraps(func)
        async def wrapper(*args, **kwargs):
            # Generate cache key from function name and arguments
            cache_key = f"{key_prefix}:{func.__name__}:{str(args)}:{str(kwargs)}"

            # Try to get from cache
            cached_value = await _sentinel_cache.get(cache_key)
            if cached_value is not None:
                logger.debug(f"Cache hit for {cache_key}")
                return cached_value

            # Execute function and cache result
            logger.debug(f"Cache miss for {cache_key}")
            result = await func(*args, **kwargs)
            await _sentinel_cache.set(cache_key, result, ttl_seconds)
            return result

        return wrapper
    return decorator


class PerformanceMonitor:
    """Monitor and track performance metrics for Sentinel operations."""

    def __init__(self):
        self._metrics: Dict[str, list[float]] = {}
        self._lock = asyncio.Lock()

    async def record(self, operation: str, duration_seconds: float):
        """Record operation duration.

        Args:
            operation: Name of the operation
            duration_seconds: Duration in seconds
        """
        async with self._lock:
            if operation not in self._metrics:
                self._metrics[operation] = []
            self._metrics[operation].append(duration_seconds)

            # Keep only last 1000 measurements per operation
            if len(self._metrics[operation]) > 1000:
                self._metrics[operation] = self._metrics[operation][-1000:]

    def get_stats(self, operation: str) -> Optional[Dict[str, float]]:
        """Get statistics for an operation.

        Args:
            operation: Name of the operation

        Returns:
            Dictionary with min, max, avg, p95, p99 or None if no data
        """
        if operation not in self._metrics or not self._metrics[operation]:
            return None

        durations = sorted(self._metrics[operation])
        count = len(durations)

        return {
            "count": count,
            "min": round(min(durations), 3),
            "max": round(max(durations), 3),
            "avg": round(sum(durations) / count, 3),
            "p50": round(durations[int(count * 0.5)], 3),
            "p95": round(durations[int(count * 0.95)], 3),
            "p99": round(durations[int(count * 0.99)], 3)
        }

    def get_all_stats(self) -> Dict[str, Dict[str, float]]:
        """Get statistics for all operations.

        Returns:
            Dictionary mapping operation names to their statistics
        """
        return {
            operation: self.get_stats(operation)
            for operation in self._metrics.keys()
        }


# Global performance monitor
_performance_monitor = PerformanceMonitor()


def get_performance_monitor() -> PerformanceMonitor:
    """Get global performance monitor instance.

    Returns:
        Global PerformanceMonitor instance
    """
    return _performance_monitor


def monitor_performance(operation_name: str):
    """Decorator to monitor function performance.

    Args:
        operation_name: Name to identify the operation in metrics

    Example:
        @monitor_performance("detect_sdhf")
        async def detect_sdhf_patterns():
            # ... detection logic
    """
    def decorator(func: Callable):
        @functools.wraps(func)
        async def wrapper(*args, **kwargs):
            start_time = time.time()
            try:
                result = await func(*args, **kwargs)
                return result
            finally:
                duration = time.time() - start_time
                await _performance_monitor.record(operation_name, duration)
                logger.info(f"{operation_name} completed in {duration:.3f}s")

        return wrapper
    return decorator


class BatchProcessor:
    """Efficient batch processing utility with configurable batch size."""

    @staticmethod
    async def process_in_batches(
        items: list,
        process_func: Callable,
        batch_size: int = 1000,
        concurrency: int = 5
    ) -> list:
        """Process items in batches with controlled concurrency.

        Args:
            items: List of items to process
            process_func: Async function to process each batch
            batch_size: Number of items per batch
            concurrency: Number of concurrent batch operations

        Returns:
            List of results from all batches
        """
        results = []
        batches = [
            items[i:i + batch_size]
            for i in range(0, len(items), batch_size)
        ]

        # Process batches with controlled concurrency
        semaphore = asyncio.Semaphore(concurrency)

        async def process_batch(batch):
            async with semaphore:
                return await process_func(batch)

        tasks = [process_batch(batch) for batch in batches]
        batch_results = await asyncio.gather(*tasks)

        for result in batch_results:
            if isinstance(result, list):
                results.extend(result)
            else:
                results.append(result)

        return results


# Database connection pool configuration
class PoolConfig:
    """Database connection pool configuration for production."""

    # Connection pool settings
    MIN_POOL_SIZE = 10
    MAX_POOL_SIZE = 50
    MAX_QUERIES = 50000  # Max queries per connection before recycling
    MAX_INACTIVE_CONNECTION_LIFETIME = 300  # 5 minutes
    POOL_TIMEOUT = 30  # Connection acquire timeout

    # Query optimization settings
    BATCH_INSERT_SIZE = 1000
    QUERY_TIMEOUT = 30  # Query execution timeout

    # Cache settings
    CACHE_ENABLED = True
    CACHE_TTL_SECONDS = 300  # 5 minutes
    ALERT_CACHE_TTL = 60  # 1 minute for alerts (more dynamic data)

    @classmethod
    def get_pool_kwargs(cls) -> Dict[str, Any]:
        """Get connection pool kwargs for asyncpg.

        Returns:
            Dictionary of connection pool parameters
        """
        return {
            "min_size": cls.MIN_POOL_SIZE,
            "max_size": cls.MAX_POOL_SIZE,
            "max_queries": cls.MAX_QUERIES,
            "max_inactive_connection_lifetime": cls.MAX_INACTIVE_CONNECTION_LIFETIME,
            "timeout": cls.POOL_TIMEOUT,
            "command_timeout": cls.QUERY_TIMEOUT
        }
