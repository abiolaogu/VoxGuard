"""Tests for SIP signaling module."""
import pytest
from app.signaling.parser import parse_sip_message, extract_number_from_uri, is_sip_message
from app.signaling.models import SIPMethod


class TestSIPParser:
    """Tests for SIP message parsing."""
    
    def test_parse_invite_message(self):
        """Test parsing a standard SIP INVITE."""
        raw_sip = b"""INVITE sip:+19876543210@10.0.0.1:5060 SIP/2.0\r
Via: SIP/2.0/UDP 192.168.1.1:5060;branch=z9hG4bK776asdhds\r
From: "Alice" <sip:+12025551234@carrier.com>;tag=1928301774\r
To: <sip:+19876543210@10.0.0.1>\r
Call-ID: a84b4c76e66710@192.168.1.1\r
CSeq: 314159 INVITE\r
Contact: <sip:alice@192.168.1.1:5060>\r
P-Asserted-Identity: <sip:+12025551234@carrier.com>\r
Content-Type: application/sdp\r
Content-Length: 0\r
\r
"""
        result = parse_sip_message(raw_sip)
        
        assert result is not None
        assert result.call_id == "a84b4c76e66710@192.168.1.1"
        assert result.cli == "+12025551234"
        assert result.p_asserted_identity == "+12025551234"
        assert result.method == SIPMethod.INVITE
        assert not result.has_cli_mismatch
    
    def test_cli_mismatch_detection(self):
        """Test detection of CLI vs P-Asserted-Identity mismatch."""
        raw_sip = b"""INVITE sip:+19876543210@10.0.0.1 SIP/2.0\r
Via: SIP/2.0/UDP 192.168.1.1:5060\r
From: <sip:+11111111111@spoofed.com>;tag=abc123\r
To: <sip:+19876543210@10.0.0.1>\r
Call-ID: test-mismatch-001\r
CSeq: 1 INVITE\r
P-Asserted-Identity: <sip:+12025551234@trusted.com>\r
\r
"""
        result = parse_sip_message(raw_sip)
        
        assert result is not None
        assert result.cli == "+11111111111"
        assert result.p_asserted_identity == "+12025551234"
        assert result.has_cli_mismatch
    
    def test_parse_without_pai(self):
        """Test parsing message without P-Asserted-Identity."""
        raw_sip = b"""INVITE sip:bob@example.com SIP/2.0\r
Via: SIP/2.0/UDP client.example.com\r
From: <sip:alice@example.com>;tag=xyz\r
To: <sip:bob@example.com>\r
Call-ID: no-pai-test\r
CSeq: 1 INVITE\r
\r
"""
        result = parse_sip_message(raw_sip)
        
        assert result is not None
        assert result.cli == "alice"
        assert result.p_asserted_identity is None
        assert not result.has_cli_mismatch


class TestNumberExtraction:
    """Tests for phone number extraction from URIs."""
    
    def test_extract_from_sip_uri(self):
        """Test extraction from standard SIP URIs."""
        assert extract_number_from_uri("sip:+12025551234@example.com") == "+12025551234"
        assert extract_number_from_uri("sip:12025551234@10.0.0.1:5060") == "12025551234"
    
    def test_extract_from_angle_brackets(self):
        """Test extraction from URIs with angle brackets."""
        assert extract_number_from_uri("<sip:+12025551234@host>") == "+12025551234"
        assert extract_number_from_uri('"Display" <sip:user@host>') == "user"
    
    def test_extract_from_tel_uri(self):
        """Test extraction from tel: URIs."""
        assert extract_number_from_uri("tel:+12025551234") == "+12025551234"
    
    def test_empty_and_none(self):
        """Test edge cases."""
        assert extract_number_from_uri("") is None
        assert extract_number_from_uri(None) is None


class TestSIPDetection:
    """Tests for SIP message detection."""
    
    def test_detect_invite(self):
        """Test that INVITE messages are detected."""
        assert is_sip_message(b"INVITE sip:user@host SIP/2.0\r\n")
    
    def test_detect_response(self):
        """Test that SIP responses are detected."""
        assert is_sip_message(b"SIP/2.0 200 OK\r\n")
    
    def test_detect_bye(self):
        """Test that BYE messages are detected."""
        assert is_sip_message(b"BYE sip:user@host SIP/2.0\r\n")
    
    def test_non_sip(self):
        """Test that non-SIP data is rejected."""
        assert not is_sip_message(b"HTTP/1.1 200 OK\r\n")
        assert not is_sip_message(b"random data")
        assert not is_sip_message(b"")
