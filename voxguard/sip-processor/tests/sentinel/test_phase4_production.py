"""
Tests for Phase 4 Production Features

Tests for performance optimization, metrics collection, and production configurations.
"""

import pytest
import asyncio
from datetime import datetime, timedelta


# ============================================================================
# Performance Module Tests
# ============================================================================

class TestSimpleCache:
    """Test suite for SimpleCache functionality."""

    @pytest.mark.asyncio
    async def test_cache_set_and_get(self):
        """Test basic cache set and get operations."""
        from app.sentinel.performance import SimpleCache

        cache = SimpleCache(default_ttl_seconds=60)
        await cache.set("test_key", "test_value")

        value = await cache.get("test_key")
        assert value == "test_value"

    @pytest.mark.asyncio
    async def test_cache_expiration(self):
        """Test that cached items expire after TTL."""
        from app.sentinel.performance import SimpleCache

        cache = SimpleCache(default_ttl_seconds=1)
        await cache.set("expire_key", "expire_value", ttl_seconds=1)

        # Value should exist immediately
        value = await cache.get("expire_key")
        assert value == "expire_value"

        # Wait for expiration
        await asyncio.sleep(1.5)

        # Value should be expired
        value = await cache.get("expire_key")
        assert value is None

    @pytest.mark.asyncio
    async def test_cache_delete(self):
        """Test cache key deletion."""
        from app.sentinel.performance import SimpleCache

        cache = SimpleCache()
        await cache.set("delete_key", "delete_value")

        # Verify key exists
        value = await cache.get("delete_key")
        assert value == "delete_value"

        # Delete key
        await cache.delete("delete_key")

        # Verify key is gone
        value = await cache.get("delete_key")
        assert value is None

    @pytest.mark.asyncio
    async def test_cache_clear(self):
        """Test clearing all cache entries."""
        from app.sentinel.performance import SimpleCache

        cache = SimpleCache()
        await cache.set("key1", "value1")
        await cache.set("key2", "value2")
        await cache.set("key3", "value3")

        # Clear cache
        await cache.clear()

        # All keys should be gone
        assert await cache.get("key1") is None
        assert await cache.get("key2") is None
        assert await cache.get("key3") is None

    @pytest.mark.asyncio
    async def test_cache_statistics(self):
        """Test cache hit/miss statistics."""
        from app.sentinel.performance import SimpleCache

        cache = SimpleCache()

        # Set some values
        await cache.set("hit1", "value1")
        await cache.set("hit2", "value2")

        # Generate hits and misses
        await cache.get("hit1")  # Hit
        await cache.get("hit1")  # Hit
        await cache.get("hit2")  # Hit
        await cache.get("miss1")  # Miss
        await cache.get("miss2")  # Miss

        stats = cache.get_stats()
        assert stats["hits"] == 3
        assert stats["misses"] == 2
        assert stats["hit_rate"] == 60.0  # 3/5 = 60%
        assert stats["size"] == 2  # Two keys in cache

    @pytest.mark.asyncio
    async def test_cached_decorator(self):
        """Test the @cached decorator."""
        from app.sentinel.performance import cached, get_cache

        call_count = {"count": 0}

        @cached(ttl_seconds=60, key_prefix="test")
        async def expensive_function(param: str):
            call_count["count"] += 1
            return f"result_{param}"

        # First call - should execute function
        result1 = await expensive_function("test")
        assert result1 == "result_test"
        assert call_count["count"] == 1

        # Second call with same param - should use cache
        result2 = await expensive_function("test")
        assert result2 == "result_test"
        assert call_count["count"] == 1  # Function not called again

        # Call with different param - should execute function
        result3 = await expensive_function("other")
        assert result3 == "result_other"
        assert call_count["count"] == 2

        # Clear cache for cleanup
        await get_cache().clear()


class TestPerformanceMonitor:
    """Test suite for PerformanceMonitor."""

    @pytest.mark.asyncio
    async def test_record_and_get_stats(self):
        """Test recording operation durations and retrieving statistics."""
        from app.sentinel.performance import PerformanceMonitor

        monitor = PerformanceMonitor()

        # Record some durations
        await monitor.record("test_operation", 0.1)
        await monitor.record("test_operation", 0.2)
        await monitor.record("test_operation", 0.3)
        await monitor.record("test_operation", 0.5)
        await monitor.record("test_operation", 1.0)

        stats = monitor.get_stats("test_operation")
        assert stats is not None
        assert stats["count"] == 5
        assert stats["min"] == 0.1
        assert stats["max"] == 1.0
        assert 0.4 <= stats["avg"] <= 0.5  # Average should be around 0.42

    @pytest.mark.asyncio
    async def test_monitor_performance_decorator(self):
        """Test the @monitor_performance decorator."""
        from app.sentinel.performance import monitor_performance, get_performance_monitor

        @monitor_performance("decorated_operation")
        async def test_function():
            await asyncio.sleep(0.01)
            return "done"

        # Execute function
        result = await test_function()
        assert result == "done"

        # Check that duration was recorded
        stats = get_performance_monitor().get_stats("decorated_operation")
        assert stats is not None
        assert stats["count"] == 1
        assert stats["min"] > 0

    @pytest.mark.asyncio
    async def test_get_all_stats(self):
        """Test retrieving statistics for all operations."""
        from app.sentinel.performance import PerformanceMonitor

        monitor = PerformanceMonitor()

        # Record different operations
        await monitor.record("op1", 0.1)
        await monitor.record("op2", 0.2)
        await monitor.record("op1", 0.15)

        all_stats = monitor.get_all_stats()
        assert "op1" in all_stats
        assert "op2" in all_stats
        assert all_stats["op1"]["count"] == 2
        assert all_stats["op2"]["count"] == 1


