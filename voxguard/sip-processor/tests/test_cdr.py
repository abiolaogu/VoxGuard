"""Tests for CDR metrics calculation."""
import pytest
from unittest.mock import AsyncMock, MagicMock
from datetime import datetime

from app.cdr.metrics import CDRMetricsCalculator
from app.cdr.models import CDRRecord, CDRMetrics, CallState


class TestCDRMetricsCalculator:
    """Tests for CDR metrics calculation."""
    
    @pytest.fixture
    def mock_redis(self):
        """Create a mock Redis client."""
        redis = AsyncMock()
        redis.pipeline.return_value = AsyncMock()
        return redis
    
    @pytest.mark.asyncio
    async def test_calculate_asr_with_data(self, mock_redis):
        """Test ASR calculation with existing data."""
        mock_redis.get.side_effect = [
            "100",  # attempts
            "75"    # answered
        ]
        
        calculator = CDRMetricsCalculator(mock_redis)
        asr = await calculator.calculate_asr("+19876543210")
        
        assert asr == 75.0  # 75/100 * 100
    
    @pytest.mark.asyncio
    async def test_calculate_asr_no_attempts(self, mock_redis):
        """Test ASR when no attempts recorded."""
        mock_redis.get.side_effect = [None, None]
        
        calculator = CDRMetricsCalculator(mock_redis)
        asr = await calculator.calculate_asr("+19876543210")
        
        assert asr == 0.0
    
    @pytest.mark.asyncio
    async def test_calculate_aloc(self, mock_redis):
        """Test ALOC calculation."""
        mock_redis.lrange.return_value = ["30.0", "60.0", "90.0"]
        
        calculator = CDRMetricsCalculator(mock_redis)
        aloc = await calculator.calculate_aloc("+19876543210")
        
        assert aloc == 60.0  # average of 30, 60, 90
    
    @pytest.mark.asyncio
    async def test_calculate_aloc_no_data(self, mock_redis):
        """Test ALOC when no durations recorded."""
        mock_redis.lrange.return_value = []
        
        calculator = CDRMetricsCalculator(mock_redis)
        aloc = await calculator.calculate_aloc("+19876543210")
        
        assert aloc == 0.0
    
    @pytest.mark.asyncio
    async def test_calculate_overlap_ratio(self, mock_redis):
        """Test overlap ratio calculation."""
        mock_redis.scard.return_value = 5  # 5 concurrent callers
        mock_redis.get.return_value = "10"  # 10 total in window
        
        calculator = CDRMetricsCalculator(mock_redis)
        overlap = await calculator.calculate_overlap_ratio("+19876543210")
        
        assert overlap == 0.5


class TestCDRRecord:
    """Tests for CDR record model."""
    
    def test_duration_calculation(self):
        """Test call duration calculation."""
        record = CDRRecord(
            call_id="test-001",
            a_number="+12025551234",
            b_number="+19876543210",
            start_time=datetime(2024, 1, 1, 12, 0, 0),
            answer_time=datetime(2024, 1, 1, 12, 0, 5),
            end_time=datetime(2024, 1, 1, 12, 1, 5),
            state=CallState.COMPLETED
        )
        
        assert record.duration_seconds == 60.0
        assert record.setup_time_seconds == 5.0
        assert record.is_answered
        assert record.is_completed
    
    def test_unanswered_call(self):
        """Test unanswered call properties."""
        record = CDRRecord(
            call_id="test-002",
            a_number="+12025551234",
            b_number="+19876543210",
            start_time=datetime(2024, 1, 1, 12, 0, 0),
            state=CallState.NO_ANSWER
        )
        
        assert record.duration_seconds == 0.0
        assert not record.is_answered
    
    def test_cli_mismatch_flag(self):
        """Test CLI mismatch flag in CDR."""
        record = CDRRecord(
            call_id="test-003",
            a_number="+12025551234",
            b_number="+19876543210",
            start_time=datetime.utcnow(),
            cli="+11111111111",
            p_asserted_identity="+12025551234",
            has_cli_mismatch=True
        )
        
        assert record.has_cli_mismatch
