"""
Sentinel Detection Engine

Implements fraud detection rules including SDHF (Short Duration High Frequency) analysis.
"""
from datetime import datetime, timedelta
from typing import List, Dict, Optional
import asyncpg
from .models import SentinelFraudAlert


class SDHFDetector:
    """Short Duration High Frequency (SDHF) fraud detection"""

    def __init__(self, pool: asyncpg.Pool):
        self.pool = pool

    async def detect_sdhf_patterns(
        self,
        time_window_hours: int = 24,
        min_unique_destinations: int = 50,
        max_avg_duration_seconds: float = 3.0
    ) -> List[Dict]:
        """
        Detect SDHF patterns indicating potential SIM Box fraud

        Args:
            time_window_hours: Time window to analyze (default: 24 hours)
            min_unique_destinations: Minimum unique destinations to trigger alert
            max_avg_duration_seconds: Maximum average duration for suspicious pattern

        Returns:
            List of detection results with suspect numbers and statistics
        """
        # Calculate time threshold
        time_threshold = datetime.utcnow() - timedelta(hours=time_window_hours)

        query = """
            WITH caller_stats AS (
                SELECT
                    caller_number,
                    COUNT(*) as call_count,
                    COUNT(DISTINCT callee_number) as unique_destinations,
                    AVG(duration_seconds) as avg_duration,
                    MIN(call_timestamp) as first_call,
                    MAX(call_timestamp) as last_call
                FROM call_records
                WHERE call_timestamp >= $1
                GROUP BY caller_number
                HAVING
                    COUNT(DISTINCT callee_number) > $2
                    AND AVG(duration_seconds) < $3
            )
            SELECT
                caller_number,
                call_count,
                unique_destinations,
                ROUND(avg_duration::numeric, 2) as avg_duration,
                first_call,
                last_call
            FROM caller_stats
            ORDER BY unique_destinations DESC, avg_duration ASC
        """

        async with self.pool.acquire() as conn:
            rows = await conn.fetch(
                query,
                time_threshold,
                min_unique_destinations,
                max_avg_duration_seconds
            )

            return [dict(row) for row in rows]

    async def generate_sdhf_alerts(
        self,
        time_window_hours: int = 24,
        min_unique_destinations: int = 50,
        max_avg_duration_seconds: float = 3.0
    ) -> List[int]:
        """
        Detect SDHF patterns and generate fraud alerts

        Returns:
            List of created alert IDs
        """
        # Detect suspicious patterns
        detections = await self.detect_sdhf_patterns(
            time_window_hours,
            min_unique_destinations,
            max_avg_duration_seconds
        )

        if not detections:
            return []

        # Generate alerts for each detection
        alert_ids = []

        for detection in detections:
            # Determine severity based on metrics
            severity = self._calculate_severity(
                detection['unique_destinations'],
                detection['avg_duration'],
                detection['call_count']
            )

            # Create evidence summary
            evidence = (
                f"Caller {detection['caller_number']} made {detection['call_count']} calls "
                f"to {detection['unique_destinations']} unique destinations "
                f"with average duration of {detection['avg_duration']}s "
                f"in the last {time_window_hours} hours. "
                f"First call: {detection['first_call']}, Last call: {detection['last_call']}."
            )

            # Create alert
            alert = SentinelFraudAlert(
                alert_type="SDHF_SIMBOX",
                suspect_number=detection['caller_number'],
                alert_severity=severity,
                evidence_summary=evidence,
                call_count=detection['call_count'],
                unique_destinations=detection['unique_destinations'],
                avg_duration_seconds=float(detection['avg_duration']),
                detection_rule="SDHF_001"
            )

            # Insert alert into database
            alert_id = await self._create_alert(alert)
            alert_ids.append(alert_id)

        return alert_ids

    def _calculate_severity(
        self,
        unique_destinations: int,
        avg_duration: float,
        call_count: int
    ) -> str:
        """
        Calculate alert severity based on detection metrics

        Args:
            unique_destinations: Number of unique destinations called
            avg_duration: Average call duration in seconds
            call_count: Total number of calls

        Returns:
            Severity level: LOW, MEDIUM, HIGH, or CRITICAL
        """
        # CRITICAL: Extremely high volume, very short duration
        if unique_destinations >= 200 and avg_duration <= 1.5:
            return "CRITICAL"

        # HIGH: High volume with short duration
        if unique_destinations >= 100 and avg_duration <= 2.0:
            return "HIGH"

        # MEDIUM: Moderate volume
        if unique_destinations >= 75 or avg_duration <= 1.0:
            return "HIGH"

        # LOW: Just above threshold
        return "MEDIUM"

    async def _create_alert(self, alert: SentinelFraudAlert) -> int:
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


class FraudDetectionEngine:
    """Main fraud detection engine coordinating multiple detection rules"""

    def __init__(self, pool: asyncpg.Pool):
        self.pool = pool
        self.sdhf_detector = SDHFDetector(pool)

    async def run_all_detections(self) -> Dict[str, List[int]]:
        """
        Run all enabled detection rules

        Returns:
            Dictionary mapping rule names to lists of generated alert IDs
        """
        results = {}

        # Run SDHF detection
        sdhf_alerts = await self.sdhf_detector.generate_sdhf_alerts()
        results['SDHF'] = sdhf_alerts

        # Future: Add more detection rules here
        # results['GEO_ANOMALY'] = await self.geo_detector.generate_alerts()
        # results['BEHAVIORAL'] = await self.behavioral_detector.generate_alerts()

        return results
