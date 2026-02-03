"""
Enhanced Health Check Endpoints for VoxGuard Voice Switch
Provides comprehensive health and readiness checks with circuit breaker status

Author: Claude (VoxGuard Autonomous Factory)
Date: 2026-02-03
"""

import asyncio
import time
from typing import Dict, Any, List
from dataclasses import dataclass, asdict
from enum import Enum
import logging

from circuit_breaker import get_all_metrics, get_circuit_breaker

logger = logging.getLogger(__name__)


class HealthStatus(Enum):
    """Health status levels"""
    HEALTHY = "healthy"
    DEGRADED = "degraded"
    UNHEALTHY = "unhealthy"


@dataclass
class ComponentHealth:
    """Health information for a single component"""
    name: str
    status: HealthStatus
    latency_ms: float = 0.0
    error: str = ""
    metadata: Dict[str, Any] = None

    def to_dict(self) -> Dict[str, Any]:
        result = {
            "name": self.name,
            "status": self.status.value,
            "latency_ms": round(self.latency_ms, 2)
        }
        if self.error:
            result["error"] = self.error
        if self.metadata:
            result["metadata"] = self.metadata
        return result


@dataclass
class HealthCheckResponse:
    """Complete health check response"""
    status: HealthStatus
    timestamp: float
    version: str
    node_id: str
    uptime_seconds: float
    components: List[ComponentHealth]
    circuit_breakers: Dict[str, Any]
    system_metrics: Dict[str, Any]

    def to_dict(self) -> Dict[str, Any]:
        return {
            "status": self.status.value,
            "timestamp": self.timestamp,
            "version": self.version,
            "node_id": self.node_id,
            "uptime_seconds": round(self.uptime_seconds, 2),
            "components": [c.to_dict() for c in self.components],
            "circuit_breakers": self.circuit_breakers,
            "system_metrics": self.system_metrics
        }


