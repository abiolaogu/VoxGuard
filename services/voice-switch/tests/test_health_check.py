"""
Unit tests for VoxGuard Voice Switch Health Check endpoints

Tests coverage:
- ComponentHealth and HealthCheckResponse dataclasses
- HealthChecker initialization and component checks
- Overall status determination logic
- Liveness and readiness probes
- Health endpoint handlers

Author: Claude (VoxGuard Autonomous Factory)
Date: 2026-02-04
"""

import asyncio
import pytest
from unittest.mock import AsyncMock, Mock, MagicMock, patch
import time
from typing import Dict, Any

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from health_check import (
    HealthStatus,
    ComponentHealth,
    HealthCheckResponse,
    HealthChecker,
    create_health_endpoint,
    create_liveness_endpoint,
    create_readiness_endpoint,
)


# ===========================
# Test ComponentHealth
# ===========================

class TestComponentHealth:
    """Test ComponentHealth dataclass"""

    def test_component_health_basic(self):
        """Test basic ComponentHealth creation"""
        component = ComponentHealth(
            name="test_component",
            status=HealthStatus.HEALTHY,
            latency_ms=1.5
        )
        assert component.name == "test_component"
        assert component.status == HealthStatus.HEALTHY
        assert component.latency_ms == 1.5
        assert component.error == ""
        assert component.metadata is None

    def test_component_health_with_error(self):
        """Test ComponentHealth with error"""
        component = ComponentHealth(
            name="database",
            status=HealthStatus.UNHEALTHY,
            latency_ms=500.0,
            error="Connection refused"
        )
        assert component.error == "Connection refused"
        assert component.status == HealthStatus.UNHEALTHY

    def test_component_health_with_metadata(self):
        """Test ComponentHealth with metadata"""
        metadata = {"db_size": 1000, "version": "1.0"}
        component = ComponentHealth(
            name="cache",
            status=HealthStatus.HEALTHY,
            metadata=metadata
        )
        assert component.metadata == metadata

    def test_component_health_to_dict_basic(self):
        """Test ComponentHealth.to_dict() basic conversion"""
        component = ComponentHealth(
            name="test",
            status=HealthStatus.HEALTHY,
            latency_ms=1.234
        )
        result = component.to_dict()

        assert result["name"] == "test"
        assert result["status"] == "healthy"
        assert result["latency_ms"] == 1.23  # rounded to 2 decimals
        assert "error" not in result
        assert "metadata" not in result

    def test_component_health_to_dict_with_error(self):
        """Test ComponentHealth.to_dict() with error"""
        component = ComponentHealth(
            name="test",
            status=HealthStatus.UNHEALTHY,
            error="Test error"
        )
        result = component.to_dict()

        assert result["error"] == "Test error"

    def test_component_health_to_dict_with_metadata(self):
        """Test ComponentHealth.to_dict() with metadata"""
        metadata = {"key": "value"}
        component = ComponentHealth(
            name="test",
            status=HealthStatus.HEALTHY,
            metadata=metadata
        )
        result = component.to_dict()

        assert result["metadata"] == metadata


# ===========================
# Test HealthCheckResponse
# ===========================

