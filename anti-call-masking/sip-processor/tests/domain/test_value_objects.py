"""
Unit Tests for Domain Value Objects

Tests validation, normalization, and behavior of value objects.
"""

import pytest
from app.domain.value_objects import (
    MSISDN,
    IPAddress,
    FraudScore,
    CallId,
    Severity,
    FraudType,
    DetectionWindow,
    DetectionThreshold,
    InvalidMSISDNError,
    InvalidIPAddressError,
)


class TestMSISDN:
    """Tests for MSISDN value object"""
    
    def test_valid_nigerian_number_with_plus(self):
        """Valid +234 format should work"""
        msisdn = MSISDN("+2348012345678")
        assert str(msisdn) == "+2348012345678"
        assert msisdn.is_nigerian
    
    def test_valid_number_without_plus(self):
        """234 without plus should normalize to +234"""
        msisdn = MSISDN.from_string("2348012345678")
        assert str(msisdn) == "+2348012345678"
    
    def test_local_format_normalization(self):
        """0-prefix should normalize to +234"""
        msisdn = MSISDN.from_string("08012345678")
        assert str(msisdn) == "+2348012345678"
    
    def test_invalid_format_raises(self):
        """Invalid format should raise error"""
        with pytest.raises(InvalidMSISDNError):
            MSISDN("invalid")
    
    def test_too_short_raises(self):
        """Too short number should raise error"""
        with pytest.raises(InvalidMSISDNError):
            MSISDN("+23480123")
    
    def test_prefix_extraction(self):
        """Should extract correct prefix"""
        msisdn = MSISDN("+2348031234567")
        assert msisdn.prefix == "0803"
    
    def test_carrier_detection_mtn(self):
        """Should detect MTN carrier"""
        msisdn = MSISDN("+2348031234567")
        assert msisdn.carrier == "MTN"
    
    def test_carrier_detection_glo(self):
        """Should detect GLO carrier"""
        msisdn = MSISDN("+2348051234567")
        assert msisdn.carrier == "GLO"
    
    def test_carrier_detection_airtel(self):
        """Should detect Airtel carrier"""
        msisdn = MSISDN("+2348021234567")
        assert msisdn.carrier == "AIRTEL"
    
    def test_carrier_detection_9mobile(self):
        """Should detect 9mobile carrier"""
        msisdn = MSISDN("+2348091234567")
        assert msisdn.carrier == "9MOBILE"


class TestIPAddress:
    """Tests for IPAddress value object"""
    
    def test_valid_ipv4(self):
        """Valid IPv4 should work"""
        ip = IPAddress("192.168.1.1")
        assert str(ip) == "192.168.1.1"
        assert ip.is_ipv4
        assert not ip.is_ipv6
    
    def test_valid_ipv6(self):
        """Valid IPv6 should work"""
        ip = IPAddress("2001:0db8:85a3:0000:0000:8a2e:0370:7334")
        assert ip.is_ipv6
        assert not ip.is_ipv4
    
    def test_invalid_ip_raises(self):
        """Invalid IP should raise error"""
        with pytest.raises(InvalidIPAddressError):
            IPAddress("not.an.ip.address")
    
    def test_private_ip_detection(self):
        """Should detect private IPs"""
        private = IPAddress("192.168.1.1")
        assert private.is_private
        
        public = IPAddress("8.8.8.8")
        assert not public.is_private
    
    def test_international_heuristic(self):
        """Public IPs should be flagged as potentially international"""
        ip = IPAddress("8.8.8.8")
        assert ip.is_likely_international


class TestFraudScore:
    """Tests for FraudScore value object"""
    
    def test_valid_score(self):
        """Valid score should work"""
        score = FraudScore(0.85)
        assert float(score) == 0.85
    
    def test_score_clamping_high(self):
        """Score > 1.0 should be clamped to 1.0"""
        score = FraudScore(1.5)
        assert score.value == 1.0
    
    def test_score_clamping_low(self):
        """Score < 0.0 should be clamped to 0.0"""
        score = FraudScore(-0.5)
        assert score.value == 0.0
    
    def test_severity_critical(self):
        """Score >= 0.9 should be CRITICAL"""
        score = FraudScore(0.95)
        assert score.severity == Severity.CRITICAL
    
    def test_severity_high(self):
        """Score >= 0.75 should be HIGH"""
        score = FraudScore(0.8)
        assert score.severity == Severity.HIGH
    
    def test_severity_medium(self):
        """Score >= 0.5 should be MEDIUM"""
        score = FraudScore(0.6)
        assert score.severity == Severity.MEDIUM
    
    def test_severity_low(self):
        """Score < 0.5 should be LOW"""
        score = FraudScore(0.3)
        assert score.severity == Severity.LOW
    
    def test_block_threshold(self):
        """Score >= 0.9 should exceed block threshold"""
        high = FraudScore(0.95)
        assert high.exceeds_block_threshold
        
        low = FraudScore(0.85)
        assert not low.exceeds_block_threshold


class TestCallId:
    """Tests for CallId value object"""
    
    def test_valid_call_id(self):
        """Valid call ID should work"""
        call_id = CallId("abc-123-def")
        assert str(call_id) == "abc-123-def"
    
    def test_empty_call_id_raises(self):
        """Empty call ID should raise error"""
        with pytest.raises(ValueError):
            CallId("")
    
    def test_whitespace_only_raises(self):
        """Whitespace-only call ID should raise error"""
        with pytest.raises(ValueError):
            CallId("   ")
    
    def test_generate_unique(self):
        """Generated IDs should be unique"""
        id1 = CallId.generate()
        id2 = CallId.generate()
        assert str(id1) != str(id2)


class TestDetectionWindow:
    """Tests for DetectionWindow value object"""
    
    def test_valid_window(self):
        """Valid window should work"""
        window = DetectionWindow(5)
        assert window.seconds == 5
    
    def test_too_small_raises(self):
        """Window < 1 should raise error"""
        with pytest.raises(ValueError):
            DetectionWindow(0)
    
    def test_too_large_raises(self):
        """Window > 60 should raise error"""
        with pytest.raises(ValueError):
            DetectionWindow(61)


class TestDetectionThreshold:
    """Tests for DetectionThreshold value object"""
    
    def test_valid_threshold(self):
        """Valid threshold should work"""
        threshold = DetectionThreshold(5)
        assert threshold.distinct_callers == 5
    
    def test_too_small_raises(self):
        """Threshold < 2 should raise error"""
        with pytest.raises(ValueError):
            DetectionThreshold(1)
    
    def test_too_large_raises(self):
        """Threshold > 100 should raise error"""
        with pytest.raises(ValueError):
            DetectionThreshold(101)
