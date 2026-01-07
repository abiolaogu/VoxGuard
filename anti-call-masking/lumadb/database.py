"""
Anti-Call Masking Detection System - LumaDB Edition
LumaDB database client - unified interface replacing kdb+, Kafka, Redis, PostgreSQL
"""

import asyncio
import json
from datetime import datetime, timedelta
from typing import Optional, List, Dict, Any, AsyncGenerator
from contextlib import asynccontextmanager
import structlog
import asyncpg
from kafka import KafkaProducer, KafkaConsumer
import httpx

from config import settings
from models import (
    CallRecord, FraudAlert, BlockedPattern, ThreatLevel,
    AlertSeverity, AlertStatus, LUMADB_SCHEMA, KAFKA_TOPICS
)

logger = structlog.get_logger()


class LumaDBClient:
    """
    Unified LumaDB client that provides:
    - Time-series queries (replacing kdb+)
    - Streaming via Kafka protocol (replacing Kafka/Redpanda)
    - SQL queries via PostgreSQL protocol
    - REST API for management
    """

    def __init__(self):
        self.pg_pool: Optional[asyncpg.Pool] = None
        self.kafka_producer: Optional[KafkaProducer] = None
        self.http_client: Optional[httpx.AsyncClient] = None
        self._initialized = False

    async def initialize(self):
        """Initialize all LumaDB connections"""
        if self._initialized:
            return

        logger.info("Initializing LumaDB connections...")

        # Initialize PostgreSQL connection pool (LumaDB supports PostgreSQL wire protocol)
        try:
            self.pg_pool = await asyncpg.create_pool(
                dsn=settings.lumadb.pg_dsn,
                min_size=5,
                max_size=20,
                command_timeout=30.0
            )
            logger.info("LumaDB PostgreSQL pool initialized", dsn=settings.lumadb.pg_dsn)
        except Exception as e:
            logger.error("Failed to initialize PostgreSQL pool", error=str(e))
            raise

        # Initialize Kafka producer (LumaDB is 100% Kafka-compatible)
        try:
            self.kafka_producer = KafkaProducer(
                bootstrap_servers=settings.lumadb.kafka_bootstrap_servers,
                value_serializer=lambda v: json.dumps(v, default=str).encode('utf-8'),
                key_serializer=lambda k: k.encode('utf-8') if k else None,
                acks='all',
                retries=3,
                batch_size=16384,
                linger_ms=5
            )
            logger.info("LumaDB Kafka producer initialized",
                       bootstrap_servers=settings.lumadb.kafka_bootstrap_servers)
        except Exception as e:
            logger.warning("Failed to initialize Kafka producer", error=str(e))
            # Continue without Kafka - it's optional for basic operation

        # Initialize HTTP client for REST API
        self.http_client = httpx.AsyncClient(
            base_url=settings.lumadb.rest_url,
            timeout=30.0
        )

        # Initialize schema
        await self._init_schema()

        self._initialized = True
        logger.info("LumaDB client fully initialized")

    async def _init_schema(self):
        """Initialize database schema"""
        async with self.pg_pool.acquire() as conn:
            await conn.execute(LUMADB_SCHEMA)
            logger.info("Database schema initialized")

    async def close(self):
        """Close all connections"""
        if self.pg_pool:
            await self.pg_pool.close()
        if self.kafka_producer:
            self.kafka_producer.close()
        if self.http_client:
            await self.http_client.aclose()
        self._initialized = False
        logger.info("LumaDB connections closed")

    # =========================================================================
    # TIME-SERIES OPERATIONS (replacing kdb+)
    # =========================================================================

    async def insert_call(self, call: CallRecord) -> bool:
        """Insert a call record into the time-series store"""
        async with self.pg_pool.acquire() as conn:
            await conn.execute("""
                INSERT INTO calls (
                    call_id, a_number, b_number, timestamp, status,
                    flagged, alert_id, switch_id, raw_call_id, source_ip
                ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
                ON CONFLICT (call_id) DO NOTHING
            """,
                call.call_id, call.a_number, call.b_number, call.timestamp,
                call.status.value, call.flagged, call.alert_id,
                call.switch_id, call.raw_call_id, call.source_ip
            )

        # Also publish to Kafka topic for streaming consumers
        if self.kafka_producer:
            self.kafka_producer.send(
                settings.streaming.calls_topic,
                key=call.b_number,
                value=call.model_dump()
            )

        return True

    async def get_calls_in_window(
        self,
        b_number: str,
        window_start: datetime,
        window_end: datetime
    ) -> List[CallRecord]:
        """
        Get calls to a B-number within a time window.
        This is the core sliding window query - optimized in LumaDB.
        """
        async with self.pg_pool.acquire() as conn:
            rows = await conn.fetch("""
                SELECT call_id, a_number, b_number, timestamp, status,
                       flagged, alert_id, switch_id, raw_call_id, source_ip
                FROM calls
                WHERE b_number = $1
                  AND timestamp BETWEEN $2 AND $3
                  AND flagged = FALSE
                ORDER BY timestamp DESC
            """, b_number, window_start, window_end)

            return [
                CallRecord(
                    call_id=row['call_id'],
                    a_number=row['a_number'],
                    b_number=row['b_number'],
                    timestamp=row['timestamp'],
                    status=row['status'],
                    flagged=row['flagged'],
                    alert_id=row['alert_id'],
                    switch_id=row['switch_id'],
                    raw_call_id=row['raw_call_id'],
                    source_ip=row['source_ip']
                )
                for row in rows
            ]

    async def count_distinct_a_numbers(
        self,
        b_number: str,
        window_start: datetime,
        window_end: datetime
    ) -> int:
        """Count distinct A-numbers calling a B-number in the window"""
        async with self.pg_pool.acquire() as conn:
            count = await conn.fetchval("""
                SELECT COUNT(DISTINCT a_number)
                FROM calls
                WHERE b_number = $1
                  AND timestamp BETWEEN $2 AND $3
                  AND flagged = FALSE
            """, b_number, window_start, window_end)
            return count or 0

    async def flag_calls(self, call_ids: List[str], alert_id: str) -> int:
        """Flag calls as part of a fraud alert"""
        async with self.pg_pool.acquire() as conn:
            result = await conn.execute("""
                UPDATE calls
                SET flagged = TRUE, alert_id = $1
                WHERE call_id = ANY($2)
            """, alert_id, call_ids)
            return int(result.split()[-1])

    # =========================================================================
    # ALERT OPERATIONS
    # =========================================================================

    async def create_alert(self, alert: FraudAlert) -> str:
        """Create a new fraud alert"""
        async with self.pg_pool.acquire() as conn:
            await conn.execute("""
                INSERT INTO fraud_alerts (
                    alert_id, b_number, a_numbers, call_ids, source_ips,
                    call_count, window_start, window_end, severity, status,
                    retry_count, created_at, updated_at, notes
                ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
            """,
                alert.alert_id, alert.b_number, alert.a_numbers, alert.call_ids,
                alert.source_ips, alert.call_count, alert.window_start, alert.window_end,
                alert.severity.value, alert.status.value, alert.retry_count,
                alert.created_at, alert.updated_at, alert.notes
            )

        # Publish to alerts topic
        if self.kafka_producer:
            self.kafka_producer.send(
                settings.streaming.alerts_topic,
                key=alert.b_number,
                value=alert.model_dump()
            )

        return alert.alert_id

    async def get_alert(self, alert_id: str) -> Optional[FraudAlert]:
        """Get alert by ID"""
        async with self.pg_pool.acquire() as conn:
            row = await conn.fetchrow("""
                SELECT * FROM fraud_alerts WHERE alert_id = $1
            """, alert_id)
            if row:
                return FraudAlert(**dict(row))
            return None

    async def get_recent_alerts(self, minutes: int = 60) -> List[FraudAlert]:
        """Get alerts from the last N minutes"""
        cutoff = datetime.utcnow() - timedelta(minutes=minutes)
        async with self.pg_pool.acquire() as conn:
            rows = await conn.fetch("""
                SELECT * FROM fraud_alerts
                WHERE created_at > $1
                ORDER BY created_at DESC
            """, cutoff)
            return [FraudAlert(**dict(row)) for row in rows]

    async def update_alert_status(
        self,
        alert_id: str,
        status: AlertStatus,
        notes: Optional[str] = None
    ) -> bool:
        """Update alert status"""
        async with self.pg_pool.acquire() as conn:
            result = await conn.execute("""
                UPDATE fraud_alerts
                SET status = $1, updated_at = $2, notes = COALESCE($3, notes),
                    resolved_at = CASE WHEN $1 IN ('RESOLVED', 'FALSE_POSITIVE') THEN $2 ELSE resolved_at END
                WHERE alert_id = $4
            """, status.value, datetime.utcnow(), notes, alert_id)
            return "UPDATE 1" in result

    # =========================================================================
    # COOLDOWN OPERATIONS
    # =========================================================================

    async def is_in_cooldown(self, b_number: str) -> bool:
        """Check if B-number is in cooldown period"""
        cooldown_cutoff = datetime.utcnow() - timedelta(seconds=settings.detection.cooldown_seconds)
        async with self.pg_pool.acquire() as conn:
            row = await conn.fetchrow("""
                SELECT last_alert_at FROM cooldowns
                WHERE b_number = $1 AND last_alert_at > $2
            """, b_number, cooldown_cutoff)
            return row is not None

    async def set_cooldown(self, b_number: str):
        """Set cooldown for a B-number"""
        async with self.pg_pool.acquire() as conn:
            await conn.execute("""
                INSERT INTO cooldowns (b_number, last_alert_at, alert_count)
                VALUES ($1, $2, 1)
                ON CONFLICT (b_number) DO UPDATE
                SET last_alert_at = $2, alert_count = cooldowns.alert_count + 1
            """, b_number, datetime.utcnow())

    # =========================================================================
    # BLOCKED PATTERNS
    # =========================================================================

    async def is_blocked(self, b_number: str, a_number: str) -> bool:
        """Check if A-number is blocked for this B-number"""
        async with self.pg_pool.acquire() as conn:
            row = await conn.fetchrow("""
                SELECT 1 FROM blocked_patterns
                WHERE b_number = $1
                  AND $2 = ANY(a_numbers)
                  AND active = TRUE
                  AND expires_at > NOW()
            """, b_number, a_number)
            return row is not None

    async def create_block(self, block: BlockedPattern):
        """Create a blocked pattern"""
        async with self.pg_pool.acquire() as conn:
            await conn.execute("""
                INSERT INTO blocked_patterns (
                    pattern_id, b_number, a_numbers, alert_id,
                    blocked_at, expires_at, active, reason
                ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
            """,
                block.pattern_id, block.b_number, block.a_numbers,
                block.alert_id, block.blocked_at, block.expires_at,
                block.active, block.reason
            )

    # =========================================================================
    # WHITELIST OPERATIONS
    # =========================================================================

    async def is_whitelisted(self, b_number: str, a_number: str) -> bool:
        """Check if the pattern is whitelisted"""
        async with self.pg_pool.acquire() as conn:
            # Check B-number whitelist
            row = await conn.fetchrow("""
                SELECT 1 FROM whitelist
                WHERE (pattern_type = 'b_number' AND pattern = $1)
                   OR (pattern_type = 'a_number_prefix' AND $2 LIKE pattern || '%')
            """, b_number, a_number)
            return row is not None

    # =========================================================================
    # THREAT LEVEL QUERIES
    # =========================================================================

    async def get_threat_level(self, b_number: str) -> ThreatLevel:
        """Get current threat level for a B-number"""
        window_start = datetime.utcnow() - timedelta(seconds=settings.detection.window_seconds)

        async with self.pg_pool.acquire() as conn:
            row = await conn.fetchrow("""
                SELECT
                    COUNT(DISTINCT a_number) as distinct_a,
                    COUNT(DISTINCT source_ip) as distinct_ips,
                    COUNT(*) as call_count,
                    MAX(timestamp) as last_seen
                FROM calls
                WHERE b_number = $1
                  AND timestamp > $2
                  AND status IN ('active', 'ringing')
            """, b_number, window_start)

            distinct_a = row['distinct_a'] or 0
            threshold = settings.detection.threshold

            if distinct_a >= threshold:
                level = "critical"
            elif distinct_a >= threshold - 1:
                level = "high"
            elif distinct_a >= threshold - 2:
                level = "medium"
            else:
                level = "low"

            return ThreatLevel(
                b_number=b_number,
                threat_level=level,
                distinct_a_numbers=distinct_a,
                distinct_ips=row['distinct_ips'] or 0,
                call_count=row['call_count'] or 0,
                last_seen=row['last_seen'] or datetime.utcnow()
            )

    async def get_elevated_threats(self) -> List[ThreatLevel]:
        """Get all B-numbers with elevated threat levels"""
        window_start = datetime.utcnow() - timedelta(seconds=settings.detection.window_seconds)
        min_threshold = settings.detection.threshold - 2

        async with self.pg_pool.acquire() as conn:
            rows = await conn.fetch("""
                SELECT
                    b_number,
                    COUNT(DISTINCT a_number) as distinct_a,
                    COUNT(DISTINCT source_ip) as distinct_ips,
                    COUNT(*) as call_count,
                    MAX(timestamp) as last_seen
                FROM calls
                WHERE timestamp > $1
                  AND status IN ('active', 'ringing')
                GROUP BY b_number
                HAVING COUNT(DISTINCT a_number) >= $2
                ORDER BY distinct_a DESC
            """, window_start, min_threshold)

            threats = []
            threshold = settings.detection.threshold
            for row in rows:
                distinct_a = row['distinct_a']
                if distinct_a >= threshold:
                    level = "critical"
                elif distinct_a >= threshold - 1:
                    level = "high"
                else:
                    level = "medium"

                threats.append(ThreatLevel(
                    b_number=row['b_number'],
                    threat_level=level,
                    distinct_a_numbers=distinct_a,
                    distinct_ips=row['distinct_ips'],
                    call_count=row['call_count'],
                    last_seen=row['last_seen']
                ))

            return threats

    # =========================================================================
    # STATISTICS
    # =========================================================================

    async def get_stats(self) -> Dict[str, Any]:
        """Get detection statistics"""
        window_start = datetime.utcnow() - timedelta(seconds=settings.detection.window_seconds)

        async with self.pg_pool.acquire() as conn:
            # Get active calls count
            active_calls = await conn.fetchval("""
                SELECT COUNT(*) FROM calls
                WHERE timestamp > $1 AND status IN ('active', 'ringing')
            """, window_start)

            # Get total counts
            total_calls = await conn.fetchval("SELECT COUNT(*) FROM calls")
            total_alerts = await conn.fetchval("SELECT COUNT(*) FROM fraud_alerts")

            # Get alert counts by severity
            alert_counts = await conn.fetch("""
                SELECT severity, COUNT(*) as count
                FROM fraud_alerts
                WHERE created_at > NOW() - INTERVAL '24 hours'
                GROUP BY severity
            """)

            return {
                "total_calls": total_calls or 0,
                "total_alerts": total_alerts or 0,
                "active_calls": active_calls or 0,
                "alerts_by_severity": {row['severity']: row['count'] for row in alert_counts},
                "window_seconds": settings.detection.window_seconds,
                "threshold": settings.detection.threshold
            }

    # =========================================================================
    # CLEANUP / MAINTENANCE
    # =========================================================================

    async def cleanup_old_records(self, retention_seconds: int = 300):
        """Clean up old unflagged call records"""
        cutoff = datetime.utcnow() - timedelta(seconds=retention_seconds)
        async with self.pg_pool.acquire() as conn:
            result = await conn.execute("""
                DELETE FROM calls
                WHERE timestamp < $1 AND flagged = FALSE
            """, cutoff)
            deleted = int(result.split()[-1])
            if deleted > 0:
                logger.info("Cleaned up old records", count=deleted)

    async def expire_blocks(self):
        """Expire old blocked patterns"""
        async with self.pg_pool.acquire() as conn:
            await conn.execute("""
                UPDATE blocked_patterns
                SET active = FALSE
                WHERE expires_at < NOW() AND active = TRUE
            """)


# Global database client instance
db = LumaDBClient()