class TestHealthCheckResponse:
    """Test HealthCheckResponse dataclass"""

    def test_health_check_response_creation(self):
        """Test HealthCheckResponse creation"""
        components = [
            ComponentHealth("db", HealthStatus.HEALTHY, 1.0),
            ComponentHealth("cache", HealthStatus.HEALTHY, 2.0),
        ]

        response = HealthCheckResponse(
            status=HealthStatus.HEALTHY,
            timestamp=1234567890.123,
            version="1.0.0",
            node_id="node-1",
            uptime_seconds=3600.567,
            components=components,
            circuit_breakers={"cb1": {"state": "closed"}},
            system_metrics={"cpu": 50}
        )

        assert response.status == HealthStatus.HEALTHY
        assert response.version == "1.0.0"
        assert response.node_id == "node-1"
        assert len(response.components) == 2

    def test_health_check_response_to_dict(self):
        """Test HealthCheckResponse.to_dict() conversion"""
        components = [ComponentHealth("db", HealthStatus.HEALTHY, 1.5)]

        response = HealthCheckResponse(
            status=HealthStatus.HEALTHY,
            timestamp=1234567890.0,
            version="1.0.0",
            node_id="node-1",
            uptime_seconds=3600.789,
            components=components,
            circuit_breakers={},
            system_metrics={"cpu": 25}
        )

        result = response.to_dict()

        assert result["status"] == "healthy"
        assert result["timestamp"] == 1234567890.0
        assert result["version"] == "1.0.0"
        assert result["node_id"] == "node-1"
        assert result["uptime_seconds"] == 3600.79  # rounded to 2 decimals
        assert len(result["components"]) == 1
        assert result["components"][0]["name"] == "db"
        assert result["circuit_breakers"] == {}
        assert result["system_metrics"] == {"cpu": 25}


# ===========================
# Test HealthChecker
# ===========================