class HealthChecker:
    """
    Comprehensive health checker for Voice Switch services

    Checks:
    - Database connectivity (YugabyteDB)
    - Cache connectivity (DragonflyDB)
    - ACM detection engine availability
    - Circuit breaker states
    - System resources
    """

    def __init__(
        self,
        version: str,
        node_id: str,
        yugabyte_pool=None,
        redis_client=None,
        acm_engine_url: str = None
    ):
        self.version = version
        self.node_id = node_id
        self.yugabyte_pool = yugabyte_pool
        self.redis_client = redis_client
        self.acm_engine_url = acm_engine_url
        self.start_time = time.time()

    async def check_yugabyte(self) -> ComponentHealth:
        """Check YugabyteDB connectivity"""
        start = time.time()
        try:
            if self.yugabyte_pool is None:
                return ComponentHealth(
                    name="yugabyte",
                    status=HealthStatus.DEGRADED,
                    error="Database pool not configured"
                )

            # Simple connectivity check
            async with self.yugabyte_pool.acquire() as conn:
                await conn.fetchval("SELECT 1")

            latency = (time.time() - start) * 1000
            return ComponentHealth(
                name="yugabyte",
                status=HealthStatus.HEALTHY,
                latency_ms=latency
            )

        except Exception as e:
            latency = (time.time() - start) * 1000
            logger.error(f"YugabyteDB health check failed: {e}")
            return ComponentHealth(
                name="yugabyte",
                status=HealthStatus.UNHEALTHY,
                latency_ms=latency,
                error=str(e)
            )

    async def check_redis(self) -> ComponentHealth:
        """Check DragonflyDB/Redis connectivity"""
        start = time.time()
        try:
            if self.redis_client is None:
                return ComponentHealth(
                    name="redis",
                    status=HealthStatus.DEGRADED,
                    error="Redis client not configured"
                )

            # Ping check
            await self.redis_client.ping()

            latency = (time.time() - start) * 1000
            return ComponentHealth(
                name="redis",
                status=HealthStatus.HEALTHY,
                latency_ms=latency,
                metadata={
                    "db_size": await self.redis_client.dbsize()
                }
            )

        except Exception as e:
            latency = (time.time() - start) * 1000
            logger.error(f"Redis health check failed: {e}")
            return ComponentHealth(
                name="redis",
                status=HealthStatus.UNHEALTHY,
                latency_ms=latency,
                error=str(e)
            )

    async def check_acm_engine(self) -> ComponentHealth:
        """Check ACM detection engine availability"""
        start = time.time()
        try:
            if not self.acm_engine_url:
                return ComponentHealth(
                    name="acm_engine",
                    status=HealthStatus.DEGRADED,
                    error="ACM engine URL not configured"
                )

            import aiohttp
            async with aiohttp.ClientSession() as session:
                async with session.get(
                    f"{self.acm_engine_url}/health",
                    timeout=aiohttp.ClientTimeout(total=5)
                ) as resp:
                    latency = (time.time() - start) * 1000

                    if resp.status == 200:
                        data = await resp.json()
                        return ComponentHealth(
                            name="acm_engine",
                            status=HealthStatus.HEALTHY,
                            latency_ms=latency,
                            metadata=data
                        )
                    else:
                        return ComponentHealth(
                            name="acm_engine",
                            status=HealthStatus.UNHEALTHY,
                            latency_ms=latency,
                            error=f"HTTP {resp.status}"
                        )

        except asyncio.TimeoutError:
            latency = (time.time() - start) * 1000
            return ComponentHealth(
                name="acm_engine",
                status=HealthStatus.UNHEALTHY,
                latency_ms=latency,
                error="Timeout (>5s)"
            )
        except Exception as e:
            latency = (time.time() - start) * 1000
            logger.error(f"ACM engine health check failed: {e}")
            return ComponentHealth(
                name="acm_engine",
                status=HealthStatus.UNHEALTHY,
                latency_ms=latency,
                error=str(e)
            )

    def get_system_metrics(self) -> Dict[str, Any]:
        """Get system-level metrics"""
        try:
            import psutil

            process = psutil.Process()
            cpu_percent = process.cpu_percent(interval=0.1)
            memory_info = process.memory_info()

            return {
                "cpu_percent": round(cpu_percent, 2),
                "memory_rss_mb": round(memory_info.rss / 1024 / 1024, 2),
                "memory_vms_mb": round(memory_info.vms / 1024 / 1024, 2),
                "threads": process.num_threads(),
                "open_files": len(process.open_files()),
                "connections": len(process.connections())
            }
        except ImportError:
            return {"error": "psutil not installed"}
        except Exception as e:
            logger.error(f"Failed to get system metrics: {e}")
            return {"error": str(e)}

    def determine_overall_status(
        self,
        components: List[ComponentHealth]
    ) -> HealthStatus:
        """Determine overall health status based on components"""
        unhealthy_count = sum(
            1 for c in components if c.status == HealthStatus.UNHEALTHY
        )
        degraded_count = sum(
            1 for c in components if c.status == HealthStatus.DEGRADED
        )

        # If any critical component is unhealthy, overall is unhealthy
        critical_components = ["yugabyte", "redis"]
        for component in components:
            if (component.name in critical_components and
                component.status == HealthStatus.UNHEALTHY):
                return HealthStatus.UNHEALTHY

        # If multiple components are degraded/unhealthy, overall is unhealthy
        if unhealthy_count + degraded_count >= 2:
            return HealthStatus.UNHEALTHY

        # If any component is degraded, overall is degraded
        if degraded_count > 0 or unhealthy_count > 0:
            return HealthStatus.DEGRADED

        return HealthStatus.HEALTHY

    async def full_health_check(self) -> HealthCheckResponse:
        """Perform complete health check of all components"""
        # Check all components in parallel
        components = await asyncio.gather(
            self.check_yugabyte(),
            self.check_redis(),
            self.check_acm_engine(),
            return_exceptions=False
        )

        # Get circuit breaker metrics
        circuit_breaker_metrics = get_all_metrics()

        # Get system metrics
        system_metrics = self.get_system_metrics()

        # Determine overall status
        overall_status = self.determine_overall_status(components)

        # Check if any circuit breaker is open
        for cb_name, cb_metrics in circuit_breaker_metrics.items():
            if cb_metrics["state"] == "open":
                # If circuit breaker is open, we're degraded at minimum
                if overall_status == HealthStatus.HEALTHY:
                    overall_status = HealthStatus.DEGRADED

        return HealthCheckResponse(
            status=overall_status,
            timestamp=time.time(),
            version=self.version,
            node_id=self.node_id,
            uptime_seconds=time.time() - self.start_time,
            components=list(components),
            circuit_breakers=circuit_breaker_metrics,
            system_metrics=system_metrics
        )

    async def liveness_probe(self) -> Dict[str, Any]:
        """
        Kubernetes liveness probe - simple check that process is alive
        Should only fail if the process is deadlocked or crashed
        """
        return {
            "status": "alive",
            "timestamp": time.time()
        }

    async def readiness_probe(self) -> tuple[Dict[str, Any], int]:
        """
        Kubernetes readiness probe - checks if service can handle traffic
        Returns (response_dict, http_status_code)
        """
        health_check = await self.full_health_check()

        # Ready if healthy or degraded (can still serve traffic)
        # Not ready if unhealthy
        if health_check.status == HealthStatus.UNHEALTHY:
            return health_check.to_dict(), 503
        else:
            return health_check.to_dict(), 200


# Convenience functions for FastAPI/Flask integration
async def create_health_endpoint(health_checker: HealthChecker):
    """Create health endpoint handler"""
    health_check = await health_checker.full_health_check()
    response = health_check.to_dict()

    # Return appropriate HTTP status code
    if health_check.status == HealthStatus.HEALTHY:
        return response, 200
    elif health_check.status == HealthStatus.DEGRADED:
        return response, 200  # Still accepting traffic
    else:
        return response, 503


async def create_liveness_endpoint(health_checker: HealthChecker):
    """Create liveness endpoint handler (Kubernetes)"""
    return await health_checker.liveness_probe(), 200


async def create_readiness_endpoint(health_checker: HealthChecker):
    """Create readiness endpoint handler (Kubernetes)"""
    return await health_checker.readiness_probe()
