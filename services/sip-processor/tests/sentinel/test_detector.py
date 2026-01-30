"""
Unit tests for Sentinel detection engine
"""
import pytest
from datetime import datetime, timedelta
from unittest.mock import AsyncMock, MagicMock, patch
from app.sentinel.detector import SDHFDetector, FraudDetectionEngine
from app.sentinel.models import SentinelFraudAlert


@pytest.fixture
def mock_pool():
    """Mock asyncpg connection pool"""
    pool = MagicMock()
    return pool


@pytest.fixture
def sdhf_detector(mock_pool):
    """Create SDHFDetector instance with mock pool"""
    return SDHFDetector(mock_pool)


class TestSDHFDetector:
    """Test cases for SDHF detection"""

    @pytest.mark.asyncio
    async def test_detect_sdhf_patterns_basic(self, sdhf_detector, mock_pool):
        """Test basic SDHF pattern detection"""
        # Mock database response
        mock_conn = AsyncMock()
        mock_rows = [
            {
                'caller_number': '+2348012345678',
                'call_count': 100,
                'unique_destinations': 85,
                'avg_duration': 2.5,
                'first_call': datetime.utcnow() - timedelta(hours=10),
                'last_call': datetime.utcnow()
            }
        ]
        mock_conn.fetch.return_value = [MagicMock(**row) for row in mock_rows]
        mock_pool.acquire.return_value.__aenter__.return_value = mock_conn

        # Run detection
        results = await sdhf_detector.detect_sdhf_patterns()

        # Verify results
        assert len(results) == 1
        assert results[0]['caller_number'] == '+2348012345678'
        assert results[0]['unique_destinations'] == 85
        assert results[0]['avg_duration'] == 2.5

    @pytest.mark.asyncio
    async def test_detect_sdhf_patterns_no_matches(self, sdhf_detector, mock_pool):
        """Test SDHF detection with no suspicious patterns"""
        # Mock empty database response
        mock_conn = AsyncMock()
        mock_conn.fetch.return_value = []
        mock_pool.acquire.return_value.__aenter__.return_value = mock_conn

        # Run detection
        results = await sdhf_detector.detect_sdhf_patterns()

        # Verify no results
        assert len(results) == 0

    @pytest.mark.asyncio
    async def test_detect_sdhf_patterns_custom_thresholds(self, sdhf_detector, mock_pool):
        """Test SDHF detection with custom thresholds"""
        # Mock database response
        mock_conn = AsyncMock()
        mock_conn.fetch.return_value = []
        mock_pool.acquire.return_value.__aenter__.return_value = mock_conn

        # Run detection with custom parameters
        results = await sdhf_detector.detect_sdhf_patterns(
            time_window_hours=48,
            min_unique_destinations=100,
            max_avg_duration_seconds=2.0
        )

        # Verify query was called with correct parameters
        mock_conn.fetch.assert_called_once()
        args = mock_conn.fetch.call_args[0]
        assert args[2] == 100  # min_unique_destinations
        assert args[3] == 2.0  # max_avg_duration_seconds

    @pytest.mark.asyncio
    async def test_generate_sdhf_alerts(self, sdhf_detector, mock_pool):
        """Test alert generation from SDHF detections"""
        # Mock detection results
        mock_conn = AsyncMock()
        mock_detections = [
            {
                'caller_number': '+2348012345678',
                'call_count': 100,
                'unique_destinations': 85,
                'avg_duration': 2.5,
                'first_call': datetime.utcnow() - timedelta(hours=10),
                'last_call': datetime.utcnow()
            }
        ]

        # Mock fetch for detection query
        mock_conn.fetch.return_value = [MagicMock(**row) for row in mock_detections]

        # Mock fetchval for alert insertion
        mock_conn.fetchval.return_value = 123  # Mock alert ID

        mock_pool.acquire.return_value.__aenter__.return_value = mock_conn

        # Generate alerts
        alert_ids = await sdhf_detector.generate_sdhf_alerts()

        # Verify alerts were created
        assert len(alert_ids) == 1
        assert alert_ids[0] == 123

    @pytest.mark.asyncio
    async def test_generate_sdhf_alerts_no_detections(self, sdhf_detector, mock_pool):
        """Test alert generation with no detections"""
        # Mock empty detection results
        mock_conn = AsyncMock()
        mock_conn.fetch.return_value = []
        mock_pool.acquire.return_value.__aenter__.return_value = mock_conn

        # Generate alerts
        alert_ids = await sdhf_detector.generate_sdhf_alerts()

        # Verify no alerts created
        assert len(alert_ids) == 0

    def test_calculate_severity_critical(self, sdhf_detector):
        """Test severity calculation for critical level"""
        severity = sdhf_detector._calculate_severity(
            unique_destinations=250,
            avg_duration=1.0,
            call_count=300
        )
        assert severity == "CRITICAL"

    def test_calculate_severity_high(self, sdhf_detector):
        """Test severity calculation for high level"""
        severity = sdhf_detector._calculate_severity(
            unique_destinations=120,
            avg_duration=1.8,
            call_count=150
        )
        assert severity == "HIGH"

    def test_calculate_severity_medium(self, sdhf_detector):
        """Test severity calculation for medium level"""
        severity = sdhf_detector._calculate_severity(
            unique_destinations=60,
            avg_duration=2.5,
            call_count=80
        )
        assert severity == "MEDIUM"

    def test_calculate_severity_edge_cases(self, sdhf_detector):
        """Test severity calculation edge cases"""
        # Just above threshold
        severity = sdhf_detector._calculate_severity(
            unique_destinations=51,
            avg_duration=2.9,
            call_count=55
        )
        assert severity == "MEDIUM"

        # Very high destinations
        severity = sdhf_detector._calculate_severity(
            unique_destinations=500,
            avg_duration=0.5,
            call_count=600
        )
        assert severity == "CRITICAL"

    @pytest.mark.asyncio
    async def test_create_alert(self, sdhf_detector, mock_pool):
        """Test alert creation in database"""
        # Mock database connection
        mock_conn = AsyncMock()
        mock_conn.fetchval.return_value = 456  # Mock alert ID
        mock_pool.acquire.return_value.__aenter__.return_value = mock_conn

        # Create alert
        alert = SentinelFraudAlert(
            alert_type="SDHF_SIMBOX",
            suspect_number="+2348012345678",
            alert_severity="HIGH",
            evidence_summary="Test evidence",
            call_count=100,
            unique_destinations=85,
            avg_duration_seconds=2.5,
            detection_rule="SDHF_001"
        )

        alert_id = await sdhf_detector._create_alert(alert)

        # Verify alert was inserted
        assert alert_id == 456
        mock_conn.fetchval.assert_called_once()