class TestBatchProcessor:
    """Test suite for BatchProcessor."""

    @pytest.mark.asyncio
    async def test_process_in_batches(self):
        """Test batch processing with controlled batches."""
        from app.sentinel.performance import BatchProcessor

        # Create test data
        items = list(range(100))
        processed = []

        async def process_batch(batch):
            processed.extend(batch)
            return batch

        # Process in batches of 10
        results = await BatchProcessor.process_in_batches(
            items=items,
            process_func=process_batch,
            batch_size=10,
            concurrency=3
        )

        # Verify all items were processed
        assert len(processed) == 100
        assert sorted(processed) == items

    @pytest.mark.asyncio
    async def test_batch_processor_concurrency(self):
        """Test that batch processor respects concurrency limits."""
        from app.sentinel.performance import BatchProcessor
        import time

        concurrent_count = {"current": 0, "max": 0}

        async def process_batch(batch):
            concurrent_count["current"] += 1
            concurrent_count["max"] = max(
                concurrent_count["max"],
                concurrent_count["current"]
            )
            await asyncio.sleep(0.1)
            concurrent_count["current"] -= 1
            return batch

        items = list(range(50))

        await BatchProcessor.process_in_batches(
            items=items,
            process_func=process_batch,
            batch_size=5,  # 10 batches total
            concurrency=3   # Max 3 concurrent
        )

        # Max concurrent batches should not exceed limit
        assert concurrent_count["max"] <= 3


class TestPoolConfig:
    """Test suite for PoolConfig."""

    def test_get_pool_kwargs(self):
        """Test that pool configuration returns correct kwargs."""
        from app.sentinel.performance import PoolConfig

        kwargs = PoolConfig.get_pool_kwargs()

        assert "min_size" in kwargs
        assert "max_size" in kwargs
        assert "timeout" in kwargs
        assert kwargs["min_size"] == 10
        assert kwargs["max_size"] == 50


# ============================================================================
# Metrics Module Tests
# ============================================================================