class TestHealthChecker:
    """Test HealthChecker class"""

    def test_health_checker_initialization(self):
        """Test HealthChecker initialization"""
        checker = HealthChecker(
            version="2.0.0",
            node_id="test-node",
            yugabyte_pool=Mock(),
            redis_client=Mock(),
            acm_engine_url="http://localhost:8080"
        )

        assert checker.version == "2.0.0"
        assert checker.node_id == "test-node"
        assert checker.yugabyte_pool is not None
        assert checker.redis_client is not None
        assert checker.acm_engine_url == "http://localhost:8080"
        assert checker.start_time > 0

    @pytest.mark.asyncio
    async def test_check_yugabyte_healthy(self):
        """Test YugabyteDB health check - healthy"""
        mock_pool = MagicMock()
        mock_conn = AsyncMock()
        mock_conn.fetchval = AsyncMock(return_value=1)
        mock_pool.acquire.return_value.__aenter__.return_value = mock_conn

        checker = HealthChecker(
            version="1.0",
            node_id="node-1",
            yugabyte_pool=mock_pool
        )

        result = await checker.check_yugabyte()

        assert result.name == "yugabyte"
        assert result.status == HealthStatus.HEALTHY
        assert result.latency_ms > 0
        assert result.error == ""

    @pytest.mark.asyncio
    async def test_check_yugabyte_not_configured(self):
        """Test YugabyteDB health check - not configured"""
        checker = HealthChecker(
            version="1.0",
            node_id="node-1",
            yugabyte_pool=None
        )

        result = await checker.check_yugabyte()

        assert result.name == "yugabyte"
        assert result.status == HealthStatus.DEGRADED
        assert result.error == "Database pool not configured"

    @pytest.mark.asyncio
    async def test_check_yugabyte_connection_failed(self):
        """Test YugabyteDB health check - connection failure"""
        mock_pool = MagicMock()
        mock_pool.acquire.side_effect = Exception("Connection refused")

        checker = HealthChecker(
            version="1.0",
            node_id="node-1",
            yugabyte_pool=mock_pool
        )

        result = await checker.check_yugabyte()

        assert result.name == "yugabyte"
        assert result.status == HealthStatus.UNHEALTHY
        assert "Connection refused" in result.error
        assert result.latency_ms > 0

    @pytest.mark.asyncio
    async def test_check_redis_healthy(self):
        """Test Redis/DragonflyDB health check - healthy"""
        mock_redis = AsyncMock()
        mock_redis.ping = AsyncMock(return_value=True)
        mock_redis.dbsize = AsyncMock(return_value=1000)

        checker = HealthChecker(
            version="1.0",
            node_id="node-1",
            redis_client=mock_redis
        )

        result = await checker.check_redis()

        assert result.name == "redis"
        assert result.status == HealthStatus.HEALTHY
        assert result.latency_ms > 0
        assert result.metadata is not None
        assert result.metadata["db_size"] == 1000

    @pytest.mark.asyncio
    async def test_check_redis_not_configured(self):
        """Test Redis health check - not configured"""
        checker = HealthChecker(
            version="1.0",
            node_id="node-1",
            redis_client=None
        )

        result = await checker.check_redis()

        assert result.name == "redis"
        assert result.status == HealthStatus.DEGRADED
        assert result.error == "Redis client not configured"

    @pytest.mark.asyncio
    async def test_check_redis_connection_failed(self):
        """Test Redis health check - connection failure"""
        mock_redis = AsyncMock()
        mock_redis.ping = AsyncMock(side_effect=Exception("Connection timeout"))

        checker = HealthChecker(
            version="1.0",
            node_id="node-1",
            redis_client=mock_redis
        )

        result = await checker.check_redis()

        assert result.name == "redis"
        assert result.status == HealthStatus.UNHEALTHY
        assert "Connection timeout" in result.error

    @pytest.mark.asyncio
    async def test_check_acm_engine_healthy(self):
        """Test ACM engine health check - healthy"""
        mock_response = AsyncMock()
        mock_response.status = 200
        mock_response.json = AsyncMock(return_value={"status": "ok", "version": "1.0"})

        mock_session = AsyncMock()
        mock_session.get.return_value.__aenter__.return_value = mock_response

        with patch('health_check.aiohttp.ClientSession') as mock_client_session:
            mock_client_session.return_value.__aenter__.return_value = mock_session

            checker = HealthChecker(
                version="1.0",
                node_id="node-1",
                acm_engine_url="http://localhost:8080"
            )

            result = await checker.check_acm_engine()

            assert result.name == "acm_engine"
            assert result.status == HealthStatus.HEALTHY
            assert result.latency_ms > 0
            assert result.metadata is not None
            assert result.metadata["status"] == "ok"

    @pytest.mark.asyncio
    async def test_check_acm_engine_not_configured(self):
        """Test ACM engine health check - not configured"""
        checker = HealthChecker(
            version="1.0",
            node_id="node-1",
            acm_engine_url=None
        )

        result = await checker.check_acm_engine()

        assert result.name == "acm_engine"
        assert result.status == HealthStatus.DEGRADED
        assert result.error == "ACM engine URL not configured"

    @pytest.mark.asyncio
    async def test_check_acm_engine_http_error(self):
        """Test ACM engine health check - HTTP error"""
        mock_response = AsyncMock()
        mock_response.status = 503

        mock_session = AsyncMock()
        mock_session.get.return_value.__aenter__.return_value = mock_response

        with patch('health_check.aiohttp.ClientSession') as mock_client_session:
            mock_client_session.return_value.__aenter__.return_value = mock_session

            checker = HealthChecker(
                version="1.0",
                node_id="node-1",
                acm_engine_url="http://localhost:8080"
            )

            result = await checker.check_acm_engine()

            assert result.name == "acm_engine"
            assert result.status == HealthStatus.UNHEALTHY
            assert "HTTP 503" in result.error

    @pytest.mark.asyncio
    async def test_check_acm_engine_timeout(self):
        """Test ACM engine health check - timeout"""
        mock_session = AsyncMock()
        mock_session.get.side_effect = asyncio.TimeoutError()

        with patch('health_check.aiohttp.ClientSession') as mock_client_session:
            mock_client_session.return_value.__aenter__.return_value = mock_session

            checker = HealthChecker(
                version="1.0",
                node_id="node-1",
                acm_engine_url="http://localhost:8080"
            )

            result = await checker.check_acm_engine()

            assert result.name == "acm_engine"
            assert result.status == HealthStatus.UNHEALTHY
            assert "Timeout" in result.error

    @pytest.mark.asyncio
    async def test_check_acm_engine_connection_error(self):
        """Test ACM engine health check - connection error"""
        mock_session = AsyncMock()
        mock_session.get.side_effect = Exception("Connection refused")

        with patch('health_check.aiohttp.ClientSession') as mock_client_session:
            mock_client_session.return_value.__aenter__.return_value = mock_session

            checker = HealthChecker(
                version="1.0",
                node_id="node-1",
                acm_engine_url="http://localhost:8080"
            )

            result = await checker.check_acm_engine()

            assert result.name == "acm_engine"
            assert result.status == HealthStatus.UNHEALTHY
            assert "Connection refused" in result.error

    def test_get_system_metrics_success(self):
        """Test get_system_metrics - success"""
        mock_process = Mock()
        mock_process.cpu_percent.return_value = 25.5
        mock_memory_info = Mock(rss=1024 * 1024 * 100, vms=1024 * 1024 * 200)
        mock_process.memory_info.return_value = mock_memory_info
        mock_process.num_threads.return_value = 4
        mock_process.open_files.return_value = [1, 2, 3]
        mock_process.connections.return_value = [1, 2]

        with patch('health_check.psutil.Process', return_value=mock_process):
            checker = HealthChecker(version="1.0", node_id="node-1")
            result = checker.get_system_metrics()

            assert result["cpu_percent"] == 25.5
            assert result["memory_rss_mb"] == 100.0
            assert result["memory_vms_mb"] == 200.0
            assert result["threads"] == 4
            assert result["open_files"] == 3
            assert result["connections"] == 2

    def test_get_system_metrics_psutil_not_installed(self):
        """Test get_system_metrics - psutil not installed"""
        with patch('health_check.psutil', side_effect=ImportError()):
            checker = HealthChecker(version="1.0", node_id="node-1")
            result = checker.get_system_metrics()

            assert "error" in result
            assert result["error"] == "psutil not installed"

    def test_get_system_metrics_error(self):
        """Test get_system_metrics - exception"""
        with patch('health_check.psutil.Process', side_effect=Exception("Test error")):
            checker = HealthChecker(version="1.0", node_id="node-1")
            result = checker.get_system_metrics()

            assert "error" in result
            assert result["error"] == "Test error"

    def test_determine_overall_status_all_healthy(self):
        """Test determine_overall_status - all components healthy"""
        checker = HealthChecker(version="1.0", node_id="node-1")
        components = [
            ComponentHealth("yugabyte", HealthStatus.HEALTHY),
            ComponentHealth("redis", HealthStatus.HEALTHY),
            ComponentHealth("acm_engine", HealthStatus.HEALTHY),
        ]

        result = checker.determine_overall_status(components)
        assert result == HealthStatus.HEALTHY

    def test_determine_overall_status_critical_unhealthy(self):
        """Test determine_overall_status - critical component unhealthy"""
        checker = HealthChecker(version="1.0", node_id="node-1")
        components = [
            ComponentHealth("yugabyte", HealthStatus.UNHEALTHY),
            ComponentHealth("redis", HealthStatus.HEALTHY),
            ComponentHealth("acm_engine", HealthStatus.HEALTHY),
        ]

        result = checker.determine_overall_status(components)
        assert result == HealthStatus.UNHEALTHY

    def test_determine_overall_status_redis_unhealthy(self):
        """Test determine_overall_status - redis unhealthy"""
        checker = HealthChecker(version="1.0", node_id="node-1")
        components = [
            ComponentHealth("yugabyte", HealthStatus.HEALTHY),
            ComponentHealth("redis", HealthStatus.UNHEALTHY),
            ComponentHealth("acm_engine", HealthStatus.HEALTHY),
        ]

        result = checker.determine_overall_status(components)
        assert result == HealthStatus.UNHEALTHY

    def test_determine_overall_status_multiple_degraded(self):
        """Test determine_overall_status - multiple components degraded"""
        checker = HealthChecker(version="1.0", node_id="node-1")
        components = [
            ComponentHealth("yugabyte", HealthStatus.DEGRADED),
            ComponentHealth("redis", HealthStatus.DEGRADED),
            ComponentHealth("acm_engine", HealthStatus.HEALTHY),
        ]

        result = checker.determine_overall_status(components)
        assert result == HealthStatus.UNHEALTHY

    def test_determine_overall_status_one_degraded(self):
        """Test determine_overall_status - one component degraded"""
        checker = HealthChecker(version="1.0", node_id="node-1")
        components = [
            ComponentHealth("yugabyte", HealthStatus.HEALTHY),
            ComponentHealth("redis", HealthStatus.DEGRADED),
            ComponentHealth("acm_engine", HealthStatus.HEALTHY),
        ]

        result = checker.determine_overall_status(components)
        assert result == HealthStatus.DEGRADED

    def test_determine_overall_status_non_critical_unhealthy(self):
        """Test determine_overall_status - non-critical component unhealthy"""
        checker = HealthChecker(version="1.0", node_id="node-1")
        components = [
            ComponentHealth("yugabyte", HealthStatus.HEALTHY),
            ComponentHealth("redis", HealthStatus.HEALTHY),
            ComponentHealth("acm_engine", HealthStatus.UNHEALTHY),
        ]

        result = checker.determine_overall_status(components)
        assert result == HealthStatus.DEGRADED

    @pytest.mark.asyncio
    async def test_full_health_check_all_healthy(self):
        """Test full_health_check - all components healthy"""
        # Mock all component checks
        mock_yugabyte_pool = MagicMock()
        mock_conn = AsyncMock()
        mock_conn.fetchval = AsyncMock(return_value=1)
        mock_yugabyte_pool.acquire.return_value.__aenter__.return_value = mock_conn

        mock_redis = AsyncMock()
        mock_redis.ping = AsyncMock(return_value=True)
        mock_redis.dbsize = AsyncMock(return_value=100)

        # Mock circuit breaker metrics
        with patch('health_check.get_all_metrics', return_value={"cb1": {"state": "closed"}}):
            with patch('health_check.aiohttp.ClientSession') as mock_session_cls:
                mock_response = AsyncMock()
                mock_response.status = 200
                mock_response.json = AsyncMock(return_value={"status": "ok"})

                mock_session = AsyncMock()
                mock_session.get.return_value.__aenter__.return_value = mock_response
                mock_session_cls.return_value.__aenter__.return_value = mock_session

                checker = HealthChecker(
                    version="1.0.0",
                    node_id="test-node",
                    yugabyte_pool=mock_yugabyte_pool,
                    redis_client=mock_redis,
                    acm_engine_url="http://localhost:8080"
                )

                result = await checker.full_health_check()

                assert result.status == HealthStatus.HEALTHY
                assert result.version == "1.0.0"
                assert result.node_id == "test-node"
                assert len(result.components) == 3
                assert result.circuit_breakers == {"cb1": {"state": "closed"}}

    @pytest.mark.asyncio
    async def test_full_health_check_circuit_breaker_open(self):
        """Test full_health_check - circuit breaker open causes degraded"""
        mock_yugabyte_pool = MagicMock()
        mock_conn = AsyncMock()
        mock_conn.fetchval = AsyncMock(return_value=1)
        mock_yugabyte_pool.acquire.return_value.__aenter__.return_value = mock_conn

        mock_redis = AsyncMock()
        mock_redis.ping = AsyncMock(return_value=True)
        mock_redis.dbsize = AsyncMock(return_value=100)

        # Circuit breaker is OPEN
        with patch('health_check.get_all_metrics', return_value={"cb1": {"state": "open"}}):
            with patch('health_check.aiohttp.ClientSession') as mock_session_cls:
                mock_response = AsyncMock()
                mock_response.status = 200
                mock_response.json = AsyncMock(return_value={"status": "ok"})

                mock_session = AsyncMock()
                mock_session.get.return_value.__aenter__.return_value = mock_response
                mock_session_cls.return_value.__aenter__.return_value = mock_session

                checker = HealthChecker(
                    version="1.0.0",
                    node_id="test-node",
                    yugabyte_pool=mock_yugabyte_pool,
                    redis_client=mock_redis,
                    acm_engine_url="http://localhost:8080"
                )

                result = await checker.full_health_check()

                # Should be DEGRADED due to open circuit breaker
                assert result.status == HealthStatus.DEGRADED

    @pytest.mark.asyncio
    async def test_liveness_probe(self):
        """Test liveness probe - simple alive check"""
        checker = HealthChecker(version="1.0", node_id="node-1")
        result = await checker.liveness_probe()

        assert result["status"] == "alive"
        assert "timestamp" in result
        assert result["timestamp"] > 0

    @pytest.mark.asyncio
    async def test_readiness_probe_healthy(self):
        """Test readiness probe - healthy status returns 200"""
        mock_yugabyte_pool = MagicMock()
        mock_conn = AsyncMock()
        mock_conn.fetchval = AsyncMock(return_value=1)
        mock_yugabyte_pool.acquire.return_value.__aenter__.return_value = mock_conn

        mock_redis = AsyncMock()
        mock_redis.ping = AsyncMock(return_value=True)
        mock_redis.dbsize = AsyncMock(return_value=100)

        with patch('health_check.get_all_metrics', return_value={}):
            with patch('health_check.aiohttp.ClientSession') as mock_session_cls:
                mock_response = AsyncMock()
                mock_response.status = 200
                mock_response.json = AsyncMock(return_value={"status": "ok"})

                mock_session = AsyncMock()
                mock_session.get.return_value.__aenter__.return_value = mock_response
                mock_session_cls.return_value.__aenter__.return_value = mock_session

                checker = HealthChecker(
                    version="1.0",
                    node_id="node-1",
                    yugabyte_pool=mock_yugabyte_pool,
                    redis_client=mock_redis,
                    acm_engine_url="http://localhost:8080"
                )

                response_dict, status_code = await checker.readiness_probe()

                assert status_code == 200
                assert response_dict["status"] == "healthy"

    @pytest.mark.asyncio
    async def test_readiness_probe_degraded(self):
        """Test readiness probe - degraded status returns 200 (still ready)"""
        mock_yugabyte_pool = MagicMock()
        mock_conn = AsyncMock()
        mock_conn.fetchval = AsyncMock(return_value=1)
        mock_yugabyte_pool.acquire.return_value.__aenter__.return_value = mock_conn

        mock_redis = AsyncMock()
        mock_redis.ping = AsyncMock(return_value=True)
        mock_redis.dbsize = AsyncMock(return_value=100)

        # ACM engine not configured (degraded)
        with patch('health_check.get_all_metrics', return_value={}):
            checker = HealthChecker(
                version="1.0",
                node_id="node-1",
                yugabyte_pool=mock_yugabyte_pool,
                redis_client=mock_redis,
                acm_engine_url=None  # Not configured
            )

            response_dict, status_code = await checker.readiness_probe()

            assert status_code == 200  # Still ready despite degraded
            assert response_dict["status"] == "degraded"

    @pytest.mark.asyncio
    async def test_readiness_probe_unhealthy(self):
        """Test readiness probe - unhealthy status returns 503"""
        mock_yugabyte_pool = MagicMock()
        mock_yugabyte_pool.acquire.side_effect = Exception("Connection refused")

        with patch('health_check.get_all_metrics', return_value={}):
            checker = HealthChecker(
                version="1.0",
                node_id="node-1",
                yugabyte_pool=mock_yugabyte_pool,
                redis_client=None,
                acm_engine_url=None
            )

            response_dict, status_code = await checker.readiness_probe()

            assert status_code == 503  # Not ready
            assert response_dict["status"] == "unhealthy"


