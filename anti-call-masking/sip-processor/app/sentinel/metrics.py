"""Prometheus metrics for Sentinel Engine monitoring.

This module provides Prometheus-compatible metrics for monitoring
Sentinel's performance, alerts, and system health.
"""

from typing import Dict, Any
import time
from datetime import datetime


class PrometheusMetrics:
    """Prometheus metrics collector for Sentinel Engine."""

    def __init__(self):
        # Counter metrics
        self.cdr_records_ingested_total = 0
        self.cdr_records_duplicate_total = 0
        self.cdr_ingestion_errors_total = 0
        self.alerts_generated_total = 0
        self.alerts_by_severity: Dict[str, int] = {
            "LOW": 0,
            "MEDIUM": 0,
            "HIGH": 0,
            "CRITICAL": 0
        }
        self.detection_runs_total = 0
        self.websocket_connections_total = 0
        self.websocket_disconnections_total = 0
        self.realtime_events_received_total = 0

        # Gauge metrics
        self.active_websocket_connections = 0
        self.unreviewed_alerts = 0
        self.last_detection_timestamp = 0

        # Histogram metrics (stored as lists for percentile calculation)
        self.ingestion_duration_seconds: list[float] = []
        self.detection_duration_seconds: list[float] = []
        self.api_request_duration_seconds: Dict[str, list[float]] = {}

        # Summary metrics
        self.cache_hit_rate = 0.0
        self.database_pool_utilization = 0.0

    def increment_cdr_ingested(self, count: int = 1):
        """Increment CDR records ingested counter."""
        self.cdr_records_ingested_total += count

    def increment_cdr_duplicates(self, count: int = 1):
        """Increment CDR duplicate records counter."""
        self.cdr_records_duplicate_total += count

    def increment_ingestion_errors(self, count: int = 1):
        """Increment CDR ingestion errors counter."""
        self.cdr_ingestion_errors_total += count

    def increment_alert_generated(self, severity: str = "MEDIUM"):
        """Increment alerts generated counter.

        Args:
            severity: Alert severity (LOW, MEDIUM, HIGH, CRITICAL)
        """
        self.alerts_generated_total += 1
        if severity in self.alerts_by_severity:
            self.alerts_by_severity[severity] += 1

    def increment_detection_runs(self):
        """Increment detection runs counter."""
        self.detection_runs_total += 1
        self.last_detection_timestamp = time.time()

    def increment_websocket_connection(self):
        """Increment WebSocket connection counter."""
        self.websocket_connections_total += 1
        self.active_websocket_connections += 1

    def decrement_websocket_connection(self):
        """Decrement active WebSocket connections."""
        self.websocket_disconnections_total += 1
        if self.active_websocket_connections > 0:
            self.active_websocket_connections -= 1

    def increment_realtime_events(self, count: int = 1):
        """Increment real-time events received counter."""
        self.realtime_events_received_total += count

    def set_unreviewed_alerts(self, count: int):
        """Set unreviewed alerts gauge.

        Args:
            count: Number of unreviewed alerts
        """
        self.unreviewed_alerts = count

    def record_ingestion_duration(self, duration_seconds: float):
        """Record CDR ingestion duration.

        Args:
            duration_seconds: Duration in seconds
        """
        self.ingestion_duration_seconds.append(duration_seconds)
        # Keep only last 1000 measurements
        if len(self.ingestion_duration_seconds) > 1000:
            self.ingestion_duration_seconds = self.ingestion_duration_seconds[-1000:]

    def record_detection_duration(self, duration_seconds: float):
        """Record detection run duration.

        Args:
            duration_seconds: Duration in seconds
        """
        self.detection_duration_seconds.append(duration_seconds)
        if len(self.detection_duration_seconds) > 1000:
            self.detection_duration_seconds = self.detection_duration_seconds[-1000:]

    def record_api_request(self, endpoint: str, duration_seconds: float):
        """Record API request duration.

        Args:
            endpoint: API endpoint name
            duration_seconds: Request duration in seconds
        """
        if endpoint not in self.api_request_duration_seconds:
            self.api_request_duration_seconds[endpoint] = []

        self.api_request_duration_seconds[endpoint].append(duration_seconds)
        if len(self.api_request_duration_seconds[endpoint]) > 1000:
            self.api_request_duration_seconds[endpoint] = \
                self.api_request_duration_seconds[endpoint][-1000:]

    def update_cache_hit_rate(self, hit_rate: float):
        """Update cache hit rate metric.

        Args:
            hit_rate: Cache hit rate as percentage (0-100)
        """
        self.cache_hit_rate = hit_rate

    def update_pool_utilization(self, utilization: float):
        """Update database pool utilization.

        Args:
            utilization: Pool utilization as percentage (0-100)
        """
        self.database_pool_utilization = utilization

    def _calculate_percentile(self, data: list[float], percentile: float) -> float:
        """Calculate percentile from list of values.

        Args:
            data: List of values
            percentile: Percentile to calculate (0-1)

        Returns:
            Percentile value
        """
        if not data:
            return 0.0
        sorted_data = sorted(data)
        index = int(len(sorted_data) * percentile)
        return round(sorted_data[min(index, len(sorted_data) - 1)], 3)

    def get_prometheus_metrics(self) -> str:
        """Generate Prometheus-formatted metrics output.

        Returns:
            String containing Prometheus metrics in exposition format
        """
        lines = []

        # Counter metrics
        lines.append("# HELP sentinel_cdr_records_ingested_total Total CDR records ingested")
        lines.append("# TYPE sentinel_cdr_records_ingested_total counter")
        lines.append(f"sentinel_cdr_records_ingested_total {self.cdr_records_ingested_total}")

        lines.append("# HELP sentinel_cdr_records_duplicate_total Total duplicate CDR records skipped")
        lines.append("# TYPE sentinel_cdr_records_duplicate_total counter")
        lines.append(f"sentinel_cdr_records_duplicate_total {self.cdr_records_duplicate_total}")

        lines.append("# HELP sentinel_cdr_ingestion_errors_total Total CDR ingestion errors")
        lines.append("# TYPE sentinel_cdr_ingestion_errors_total counter")
        lines.append(f"sentinel_cdr_ingestion_errors_total {self.cdr_ingestion_errors_total}")

        lines.append("# HELP sentinel_alerts_generated_total Total fraud alerts generated")
        lines.append("# TYPE sentinel_alerts_generated_total counter")
        lines.append(f"sentinel_alerts_generated_total {self.alerts_generated_total}")

        lines.append("# HELP sentinel_alerts_by_severity_total Alerts by severity level")
        lines.append("# TYPE sentinel_alerts_by_severity_total counter")
        for severity, count in self.alerts_by_severity.items():
            lines.append(f'sentinel_alerts_by_severity_total{{severity="{severity}"}} {count}')

        lines.append("# HELP sentinel_detection_runs_total Total detection runs executed")
        lines.append("# TYPE sentinel_detection_runs_total counter")
        lines.append(f"sentinel_detection_runs_total {self.detection_runs_total}")

        lines.append("# HELP sentinel_websocket_connections_total Total WebSocket connections")
        lines.append("# TYPE sentinel_websocket_connections_total counter")
        lines.append(f"sentinel_websocket_connections_total {self.websocket_connections_total}")

        lines.append("# HELP sentinel_realtime_events_received_total Total real-time events received")
        lines.append("# TYPE sentinel_realtime_events_received_total counter")
        lines.append(f"sentinel_realtime_events_received_total {self.realtime_events_received_total}")

        # Gauge metrics
        lines.append("# HELP sentinel_active_websocket_connections Current active WebSocket connections")
        lines.append("# TYPE sentinel_active_websocket_connections gauge")
        lines.append(f"sentinel_active_websocket_connections {self.active_websocket_connections}")

        lines.append("# HELP sentinel_unreviewed_alerts Current unreviewed alerts")
        lines.append("# TYPE sentinel_unreviewed_alerts gauge")
        lines.append(f"sentinel_unreviewed_alerts {self.unreviewed_alerts}")

        lines.append("# HELP sentinel_last_detection_timestamp Unix timestamp of last detection run")
        lines.append("# TYPE sentinel_last_detection_timestamp gauge")
        lines.append(f"sentinel_last_detection_timestamp {self.last_detection_timestamp}")

        # Histogram metrics
        if self.ingestion_duration_seconds:
            lines.append("# HELP sentinel_ingestion_duration_seconds CDR ingestion duration")
            lines.append("# TYPE sentinel_ingestion_duration_seconds histogram")
            lines.append(f'sentinel_ingestion_duration_seconds{{quantile="0.5"}} '
                        f'{self._calculate_percentile(self.ingestion_duration_seconds, 0.5)}')
            lines.append(f'sentinel_ingestion_duration_seconds{{quantile="0.95"}} '
                        f'{self._calculate_percentile(self.ingestion_duration_seconds, 0.95)}')
            lines.append(f'sentinel_ingestion_duration_seconds{{quantile="0.99"}} '
                        f'{self._calculate_percentile(self.ingestion_duration_seconds, 0.99)}')

        if self.detection_duration_seconds:
            lines.append("# HELP sentinel_detection_duration_seconds Detection run duration")
            lines.append("# TYPE sentinel_detection_duration_seconds histogram")
            lines.append(f'sentinel_detection_duration_seconds{{quantile="0.5"}} '
                        f'{self._calculate_percentile(self.detection_duration_seconds, 0.5)}')
            lines.append(f'sentinel_detection_duration_seconds{{quantile="0.95"}} '
                        f'{self._calculate_percentile(self.detection_duration_seconds, 0.95)}')
            lines.append(f'sentinel_detection_duration_seconds{{quantile="0.99"}} '
                        f'{self._calculate_percentile(self.detection_duration_seconds, 0.99)}')

        # API request duration by endpoint
        for endpoint, durations in self.api_request_duration_seconds.items():
            if durations:
                lines.append(f"# HELP sentinel_api_request_duration_seconds API request duration for {endpoint}")
                lines.append(f"# TYPE sentinel_api_request_duration_seconds histogram")
                lines.append(f'sentinel_api_request_duration_seconds{{endpoint="{endpoint}",quantile="0.95"}} '
                            f'{self._calculate_percentile(durations, 0.95)}')

        # Summary metrics
        lines.append("# HELP sentinel_cache_hit_rate Cache hit rate percentage")
        lines.append("# TYPE sentinel_cache_hit_rate gauge")
        lines.append(f"sentinel_cache_hit_rate {self.cache_hit_rate}")

        lines.append("# HELP sentinel_database_pool_utilization Database connection pool utilization")
        lines.append("# TYPE sentinel_database_pool_utilization gauge")
        lines.append(f"sentinel_database_pool_utilization {self.database_pool_utilization}")

        return "\n".join(lines) + "\n"

    def get_json_metrics(self) -> Dict[str, Any]:
        """Get metrics as JSON-serializable dictionary.

        Returns:
            Dictionary containing all current metrics
        """
        return {
            "counters": {
                "cdr_records_ingested_total": self.cdr_records_ingested_total,
                "cdr_records_duplicate_total": self.cdr_records_duplicate_total,
                "cdr_ingestion_errors_total": self.cdr_ingestion_errors_total,
                "alerts_generated_total": self.alerts_generated_total,
                "alerts_by_severity": self.alerts_by_severity.copy(),
                "detection_runs_total": self.detection_runs_total,
                "websocket_connections_total": self.websocket_connections_total,
                "realtime_events_received_total": self.realtime_events_received_total
            },
            "gauges": {
                "active_websocket_connections": self.active_websocket_connections,
                "unreviewed_alerts": self.unreviewed_alerts,
                "last_detection_timestamp": self.last_detection_timestamp,
                "cache_hit_rate": self.cache_hit_rate,
                "database_pool_utilization": self.database_pool_utilization
            },
            "histograms": {
                "ingestion_duration": {
                    "p50": self._calculate_percentile(self.ingestion_duration_seconds, 0.5),
                    "p95": self._calculate_percentile(self.ingestion_duration_seconds, 0.95),
                    "p99": self._calculate_percentile(self.ingestion_duration_seconds, 0.99)
                } if self.ingestion_duration_seconds else None,
                "detection_duration": {
                    "p50": self._calculate_percentile(self.detection_duration_seconds, 0.5),
                    "p95": self._calculate_percentile(self.detection_duration_seconds, 0.95),
                    "p99": self._calculate_percentile(self.detection_duration_seconds, 0.99)
                } if self.detection_duration_seconds else None
            }
        }


# Global metrics instance
_sentinel_metrics = PrometheusMetrics()


def get_metrics() -> PrometheusMetrics:
    """Get global Prometheus metrics instance.

    Returns:
        Global PrometheusMetrics instance
    """
    return _sentinel_metrics
