"""
Sentinel database operations

Handles database interactions for CDR ingestion and alert management.
"""
from typing import List, Optional
import asyncpg
from .models import CallRecord, SentinelFraudAlert


class SentinelDatabase:
    """Database operations for Sentinel engine"""

    def __init__(self, pool: asyncpg.Pool):
        self.pool = pool

    async def insert_call_records(self, records: List[CallRecord]) -> int:
        """
        Batch insert call records into database

        Args:
            records: List of CallRecord objects

        Returns:
            Number of records inserted
        """
        if not records:
            return 0

        # Batch insert in chunks of 1000
        BATCH_SIZE = 1000
        total_inserted = 0

        for i in range(0, len(records), BATCH_SIZE):
            batch = records[i:i + BATCH_SIZE]

            # Prepare values for batch insert
            values = [
                (
                    r.call_timestamp,
                    r.caller_number,
                    r.callee_number,
                    r.duration_seconds,
                    r.call_direction,
                    r.termination_cause,
                    r.location_code
                )
                for r in batch
            ]

            query = """
                INSERT INTO call_records (
                    call_timestamp, caller_number, callee_number, duration_seconds,
                    call_direction, termination_cause, location_code
                )
                VALUES ($1, $2, $3, $4, $5, $6, $7)
                ON CONFLICT DO NOTHING
            """

            async with self.pool.acquire() as conn:
                async with conn.transaction():
                    for value_tuple in values:
                        await conn.execute(query, *value_tuple)
                        total_inserted += 1

        return total_inserted

    async def check_duplicates(self, records: List[CallRecord]) -> List[CallRecord]:
        """
        Check which records already exist in the database

        Args:
            records: List of CallRecord objects

        Returns:
            List of CallRecord objects that don't exist in database
        """
        if not records:
            return []

        async with self.pool.acquire() as conn:
            non_duplicates = []

            for record in records:
                query = """
                    SELECT 1 FROM call_records
                    WHERE caller_number = $1
                      AND callee_number = $2
                      AND call_timestamp = $3
                    LIMIT 1
                """

                result = await conn.fetchval(
                    query,
                    record.caller_number,
                    record.callee_number,
                    record.call_timestamp
                )

                if result is None:
                    non_duplicates.append(record)

        return non_duplicates

    async def create_fraud_alert(self, alert: SentinelFraudAlert) -> int:
        """
        Create a fraud alert in the database

        Args:
            alert: SentinelFraudAlert object

        Returns:
            ID of created alert
        """
        query = """
            INSERT INTO sentinel_fraud_alerts (
                alert_type, suspect_number, alert_severity, evidence_summary,
                call_count, unique_destinations, avg_duration_seconds, detection_rule
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
            RETURNING id
        """

        async with self.pool.acquire() as conn:
            alert_id = await conn.fetchval(
                query,
                alert.alert_type,
                alert.suspect_number,
                alert.alert_severity,
                alert.evidence_summary,
                alert.call_count,
                alert.unique_destinations,
                alert.avg_duration_seconds,
                alert.detection_rule
            )

        return alert_id

    async def get_alerts(
        self,
        severity: Optional[str] = None,
        reviewed: Optional[bool] = None,
        limit: int = 50
    ) -> List[dict]:
        """
        Retrieve fraud alerts with optional filtering

        Args:
            severity: Filter by alert severity (LOW, MEDIUM, HIGH, CRITICAL)
            reviewed: Filter by reviewed status
            limit: Maximum number of alerts to return

        Returns:
            List of alert dictionaries
        """
        query = "SELECT * FROM sentinel_fraud_alerts WHERE 1=1"
        params = []
        param_count = 0

        if severity:
            param_count += 1
            query += f" AND alert_severity = ${param_count}"
            params.append(severity)

        if reviewed is not None:
            param_count += 1
            query += f" AND reviewed = ${param_count}"
            params.append(reviewed)

        param_count += 1
        query += f" ORDER BY created_at DESC LIMIT ${param_count}"
        params.append(limit)

        async with self.pool.acquire() as conn:
            rows = await conn.fetch(query, *params)
            return [dict(row) for row in rows]
