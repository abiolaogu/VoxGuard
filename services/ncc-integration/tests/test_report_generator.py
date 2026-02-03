"""Tests for report generator."""

import csv
import json
import pytest
from datetime import date, datetime
from pathlib import Path
from unittest.mock import AsyncMock, MagicMock, patch

from ncc_integration.report_generator import (
    ReportGenerator,
    DatabaseConfig,
    ReportGenerationError,
)


@pytest.fixture
def db_config():
    """Create test database configuration."""
    return DatabaseConfig(
        host="localhost",
        port=5432,
        database="test_db",
        user="test_user",
        password="test_pass",
    )


@pytest.fixture
def mock_connection():
    """Create mock database connection."""
    conn = AsyncMock()
    return conn


@pytest.fixture
def test_report_date():
    """Test report date."""
    return date(2026, 1, 28)


class TestReportGenerator:
    """Test suite for report generator."""

    @pytest.mark.asyncio
    async def test_query_daily_statistics(self, db_config, mock_connection, test_report_date):
        """Test querying daily statistics from database."""
        generator = ReportGenerator(db_config, "ICL-NG-2025-001234")
        generator.conn = mock_connection

        # Mock database responses
        mock_connection.fetchval.side_effect = [
            12500000,  # total_calls
            23,        # calls_disconnected
            8,         # patterns_blocked
        ]

        mock_connection.fetch.return_value = [
            {"severity": "critical", "count": 5},
            {"severity": "high", "count": 12},
            {"severity": "medium", "count": 18},
            {"severity": "low", "count": 10},
        ]

        mock_connection.fetchrow.return_value = {
            "p99_latency": 0.82,
            "avg_latency": 0.45,
        }

        stats = await generator._query_daily_statistics(test_report_date)

        assert stats["total_calls_processed"] == 12500000
        assert stats["fraud_alerts_generated"] == 45  # sum of severities
        assert stats["alerts_by_severity"]["critical"] == 5
        assert stats["alerts_by_severity"]["high"] == 12
        assert stats["calls_disconnected"] == 23
        assert stats["detection_latency_p99_ms"] == 0.82

    @pytest.mark.asyncio
    async def test_query_alert_details(self, db_config, mock_connection, test_report_date):
        """Test querying alert details."""
        generator = ReportGenerator(db_config, "ICL-NG-2025-001234")
        generator.conn = mock_connection

        # Mock alert data
        mock_connection.fetch.return_value = [
            {
                "alert_id": "ALT-2026-0001234",
                "detected_at": datetime(2026, 1, 28, 10, 23, 45),
                "severity": "CRITICAL",
                "b_number": "+2348012345678",
                "a_number_count": 7,
                "detection_window_ms": 4200,
                "action_taken": "DISCONNECTED",
                "ncc_incident_id": "NCC-2026-01-0001234",
            },
        ]

        alerts = await generator._query_alert_details(test_report_date)

        assert len(alerts) == 1
        assert alerts[0]["alert_id"] == "ALT-2026-0001234"
        assert alerts[0]["severity"] == "CRITICAL"
        assert alerts[0]["b_number"] == "+2348012345678"
        assert alerts[0]["a_number_count"] == 7

    @pytest.mark.asyncio
    async def test_query_top_targets(self, db_config, mock_connection, test_report_date):
        """Test querying top targeted numbers."""
        generator = ReportGenerator(db_config, "ICL-NG-2025-001234")
        generator.conn = mock_connection

        # Mock top targets data
        mock_connection.fetch.return_value = [
            {
                "b_number": "+2348012345678",
                "incident_count": 5,
                "total_a_numbers": 23,
                "first_incident": datetime(2026, 1, 28, 8, 15, 0),
                "last_incident": datetime(2026, 1, 28, 22, 30, 0),
            },
            {
                "b_number": "+2348023456789",
                "incident_count": 3,
                "total_a_numbers": 12,
                "first_incident": datetime(2026, 1, 28, 10, 0, 0),
                "last_incident": datetime(2026, 1, 28, 18, 45, 0),
            },
        ]

        targets = await generator._query_top_targets(test_report_date, limit=10)

        assert len(targets) == 2
        assert targets[0]["rank"] == 1
        assert targets[0]["b_number"] == "+2348012345678"
        assert targets[0]["incident_count"] == 5
        assert targets[1]["rank"] == 2

    def test_generate_statistics_csv(self, db_config, tmp_path, test_report_date):
        """Test generating statistics CSV file."""
        generator = ReportGenerator(db_config, "ICL-NG-2025-001234")

        statistics = {
            "total_calls_processed": 12500000,
            "fraud_alerts_generated": 45,
            "alerts_by_severity": {
                "critical": 5,
                "high": 12,
                "medium": 18,
                "low": 10,
            },
            "calls_disconnected": 23,
            "patterns_blocked": 8,
            "detection_latency_p99_ms": 0.82,
            "detection_latency_avg_ms": 0.45,
            "system_uptime_percent": 99.998,
            "false_positive_rate_percent": 0.21,
        }

        output_path = tmp_path / "stats.csv"
        generator._generate_statistics_csv(output_path, statistics, test_report_date)

        assert output_path.exists()

        # Verify CSV content
        with open(output_path, "r") as f:
            reader = csv.DictReader(f)
            rows = list(reader)

        assert len(rows) == 12  # 12 metrics
        assert rows[0]["metric_name"] == "total_calls_processed"
        assert rows[0]["metric_value"] == "12500000"

    def test_generate_alerts_csv(self, db_config, tmp_path):
        """Test generating alerts CSV file."""
        generator = ReportGenerator(db_config, "ICL-NG-2025-001234")

        alerts = [
            {
                "alert_id": "ALT-2026-0001234",
                "detected_at": "2026-01-28T10:23:45Z",
                "severity": "CRITICAL",
                "b_number": "+2348012345678",
                "a_number_count": 7,
                "detection_window_ms": 4200,
                "action_taken": "DISCONNECTED",
                "ncc_incident_id": "NCC-2026-01-0001234",
            },
        ]

        output_path = tmp_path / "alerts.csv"
        generator._generate_alerts_csv(output_path, alerts)

        assert output_path.exists()

        # Verify CSV content
        with open(output_path, "r") as f:
            reader = csv.DictReader(f)
            rows = list(reader)

        assert len(rows) == 1
        assert rows[0]["alert_id"] == "ALT-2026-0001234"
        assert rows[0]["severity"] == "CRITICAL"

    def test_generate_alerts_csv_empty(self, db_config, tmp_path):
        """Test generating alerts CSV with no alerts."""
        generator = ReportGenerator(db_config, "ICL-NG-2025-001234")

        output_path = tmp_path / "alerts_empty.csv"
        generator._generate_alerts_csv(output_path, [])

        assert output_path.exists()

        # Should have header even with no data
        with open(output_path, "r") as f:
            lines = f.readlines()

        assert len(lines) == 1  # Header only
        assert "alert_id" in lines[0]

    def test_calculate_checksum(self, db_config, tmp_path):
        """Test checksum calculation."""
        generator = ReportGenerator(db_config, "ICL-NG-2025-001234")

        # Create test files
        file1 = tmp_path / "file1.txt"
        file2 = tmp_path / "file2.txt"
        file1.write_text("test data 1")
        file2.write_text("test data 2")

        checksum = generator._calculate_checksum(file1, file2)

        # Verify checksum is a valid SHA-256 hex string
        assert len(checksum) == 64
        assert all(c in "0123456789abcdef" for c in checksum)

    def test_generate_summary_json(self, db_config, tmp_path, test_report_date):
        """Test generating JSON summary file."""
        generator = ReportGenerator(db_config, "ICL-NG-2025-001234")

        statistics = {
            "total_calls_processed": 12500000,
            "fraud_alerts_generated": 45,
            "alerts_by_severity": {
                "critical": 5,
                "high": 12,
                "medium": 18,
                "low": 10,
            },
            "calls_disconnected": 23,
            "patterns_blocked": 8,
            "detection_latency_p99_ms": 0.82,
            "detection_latency_avg_ms": 0.45,
            "system_uptime_percent": 99.998,
            "false_positive_rate_percent": 0.21,
        }

        file_names = ["file1.csv", "file2.csv", "file3.csv"]
        checksum = "abc123def456"

        output_path = tmp_path / "summary.json"
        generator._generate_summary_json(
            output_path,
            test_report_date,
            statistics,
            file_names,
            checksum,
        )

        assert output_path.exists()

        # Verify JSON content
        with open(output_path, "r") as f:
            summary = json.load(f)

        assert summary["report_date"] == "2026-01-28"
        assert summary["icl_license"] == "ICL-NG-2025-001234"
        assert summary["statistics"]["total_calls_processed"] == 12500000
        assert summary["checksum"]["algorithm"] == "SHA-256"
        assert summary["checksum"]["value"] == checksum

    @pytest.mark.asyncio
    async def test_generate_daily_report_integration(
        self,
        db_config,
        mock_connection,
        tmp_path,
        test_report_date,
    ):
        """Test complete daily report generation workflow."""
        generator = ReportGenerator(db_config, "ICL-NG-2025-001234")
        generator.conn = mock_connection

        # Mock all database queries
        mock_connection.fetchval.side_effect = [
            12500000,  # total_calls
            23,        # calls_disconnected
            8,         # patterns_blocked
        ]

        mock_connection.fetch.side_effect = [
            # Alerts by severity
            [
                {"severity": "critical", "count": 5},
                {"severity": "high", "count": 12},
            ],
            # Alert details
            [
                {
                    "alert_id": "ALT-2026-0001234",
                    "detected_at": datetime(2026, 1, 28, 10, 23, 45),
                    "severity": "CRITICAL",
                    "b_number": "+2348012345678",
                    "a_number_count": 7,
                    "detection_window_ms": 4200,
                    "action_taken": "DISCONNECTED",
                    "ncc_incident_id": "NCC-2026-01-0001234",
                },
            ],
            # Top targets
            [
                {
                    "b_number": "+2348012345678",
                    "incident_count": 5,
                    "total_a_numbers": 23,
                    "first_incident": datetime(2026, 1, 28, 8, 15, 0),
                    "last_incident": datetime(2026, 1, 28, 22, 30, 0),
                },
            ],
        ]

        mock_connection.fetchrow.return_value = {
            "p99_latency": 0.82,
            "avg_latency": 0.45,
        }

        result = await generator.generate_daily_report(test_report_date, tmp_path)

        # Verify files were created
        assert Path(result["files"]["stats"]).exists()
        assert Path(result["files"]["alerts"]).exists()
        assert Path(result["files"]["targets"]).exists()
        assert Path(result["files"]["summary"]).exists()

        # Verify statistics
        assert result["statistics"]["total_calls_processed"] == 12500000
        assert result["statistics"]["fraud_alerts_generated"] == 17  # 5 + 12

        # Verify checksum was calculated
        assert len(result["checksum"]) == 64