# ===========================
# Test Endpoint Handlers
# ===========================

class TestEndpointHandlers:
    """Test convenience endpoint handlers"""

    @pytest.mark.asyncio
    async def test_create_health_endpoint_healthy(self):
        """Test create_health_endpoint - healthy returns 200"""
        mock_yugabyte_pool = MagicMock()
        mock_conn = AsyncMock()
        mock_conn.fetchval = AsyncMock(return_value=1)
        mock_yugabyte_pool.acquire.return_value.__aenter__.return_value = mock_conn

        mock_redis = AsyncMock()
        mock_redis.ping = AsyncMock(return_value=True)
        mock_redis.dbsize = AsyncMock(return_value=100)

        with patch('health_check.get_all_metrics', return_value={}):
            with patch('health_check.aiohttp.ClientSession') as mock_session_cls:
                mock_response = AsyncMock()
                mock_response.status = 200
                mock_response.json = AsyncMock(return_value={"status": "ok"})

                mock_session = AsyncMock()
                mock_session.get.return_value.__aenter__.return_value = mock_response
                mock_session_cls.return_value.__aenter__.return_value = mock_session

                checker = HealthChecker(
                    version="1.0",
                    node_id="node-1",
                    yugabyte_pool=mock_yugabyte_pool,
                    redis_client=mock_redis,
                    acm_engine_url="http://localhost:8080"
                )

                response_dict, status_code = await create_health_endpoint(checker)

                assert status_code == 200
                assert response_dict["status"] == "healthy"

    @pytest.mark.asyncio
    async def test_create_health_endpoint_degraded(self):
        """Test create_health_endpoint - degraded returns 200"""
        mock_redis = AsyncMock()
        mock_redis.ping = AsyncMock(return_value=True)
        mock_redis.dbsize = AsyncMock(return_value=100)

        with patch('health_check.get_all_metrics', return_value={}):
            checker = HealthChecker(
                version="1.0",
                node_id="node-1",
                yugabyte_pool=None,  # Not configured - degraded
                redis_client=mock_redis,
                acm_engine_url=None
            )

            response_dict, status_code = await create_health_endpoint(checker)

            assert status_code == 200  # Still accepting traffic
            assert response_dict["status"] == "degraded"

    @pytest.mark.asyncio
    async def test_create_health_endpoint_unhealthy(self):
        """Test create_health_endpoint - unhealthy returns 503"""
        mock_yugabyte_pool = MagicMock()
        mock_yugabyte_pool.acquire.side_effect = Exception("Connection error")

        with patch('health_check.get_all_metrics', return_value={}):
            checker = HealthChecker(
                version="1.0",
                node_id="node-1",
                yugabyte_pool=mock_yugabyte_pool,
                redis_client=None,
                acm_engine_url=None
            )

            response_dict, status_code = await create_health_endpoint(checker)

            assert status_code == 503
            assert response_dict["status"] == "unhealthy"

    @pytest.mark.asyncio
    async def test_create_liveness_endpoint(self):
        """Test create_liveness_endpoint"""
        checker = HealthChecker(version="1.0", node_id="node-1")

        response_dict, status_code = await create_liveness_endpoint(checker)

        assert status_code == 200
        assert response_dict["status"] == "alive"
        assert "timestamp" in response_dict

    @pytest.mark.asyncio
    async def test_create_readiness_endpoint(self):
        """Test create_readiness_endpoint"""
        mock_yugabyte_pool = MagicMock()
        mock_conn = AsyncMock()
        mock_conn.fetchval = AsyncMock(return_value=1)
        mock_yugabyte_pool.acquire.return_value.__aenter__.return_value = mock_conn

        mock_redis = AsyncMock()
        mock_redis.ping = AsyncMock(return_value=True)
        mock_redis.dbsize = AsyncMock(return_value=100)

        with patch('health_check.get_all_metrics', return_value={}):
            with patch('health_check.aiohttp.ClientSession') as mock_session_cls:
                mock_response = AsyncMock()
                mock_response.status = 200
                mock_response.json = AsyncMock(return_value={"status": "ok"})

                mock_session = AsyncMock()
                mock_session.get.return_value.__aenter__.return_value = mock_response
                mock_session_cls.return_value.__aenter__.return_value = mock_session

                checker = HealthChecker(
                    version="1.0",
                    node_id="node-1",
                    yugabyte_pool=mock_yugabyte_pool,
                    redis_client=mock_redis,
                    acm_engine_url="http://localhost:8080"
                )

                response_dict, status_code = await create_readiness_endpoint(checker)

                assert status_code == 200
                assert response_dict["status"] == "healthy"


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
