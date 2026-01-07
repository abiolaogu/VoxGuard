"""
Anti-Call Masking Detection System - LumaDB Edition
Core detection engine using LumaDB for time-series analysis
"""

import time
from datetime import datetime, timedelta
from typing import Optional, List, Tuple
import structlog
import uuid
import re

from config import settings
from models import (
    CallEvent, CallRecord, FraudAlert, BlockedPattern,
    DetectionResult, AlertSeverity, AlertStatus, CallStatus
)
from database import db

logger = structlog.get_logger()


class DetectionEngine:
    """
    Anti-Call Masking Detection Engine using LumaDB.

    Detects multicall masking attacks by identifying when 5+ distinct
    A-numbers call the same B-number within a 5-second sliding window.

    Replaces kdb+ detection logic with LumaDB SQL queries.
    """

    def __init__(self):
        self.processed_count = 0
        self.alert_count = 0
        self.latencies: List[float] = []

    @staticmethod
    def normalize_number(number: str) -> str:
        """Normalize phone number by removing formatting characters"""
        if not number:
            return ""
        # Remove common formatting
        normalized = re.sub(r'[\s\-\(\)\.]', '', str(number))
        return normalized

    def _calculate_severity(self, distinct_count: int) -> AlertSeverity:
        """Calculate alert severity based on distinct A-number count"""
        if distinct_count >= settings.detection.threshold + 5:
            return AlertSeverity.CRITICAL
        elif distinct_count >= settings.detection.threshold + 2:
            return AlertSeverity.HIGH
        elif distinct_count >= settings.detection.threshold:
            return AlertSeverity.MEDIUM
        return AlertSeverity.LOW

    async def process_call(self, event: CallEvent) -> DetectionResult:
        """
        Process an incoming call event and check for masking attack.

        This is the main entry point for call processing.
        Implements the same logic as the kdb+ detection.q but using LumaDB.
        """
        start_time = time.perf_counter()

        try:
            # Normalize phone numbers
            a_number = self.normalize_number(event.a_number)
            b_number = self.normalize_number(event.b_number)

            if not a_number or not b_number:
                return DetectionResult(
                    detected=False,
                    message="Invalid phone numbers"
                )

            # Check whitelist
            if await db.is_whitelisted(b_number, a_number):
                return DetectionResult(
                    detected=False,
                    message="Pattern is whitelisted"
                )

            # Check if pattern is blocked
            if await db.is_blocked(b_number, a_number):
                return DetectionResult(
                    detected=True,
                    message="Pattern is blocked - call rejected"
                )

            # Create call record
            call = CallRecord(
                call_id=event.call_id or str(uuid.uuid4()),
                a_number=a_number,
                b_number=b_number,
                timestamp=event.timestamp or datetime.utcnow(),
                status=CallStatus.ACTIVE,
                flagged=False,
                switch_id=event.switch_id or "default",
                raw_call_id=event.raw_call_id,
                source_ip=event.source_ip
            )

            # Insert call into LumaDB
            await db.insert_call(call)

            # Check for masking attack
            is_masking, involved_a_numbers, source_ips = await self._check_masking(
                b_number, call.timestamp
            )

            alert_id = None
            if is_masking:
                # Check cooldown to avoid duplicate alerts
                if not await db.is_in_cooldown(b_number):
                    alert_id = await self._create_alert(
                        b_number, involved_a_numbers, source_ips, call.timestamp
                    )
                    self.alert_count += 1

            # Calculate latency
            latency_ms = (time.perf_counter() - start_time) * 1000
            self.latencies.append(latency_ms)
            if len(self.latencies) > 100:
                self.latencies = self.latencies[-100:]

            self.processed_count += 1

            return DetectionResult(
                detected=is_masking,
                alert_id=alert_id,
                latency_ms=latency_ms,
                message="Masking attack detected" if is_masking else "Call processed normally"
            )

        except Exception as e:
            logger.error("Error processing call", error=str(e), event=event.model_dump())
            return DetectionResult(
                detected=False,
                message=f"Error: {str(e)}"
            )

    async def _check_masking(
        self,
        b_number: str,
        current_ts: datetime
    ) -> Tuple[bool, List[str], List[str]]:
        """
        Check if a B-number is under masking attack.

        Uses LumaDB's SQL query to count distinct A-numbers in the sliding window.
        This replaces the kdb+ checkMasking function.
        """
        window_seconds = settings.detection.window_seconds
        window_start = current_ts - timedelta(seconds=window_seconds)

        # Get calls in window
        calls = await db.get_calls_in_window(b_number, window_start, current_ts)

        # Get distinct A-numbers
        distinct_a_numbers = list(set(call.a_number for call in calls))

        # Get distinct source IPs
        distinct_ips = list(set(
            call.source_ip for call in calls
            if call.source_ip
        ))

        # Check threshold
        is_masking = len(distinct_a_numbers) >= settings.detection.threshold

        return is_masking, distinct_a_numbers, distinct_ips

    async def _create_alert(
        self,
        b_number: str,
        involved_a_numbers: List[str],
        source_ips: List[str],
        detection_time: datetime
    ) -> str:
        """Create a fraud alert and flag associated calls"""
        window_start = detection_time - timedelta(seconds=settings.detection.window_seconds)

        # Get calls to flag
        calls = await db.get_calls_in_window(b_number, window_start, detection_time)
        calls_to_flag = [c for c in calls if c.a_number in involved_a_numbers]
        call_ids = [c.call_id for c in calls_to_flag]

        # Calculate severity
        severity = self._calculate_severity(len(involved_a_numbers))

        # Create alert
        alert = FraudAlert(
            alert_id=str(uuid.uuid4()),
            b_number=b_number,
            a_numbers=involved_a_numbers,
            call_ids=call_ids,
            source_ips=source_ips,
            call_count=len(calls_to_flag),
            window_start=window_start,
            window_end=detection_time,
            severity=severity,
            status=AlertStatus.NEW
        )

        alert_id = await db.create_alert(alert)

        # Flag the calls
        await db.flag_calls(call_ids, alert_id)

        # Set cooldown
        await db.set_cooldown(b_number)

        # Auto-block if enabled
        if settings.detection.auto_block:
            block = BlockedPattern(
                b_number=b_number,
                a_numbers=involved_a_numbers,
                alert_id=alert_id,
                expires_at=datetime.utcnow() + timedelta(hours=settings.detection.block_duration_hours)
            )
            await db.create_block(block)

        logger.warning(
            "Masking attack detected",
            alert_id=alert_id,
            b_number=b_number,
            distinct_a_numbers=len(involved_a_numbers),
            severity=severity.value
        )

        return alert_id

    async def process_batch(self, events: List[CallEvent]) -> List[DetectionResult]:
        """Process a batch of call events"""
        results = []
        for event in events:
            result = await self.process_call(event)
            results.append(result)
        return results

    def get_stats(self) -> dict:
        """Get detection statistics"""
        return {
            "processed_count": self.processed_count,
            "alert_count": self.alert_count,
            "avg_latency_ms": sum(self.latencies) / len(self.latencies) if self.latencies else 0,
            "max_latency_ms": max(self.latencies) if self.latencies else 0,
            "window_seconds": settings.detection.window_seconds,
            "threshold": settings.detection.threshold
        }

    async def set_threshold(self, threshold: int) -> bool:
        """Update detection threshold"""
        if not 2 <= threshold <= 100:
            return False
        settings.detection.threshold = threshold
        logger.info("Detection threshold updated", threshold=threshold)
        return True

    async def set_window(self, seconds: int) -> bool:
        """Update detection window"""
        if not 1 <= seconds <= 60:
            return False
        settings.detection.window_seconds = seconds
        logger.info("Detection window updated", seconds=seconds)
        return True


# Global detection engine instance
engine = DetectionEngine()