class TestPrometheusMetrics:
    """Test suite for PrometheusMetrics."""

    def test_increment_counters(self):
        """Test incrementing various counter metrics."""
        from app.sentinel.metrics import PrometheusMetrics

        metrics = PrometheusMetrics()

        metrics.increment_cdr_ingested(100)
        assert metrics.cdr_records_ingested_total == 100

        metrics.increment_cdr_duplicates(5)
        assert metrics.cdr_records_duplicate_total == 5

        metrics.increment_ingestion_errors(2)
        assert metrics.cdr_ingestion_errors_total == 2

    def test_alert_metrics(self):
        """Test alert-related metrics."""
        from app.sentinel.metrics import PrometheusMetrics

        metrics = PrometheusMetrics()

        metrics.increment_alert_generated("HIGH")
        metrics.increment_alert_generated("CRITICAL")
        metrics.increment_alert_generated("HIGH")

        assert metrics.alerts_generated_total == 3
        assert metrics.alerts_by_severity["HIGH"] == 2
        assert metrics.alerts_by_severity["CRITICAL"] == 1

    def test_websocket_metrics(self):
        """Test WebSocket connection metrics."""
        from app.sentinel.metrics import PrometheusMetrics

        metrics = PrometheusMetrics()

        metrics.increment_websocket_connection()
        metrics.increment_websocket_connection()
        assert metrics.active_websocket_connections == 2

        metrics.decrement_websocket_connection()
        assert metrics.active_websocket_connections == 1

    def test_gauge_metrics(self):
        """Test gauge metrics (unreviewed alerts)."""
        from app.sentinel.metrics import PrometheusMetrics

        metrics = PrometheusMetrics()

        metrics.set_unreviewed_alerts(42)
        assert metrics.unreviewed_alerts == 42

    def test_histogram_metrics(self):
        """Test histogram metrics recording."""
        from app.sentinel.metrics import PrometheusMetrics

        metrics = PrometheusMetrics()

        metrics.record_ingestion_duration(1.5)
        metrics.record_ingestion_duration(2.0)
        metrics.record_detection_duration(30.0)

        assert len(metrics.ingestion_duration_seconds) == 2
        assert len(metrics.detection_duration_seconds) == 1

    def test_api_request_metrics(self):
        """Test API request duration recording."""
        from app.sentinel.metrics import PrometheusMetrics

        metrics = PrometheusMetrics()

        metrics.record_api_request("/ingest", 0.5)
        metrics.record_api_request("/ingest", 0.7)
        metrics.record_api_request("/alerts", 0.2)

        assert len(metrics.api_request_duration_seconds["/ingest"]) == 2
        assert len(metrics.api_request_duration_seconds["/alerts"]) == 1

    def test_percentile_calculation(self):
        """Test percentile calculation for histogram metrics."""
        from app.sentinel.metrics import PrometheusMetrics

        metrics = PrometheusMetrics()

        # Add durations
        for i in range(100):
            metrics.record_ingestion_duration(float(i))

        # Calculate percentiles
        p50 = metrics._calculate_percentile(metrics.ingestion_duration_seconds, 0.5)
        p95 = metrics._calculate_percentile(metrics.ingestion_duration_seconds, 0.95)
        p99 = metrics._calculate_percentile(metrics.ingestion_duration_seconds, 0.99)

        assert 45 <= p50 <= 55  # Median around 50
        assert 90 <= p95 <= 100  # p95 around 95
        assert 95 <= p99 <= 100  # p99 around 99

    def test_get_json_metrics(self):
        """Test JSON metrics export."""
        from app.sentinel.metrics import PrometheusMetrics

        metrics = PrometheusMetrics()

        metrics.increment_cdr_ingested(1000)
        metrics.increment_alert_generated("HIGH")
        metrics.record_ingestion_duration(1.5)

        json_metrics = metrics.get_json_metrics()

        assert "counters" in json_metrics
        assert "gauges" in json_metrics
        assert "histograms" in json_metrics
        assert json_metrics["counters"]["cdr_records_ingested_total"] == 1000

    def test_get_prometheus_metrics(self):
        """Test Prometheus format metrics export."""
        from app.sentinel.metrics import PrometheusMetrics

        metrics = PrometheusMetrics()

        metrics.increment_cdr_ingested(500)
        metrics.increment_alert_generated("CRITICAL")

        prometheus_output = metrics.get_prometheus_metrics()

        # Check format
        assert isinstance(prometheus_output, str)
        assert "sentinel_cdr_records_ingested_total 500" in prometheus_output
        assert "sentinel_alerts_generated_total 1" in prometheus_output
        assert "# HELP" in prometheus_output
        assert "# TYPE" in prometheus_output

    def test_metrics_limits(self):
        """Test that histogram metrics are limited to 1000 entries."""
        from app.sentinel.metrics import PrometheusMetrics

        metrics = PrometheusMetrics()

        # Add 1500 durations
        for i in range(1500):
            metrics.record_ingestion_duration(float(i))

        # Should only keep last 1000
        assert len(metrics.ingestion_duration_seconds) == 1000


# ============================================================================
# Integration Tests
# ============================================================================

class TestPhase4Integration:
    """Integration tests for Phase 4 production features."""

    @pytest.mark.asyncio
    async def test_cached_with_performance_monitoring(self):
        """Test that caching and performance monitoring work together."""
        from app.sentinel.performance import cached, monitor_performance, get_cache, get_performance_monitor

        @cached(ttl_seconds=60)
        @monitor_performance("cached_monitored_op")
        async def combined_function(value: int):
            await asyncio.sleep(0.01)
            return value * 2

        # First call - should be slow
        result1 = await combined_function(5)
        assert result1 == 10

        # Second call - should be fast (cached)
        result2 = await combined_function(5)
        assert result2 == 10

        # Check performance was monitored
        stats = get_performance_monitor().get_stats("cached_monitored_op")
        assert stats is not None
        assert stats["count"] == 2

        # Check cache was used
        cache_stats = get_cache().get_stats()
        assert cache_stats["hits"] >= 1

        # Cleanup
        await get_cache().clear()

    @pytest.mark.asyncio
    async def test_metrics_and_performance_integration(self):
        """Test metrics and performance tracking integration."""
        from app.sentinel.metrics import get_metrics
        from app.sentinel.performance import get_performance_monitor

        metrics = get_metrics()
        perf_monitor = get_performance_monitor()

        # Simulate operations
        metrics.increment_cdr_ingested(100)
        await perf_monitor.record("ingestion", 1.5)

        metrics.increment_alert_generated("HIGH")
        await perf_monitor.record("detection", 30.0)

        # Verify both systems captured data
        assert metrics.cdr_records_ingested_total >= 100
        assert metrics.alerts_generated_total >= 1

        perf_stats = perf_monitor.get_all_stats()
        assert "ingestion" in perf_stats or "detection" in perf_stats


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