class TestFraudDetectionEngine:
    """Test cases for main fraud detection engine"""

    @pytest.mark.asyncio
    async def test_run_all_detections(self, mock_pool):
        """Test running all detection rules"""
        engine = FraudDetectionEngine(mock_pool)

        # Mock SDHF detector
        mock_conn = AsyncMock()
        mock_conn.fetch.return_value = []
        mock_conn.fetchval.return_value = 789
        mock_pool.acquire.return_value.__aenter__.return_value = mock_conn

        # Run all detections
        results = await engine.run_all_detections()

        # Verify results structure
        assert 'SDHF' in results
        assert isinstance(results['SDHF'], list)

    @pytest.mark.asyncio
    async def test_run_all_detections_with_alerts(self, mock_pool):
        """Test running detections that generate alerts"""
        engine = FraudDetectionEngine(mock_pool)

        # Mock detection with results
        mock_conn = AsyncMock()
        mock_detections = [
            {
                'caller_number': '+2348012345678',
                'call_count': 100,
                'unique_destinations': 85,
                'avg_duration': 2.5,
                'first_call': datetime.utcnow() - timedelta(hours=10),
                'last_call': datetime.utcnow()
            }
        ]
        mock_conn.fetch.return_value = [MagicMock(**row) for row in mock_detections]
        mock_conn.fetchval.return_value = 999
        mock_pool.acquire.return_value.__aenter__.return_value = mock_conn

        # Run all detections
        results = await engine.run_all_detections()

        # Verify alerts were generated
        assert len(results['SDHF']) > 0


class TestSDHFDetectorIntegration:
    """Integration tests for SDHF detector"""

    @pytest.mark.asyncio
    async def test_end_to_end_detection_flow(self, mock_pool):
        """Test complete detection flow from query to alert creation"""
        detector = SDHFDetector(mock_pool)

        # Mock complete flow
        mock_conn = AsyncMock()

        # Mock detection query result
        mock_detection = {
            'caller_number': '+2348012345678',
            'call_count': 120,
            'unique_destinations': 95,
            'avg_duration': 2.2,
            'first_call': datetime.utcnow() - timedelta(hours=12),
            'last_call': datetime.utcnow()
        }
        mock_conn.fetch.return_value = [MagicMock(**mock_detection)]

        # Mock alert insertion
        mock_conn.fetchval.return_value = 111

        mock_pool.acquire.return_value.__aenter__.return_value = mock_conn

        # Run detection and alert generation
        alert_ids = await detector.generate_sdhf_alerts(
            time_window_hours=24,
            min_unique_destinations=50,
            max_avg_duration_seconds=3.0
        )

        # Verify complete flow
        assert len(alert_ids) == 1
        assert alert_ids[0] == 111

        # Verify both queries were executed
        assert mock_conn.fetch.call_count == 1
        assert mock_conn.fetchval.call_count == 1

    @pytest.mark.asyncio
    async def test_multiple_detections(self, mock_pool):
        """Test handling multiple suspicious patterns"""
        detector = SDHFDetector(mock_pool)

        # Mock multiple detections
        mock_conn = AsyncMock()
        mock_detections = [
            {
                'caller_number': '+2348012345678',
                'call_count': 100,
                'unique_destinations': 85,
                'avg_duration': 2.5,
                'first_call': datetime.utcnow() - timedelta(hours=10),
                'last_call': datetime.utcnow()
            },
            {
                'caller_number': '+2349087654321',
                'call_count': 150,
                'unique_destinations': 120,
                'avg_duration': 1.8,
                'first_call': datetime.utcnow() - timedelta(hours=8),
                'last_call': datetime.utcnow()
            }
        ]
        mock_conn.fetch.return_value = [MagicMock(**row) for row in mock_detections]

        # Mock alert insertions
        alert_ids = [222, 333]
        mock_conn.fetchval.side_effect = alert_ids

        mock_pool.acquire.return_value.__aenter__.return_value = mock_conn

        # Generate alerts
        result_ids = await detector.generate_sdhf_alerts()

        # Verify both alerts created
        assert len(result_ids) == 2
        assert result_ids == alert_ids
